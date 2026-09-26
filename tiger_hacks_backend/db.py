from pathlib import Path

from sqlalchemy import URL, create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


class Base(DeclarativeBase):
	pass

engine = create_engine("sqlite:///:memory:")
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def create_tables() -> None:
	from models import User

	User.metadata.create_all(bind=engine)
	Measure.metadata.create_all(bind=engine)
	Sharepoint.metadata.create_all(bind=engine)
	
