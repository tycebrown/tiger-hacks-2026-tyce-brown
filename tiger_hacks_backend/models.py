from datetime import datetime
from enum import Enum

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
    timestamp: Mapped[datetime] = mapped_column(DateTime(), nullable=False)
    bp_sys_pressure: Mapped[int] = mapped_column(Integer(), nullable=True)
    bp_dia_pressure: Mapped[int] = mapped_column(Integer(), nullable=True)
    heart_rate: Mapped[int] = mapped_column(Integer(), nullable=True)
    respiratory_rate: Mapped[int] = mapped_column(Integer(), nullable=True)
    temperature: Mapped[int] = mapped_column(Integer(), nullable=True)
    blood_ox: Mapped[int] = mapped_column(Integer(), nullable=True)



class TotalSharepoint(Base):
    __tablename__ = "total_sharepoints"

    id: Mapped[int] = mapped_column(Integer(), primary_key=True, autoincrement=True)
    individual_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )
    caretaker_id: Mapped[int] = mapped_column(
        ForeignKey("users.id"), nullable=False
    )