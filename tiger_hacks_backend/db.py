from pathlib import Path

from sqlalchemy import create_engine
from sqlalchemy.orm import DeclarativeBase, sessionmaker


DATABASE_PATH = Path(__file__).resolve().parent / "data" / "app.db"


class Base(DeclarativeBase):
	pass

engine = create_engine(f"sqlite:///{DATABASE_PATH.as_posix()}")
SessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False)


def init():
	from models import User, MeasureRecord, TotalSharepoint

	DATABASE_PATH.parent.mkdir(parents=True, exist_ok=True)
	DATABASE_PATH.touch(exist_ok=True)

	User.metadata.create_all(bind=engine)
	MeasureRecord.metadata.create_all(bind=engine)
	TotalSharepoint.metadata.create_all(bind=engine)

    

    
def cleanup(): pass