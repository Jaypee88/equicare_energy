import os
os.environ["DATABASE_URL"] = "sqlite:///./test_equicare.db"
from fastapi.testclient import TestClient
from app.main import app
client=TestClient(app)

def token(email="owner@example.com"):
    client.post("/auth/register",json={"email":email,"password":"a-strong-password-123"})
    response=client.post("/auth/login",json={"email":email,"password":"a-strong-password-123"})
    return response.json()["access_token"]

def test_health():
    assert client.get("/health").json()["status"]=="ok"

def test_register_login_and_site_access():
    access=token()
    headers={"Authorization":f"Bearer {access}"}
    site=client.post("/sites",headers=headers,json={"name":"Test hostel","daily_budget_kwh":12})
    assert site.status_code==201
    site_id=site.json()["id"]
    room=client.post(f"/sites/{site_id}/rooms",headers=headers,json={"name":"Room 1"})
    assert room.status_code==201
    allocation=client.get(f"/sites/{site_id}/allocations",headers=headers)
    assert allocation.status_code==200 and allocation.json()[0]["allocated_kwh"]==12
    reading=client.post(f"/rooms/{room.json()['id']}/readings",headers=headers,json={"meter_id":"meter-1","energy_kwh":1.2,"reading_kind":"measured"})
    assert reading.status_code==201

def test_other_user_cannot_read_site():
    access=token("owner2@example.com")
    site=client.post("/sites",headers={"Authorization":f"Bearer {access}"},json={"name":"Private site"})
    site_id=site.json()["id"]
    other=token("outsider@example.com")
    result=client.get(f"/sites/{site_id}/rooms",headers={"Authorization":f"Bearer {other}"})
    assert result.status_code==403

def test_autonomy_preserves_medical_safety_advisory():
    access=token("clinic@example.com")
    headers={"Authorization":f"Bearer {access}"}
    site=client.post("/sites",headers=headers,json={"name":"Clinic","site_type":"clinic"})
    result=client.post(f"/sites/{site.json()['id']}/battery/autonomy",headers=headers,json={"capacity_wh":2000,"battery_percent":80,"load_w":500,"reserve_percent":10,"efficiency":0.9,"flexible_reduction_w":200})
    assert result.status_code==200
    body=result.json()
    assert body["current_runtime_hours"]>0
    assert "Never disconnect critical medical equipment" in body["critical_load_warning"]

def test_unauthorized_site_access_rejected():
    response=client.get("/sites")
    assert response.status_code==401
