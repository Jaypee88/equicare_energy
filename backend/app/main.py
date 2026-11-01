from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.security import OAuth2PasswordBearer
from sqlalchemy.orm import Session
from sqlalchemy import select
from .database import Base, engine, get_db
from . import models, schemas
from .security import hash_password, verify_password, create_access_token, token_subject

Base.metadata.create_all(bind=engine)
app = FastAPI(title="EquiCare Energy API", version="0.1.0", description="Shared energy allocation and critical-service autonomy API.")
oauth2 = OAuth2PasswordBearer(tokenUrl="/auth/login")

def current_user(token: str = Depends(oauth2), db: Session = Depends(get_db)):
    try: uid = int(token_subject(token))
    except ValueError: raise HTTPException(status_code=401, detail="Invalid or expired token", headers={"WWW-Authenticate":"Bearer"})
    user = db.get(models.User, uid)
    if user is None: raise HTTPException(status_code=401, detail="User not found")
    return user

def require_site(site_id: int, user: models.User, db: Session):
    site = db.get(models.Site, site_id)
    if site is None: raise HTTPException(404, "Site not found")
    if site.owner_id != user.id and user.role != "admin": raise HTTPException(403, "Not permitted for this site")
    return site

def audit(db, site_id, user_id, action, details=""):
    db.add(models.AuditEvent(site_id=site_id, actor_id=user_id, action=action, details=details))

@app.get("/health")
def health():
    return {"status":"ok","service":"equicare-energy-api"}

@app.post("/auth/register", response_model=schemas.UserOut, status_code=201)
def register(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    email = payload.email.lower()
    if db.scalar(select(models.User).where(models.User.email == email)):
        raise HTTPException(409, "Email already registered")
    # First account bootstraps the local deployment; subsequent registrations are least-privilege residents.
    first_user = db.scalar(select(models.User.id).limit(1)) is None
    user = models.User(email=email, password_hash=hash_password(payload.password), role="admin" if first_user else "resident")
    db.add(user); db.commit(); db.refresh(user)
    return user

@app.post("/auth/login", response_model=schemas.TokenOut)
def login(payload: schemas.UserCreate, db: Session = Depends(get_db)):
    user = db.scalar(select(models.User).where(models.User.email == payload.email.lower()))
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(401, "Incorrect email or password")
    return {"access_token":create_access_token(str(user.id)),"user":user}

@app.get("/auth/me", response_model=schemas.UserOut)
def me(user=Depends(current_user)):
    return user

@app.post("/sites", response_model=schemas.SiteOut, status_code=201)
def create_site(payload: schemas.SiteCreate, user=Depends(current_user), db: Session=Depends(get_db)):
    site=models.Site(**payload.model_dump(),owner_id=user.id); db.add(site); db.flush()
    audit(db,site.id,user.id,"site.created",site.name); db.commit(); db.refresh(site); return site

@app.get("/sites", response_model=list[schemas.SiteOut])
def list_sites(user=Depends(current_user),db:Session=Depends(get_db)):
    q=select(models.Site)
    if user.role!="admin": q=q.where(models.Site.owner_id==user.id)
    return list(db.scalars(q.order_by(models.Site.id.desc())))

@app.post("/sites/{site_id}/rooms",response_model=schemas.RoomOut,status_code=201)
def create_room(site_id:int,payload:schemas.RoomCreate,user=Depends(current_user),db:Session=Depends(get_db)):
    site=require_site(site_id,user,db); room=models.Room(site_id=site.id,**payload.model_dump())
    db.add(room); audit(db,site.id,user.id,"room.created",room.name); db.commit(); db.refresh(room); return room

@app.get("/sites/{site_id}/rooms",response_model=list[schemas.RoomOut])
def list_rooms(site_id:int,user=Depends(current_user),db:Session=Depends(get_db)):
    require_site(site_id,user,db)
    return list(db.scalars(select(models.Room).where(models.Room.site_id==site_id).order_by(models.Room.id)))

@app.post("/rooms/{room_id}/readings",response_model=schemas.ReadingOut,status_code=201)
def add_reading(room_id:int,payload:schemas.ReadingCreate,user=Depends(current_user),db:Session=Depends(get_db)):
    room=db.get(models.Room,room_id)
    if not room: raise HTTPException(404,"Room not found")
    require_site(room.site_id,user,db)
    reading=models.MeterReading(room_id=room.id,**payload.model_dump())
    db.add(reading); audit(db,room.site_id,user.id,"meter.reading.created",f"{payload.reading_kind}:{payload.energy_kwh} kWh"); db.commit(); db.refresh(reading); return reading

@app.get("/rooms/{room_id}/readings",response_model=list[schemas.ReadingOut])
def list_readings(room_id:int,user=Depends(current_user),db:Session=Depends(get_db)):
    room=db.get(models.Room,room_id)
    if not room: raise HTTPException(404,"Room not found")
    require_site(room.site_id,user,db)
    return list(db.scalars(select(models.MeterReading).where(models.MeterReading.room_id==room_id).order_by(models.MeterReading.recorded_at.desc()).limit(500)))

@app.get("/sites/{site_id}/allocations",response_model=list[schemas.AllocationOut])
def allocations(site_id:int,policy:str="equal",user=Depends(current_user),db:Session=Depends(get_db)):
    site=require_site(site_id,user,db)
    rooms=list(db.scalars(select(models.Room).where(models.Room.site_id==site_id,models.Room.active.is_(True))))
    if not rooms:return []
    if policy=="manual": raise HTTPException(422,"Manual allocations require explicit approved values.")
    if policy=="equal": weights=[1.0]*len(rooms)
    elif policy=="weighted": weights=[r.allocation_weight for r in rooms]
    elif policy=="priority": weights=[float(r.priority) for r in rooms]
    else: raise HTTPException(422,"Policy must be equal, weighted, priority or manual.")
    total=sum(weights)
    return [schemas.AllocationOut(room_id=r.id,room_name=r.name,allocated_kwh=site.daily_budget_kwh*w/total,policy=policy) for r,w in zip(rooms,weights)]

@app.post("/sites/{site_id}/battery/autonomy",response_model=schemas.AutonomyOut)
def autonomy(site_id:int,payload:schemas.BatteryInput,user=Depends(current_user),db:Session=Depends(get_db)):
    require_site(site_id,user,db)
    available=max(0,(payload.battery_percent-payload.reserve_percent)/100*payload.capacity_wh*payload.efficiency)
    reduced=max(0,payload.load_w-payload.flexible_reduction_w)
    current=None if payload.load_w==0 else available/payload.load_w
    after=None if reduced==0 else available/reduced
    db.add(models.BatterySnapshot(site_id=site_id,**payload.model_dump(exclude={"flexible_reduction_w"})))
    audit(db,site_id,user.id,"battery.autonomy.calculated","Advisory calculation; no switching action taken.")
    db.commit()
    return schemas.AutonomyOut(available_energy_wh=available,current_runtime_hours=current,reduced_load_runtime_hours=after,extension_hours=(after-current) if after is not None and current is not None else None,critical_load_warning="Flexible-load reduction is advisory only. Never disconnect critical medical equipment.")

@app.get("/sites/{site_id}/audit")
def audit_events(site_id:int,user=Depends(current_user),db:Session=Depends(get_db)):
    require_site(site_id,user,db)
    rows=db.scalars(select(models.AuditEvent).where(models.AuditEvent.site_id==site_id).order_by(models.AuditEvent.created_at.desc()).limit(500))
    return [{"id":x.id,"actor_id":x.actor_id,"action":x.action,"details":x.details,"created_at":x.created_at} for x in rows]
