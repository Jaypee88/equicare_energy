from datetime import datetime
from pydantic import BaseModel, ConfigDict, EmailStr, Field

class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=10, max_length=128)
class UserOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    email: EmailStr
    role: str
class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserOut
class SiteCreate(BaseModel):
    name: str = Field(min_length=2, max_length=160)
    site_type: str = Field(default="shared_residence", pattern="^(shared_residence|clinic|pharmacy|laboratory|microgrid)$")
    timezone: str = Field(default="UTC", max_length=64)
    daily_budget_kwh: float = Field(default=0, ge=0, le=1000000)
class SiteOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    name: str
    site_type: str
    timezone: str
    daily_budget_kwh: float
class RoomCreate(BaseModel):
    name: str = Field(min_length=1, max_length=120)
    allocation_weight: float = Field(default=1, gt=0, le=100000)
    priority: int = Field(default=1, ge=1, le=1000)
class RoomOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    site_id: int
    name: str
    allocation_weight: float
    priority: int
    active: bool
class ReadingCreate(BaseModel):
    meter_id: str = Field(min_length=1, max_length=128)
    energy_kwh: float = Field(ge=0, le=10000000)
    reading_kind: str = Field(default="measured", pattern="^(measured|simulated|estimated)$")
    recorded_at: datetime | None = None
class ReadingOut(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    id: int
    room_id: int
    meter_id: str
    energy_kwh: float
    reading_kind: str
    recorded_at: datetime
class AllocationOut(BaseModel):
    room_id: int
    room_name: str
    allocated_kwh: float
    policy: str
class BatteryInput(BaseModel):
    capacity_wh: float = Field(gt=0, le=100000000)
    battery_percent: float = Field(ge=0, le=100)
    load_w: float = Field(ge=0, le=10000000)
    reserve_percent: float = Field(ge=0, lt=100)
    efficiency: float = Field(gt=0, le=1)
    flexible_reduction_w: float = Field(default=0, ge=0)
class AutonomyOut(BaseModel):
    available_energy_wh: float
    current_runtime_hours: float | None
    reduced_load_runtime_hours: float | None
    extension_hours: float | None
    critical_load_warning: str
