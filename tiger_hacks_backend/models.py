from datetime import UTC, datetime
from enum import Enum
from typing import Optional

import pydantic
from sqlalchemy import DateTime, Enum as SqlEnum, ForeignKey, Integer, Text
from sqlalchemy.orm import Mapped, mapped_column

from db import Base


class UserRole(str, Enum):
    INDIVIDUAL = "individual"
    CARETAKER = "caretaker"


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer(), primary_key=True, autoincrement=True)
    username: Mapped[str] = mapped_column(Text(), unique=True, nullable=False, index=True)
    hashed_password: Mapped[Optional[str]] = mapped_column(Text(), nullable=True)
    role: Mapped[UserRole] = mapped_column(
        SqlEnum(
            UserRole,
            values_callable=lambda roles: [role.value for role in roles],
            name="user_role",
            native_enum=False,
            create_constraint=True,
        ),
        nullable=False,
    )

class MeasureRecord(Base):
    __tablename__ = "measures"

    id: Mapped[int] = mapped_column(Integer(), primary_key=True, autoincrement=True)
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"), nullable=False)
    timestamp: Mapped[datetime] = mapped_column(DateTime(timezone=True), nullable=False)
    bp_sys_pressure: Mapped[int] = mapped_column(Integer(), nullable=True)
    bp_dia_pressure: Mapped[int] = mapped_column(Integer(), nullable=True)
    heart_rate: Mapped[int] = mapped_column(Integer(), nullable=True)
    respiratory_rate: Mapped[int] = mapped_column(Integer(), nullable=True)
    temperature: Mapped[int] = mapped_column(Integer(), nullable=True)
    blood_ox: Mapped[int] = mapped_column(Integer(), nullable=True)

    
class MeasureModelData(pydantic.BaseModel):
    timestamp: datetime = pydantic.Field(default_factory=lambda: datetime.now(UTC))
    bp_sys_pressure: Optional[int] = None
    bp_dia_pressure: Optional[int] = None
    heart_rate: Optional[int] = None
    respiratory_rate: Optional[int] = None
    temperature: Optional[int] = None
    blood_ox: Optional[int] = None


class MeasureQueryParams(pydantic.BaseModel):
    start: datetime
    end: datetime


class MeasureModel(pydantic.BaseModel):
    id: int
    user_id: int
    timestamp: datetime
    bp_sys_pressure: Optional[int]
    bp_dia_pressure: Optional[int]
    heart_rate: Optional[int]
    respiratory_rate: Optional[int]
    temperature: Optional[int]
    blood_ox: Optional[int]


class SharepointModel(pydantic.BaseModel):
    id: int
    individual_id: int
    caretaker_id: int


class SharedUserModel(pydantic.BaseModel):
    sharepoint_id: int
    individual_id: int
    caretaker_id: int
    username: str
    role: UserRole


class LoginRequest(pydantic.BaseModel):
    username: str = pydantic.Field(min_length=1)
    password: str = pydantic.Field(min_length=1)


class PublicUserModel(pydantic.BaseModel):
    id: int
    username: str
    role: UserRole


class LoginResponse(pydantic.BaseModel):
    user: PublicUserModel
    token: str



class TotalSharepoint(Base):
    __tablename__ = "total_sharepoints"

    id: Mapped[int] = mapped_column(Integer(), primary_key=True, autoincrement=True)
    individual_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"), nullable=False)
    caretaker_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"), nullable=False)