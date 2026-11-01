from datetime import datetime, timezone
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .database import Base

def utcnow():
    return datetime.now(timezone.utc)

class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(32), default="resident")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

class Site(Base):
    __tablename__ = "sites"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    name: Mapped[str] = mapped_column(String(160))
    site_type: Mapped[str] = mapped_column(String(40), default="shared_residence")
    timezone: Mapped[str] = mapped_column(String(64), default="UTC")
    daily_budget_kwh: Mapped[float] = mapped_column(Float, default=0)
    owner_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    rooms: Mapped[list["Room"]] = relationship(back_populates="site", cascade="all, delete-orphan")

class Room(Base):
    __tablename__ = "rooms"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    site_id: Mapped[int] = mapped_column(ForeignKey("sites.id", ondelete="CASCADE"), index=True)
    name: Mapped[str] = mapped_column(String(120))
    allocation_weight: Mapped[float] = mapped_column(Float, default=1)
    priority: Mapped[int] = mapped_column(Integer, default=1)
    active: Mapped[bool] = mapped_column(Boolean, default=True)
    site: Mapped[Site] = relationship(back_populates="rooms")

class MeterReading(Base):
    __tablename__ = "meter_readings"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    room_id: Mapped[int] = mapped_column(ForeignKey("rooms.id"), index=True)
    meter_id: Mapped[str] = mapped_column(String(128))
    energy_kwh: Mapped[float] = mapped_column(Float)
    reading_kind: Mapped[str] = mapped_column(String(20), default="measured")
    recorded_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

class BatterySnapshot(Base):
    __tablename__ = "battery_snapshots"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    site_id: Mapped[int] = mapped_column(ForeignKey("sites.id"), index=True)
    capacity_wh: Mapped[float] = mapped_column(Float)
    battery_percent: Mapped[float] = mapped_column(Float)
    load_w: Mapped[float] = mapped_column(Float)
    reserve_percent: Mapped[float] = mapped_column(Float, default=10)
    efficiency: Mapped[float] = mapped_column(Float, default=0.9)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)

class AuditEvent(Base):
    __tablename__ = "audit_events"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    site_id: Mapped[int] = mapped_column(ForeignKey("sites.id"), index=True)
    actor_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    action: Mapped[str] = mapped_column(String(80))
    details: Mapped[str] = mapped_column(Text, default="")
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=utcnow)
