from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select

import db
from models import (
	MeasureModel,
	MeasureModelData,
	MeasureQueryParams,
	MeasureRecord,
	SharepointModel,
	SharedUserModel,
	TotalSharepoint,
	User,
)


router = APIRouter()



@router.post(
	'/user/{user_id}/one-time-record-measures',
	status_code=201,
	response_model=MeasureModel,
)
def record_measures(user_id: int, body: MeasureModelData) -> MeasureModel:
	with db.SessionLocal() as session:
		if session.get(User, user_id) is None:
			raise HTTPException(status_code=404, detail="User not found")

		record = MeasureRecord(user_id=user_id, **body.model_dump())
		session.add(record)
		session.commit()
		session.refresh(record)

		return {
			"id": record.id,
			"user_id": record.user_id,
			**body.model_dump(),
		}

@router.post('/user/{id}/query', response_model=list[MeasureModel])
def query_measures(
	id: int,
	query: MeasureQueryParams = Depends(),
) -> list[MeasureModel]:
	start, end = query.start, query.end
	if start > end:
		raise HTTPException(status_code=422, detail="start must be before or equal to end")

	with db.SessionLocal() as session:
		if session.get(User, id) is None:
			raise HTTPException(status_code=404, detail="User not found")

		statement = (
			select(MeasureRecord)
			.where(
				MeasureRecord.user_id == id,
				MeasureRecord.timestamp >= start,
				MeasureRecord.timestamp <= end,
			)
			.order_by(MeasureRecord.timestamp)
		)
		records = session.scalars(statement).all()
		return _serialize_measures(records)


def _serialize_measures(records: list[MeasureRecord]) -> list[MeasureModel]:
	return [
		MeasureModel(
			id=record.id,
			user_id=record.user_id,
			timestamp=record.timestamp,
			bp_sys_pressure=record.bp_sys_pressure,
			bp_dia_pressure=record.bp_dia_pressure,
			heart_rate=record.heart_rate,
			respiratory_rate=record.respiratory_rate,
			temperature=record.temperature,
			blood_ox=record.blood_ox,
		)
		for record in records
	]


@router.post(
	'/user/{id}/share/{caretaker_id}',
	status_code=201,
	response_model=SharepointModel,
)
def share_user(id: int, caretaker_id: int) -> SharepointModel:
	with db.SessionLocal() as session:
		if session.get(User, id) is None:
			raise HTTPException(status_code=404, detail="User not found")
		if session.get(User, caretaker_id) is None:
			raise HTTPException(status_code=404, detail="Caretaker not found")

		sharepoint = TotalSharepoint(
			individual_id=id,
			caretaker_id=caretaker_id,
		)
		session.add(sharepoint)
		session.commit()
		session.refresh(sharepoint)

		return {
			"id": sharepoint.id,
			"individual_id": sharepoint.individual_id,
			"caretaker_id": sharepoint.caretaker_id,
		}

@router.get('/user/{id}/caretakers', response_model=list[SharedUserModel])
def get_caretakers(id: int) -> list[SharedUserModel]:
	with db.SessionLocal() as session:
		if session.get(User, id) is None:
			raise HTTPException(status_code=404, detail="User not found")

		statement = (
			select(TotalSharepoint, User)
			.join(User, User.id == TotalSharepoint.caretaker_id)
			.where(TotalSharepoint.individual_id == id)
			.order_by(TotalSharepoint.id)
		)
		shares = session.execute(statement).all()

		return [
			{
				"sharepoint_id": sharepoint.id,
				"individual_id": sharepoint.individual_id,
				"caretaker_id": caretaker.id,
				"username": caretaker.username,
				"role": caretaker.role.value,
			}
			for sharepoint, caretaker in shares
		]


@router.get('/caretaker/{id}/patients', response_model=list[SharedUserModel])
def get_patients(id: int) -> list[SharedUserModel]:
	with db.SessionLocal() as session:
		if session.get(User, id) is None:
			raise HTTPException(status_code=404, detail="Caretaker not found")

		statement = (
			select(TotalSharepoint, User)
			.join(User, User.id == TotalSharepoint.individual_id)
			.where(TotalSharepoint.caretaker_id == id)
			.order_by(TotalSharepoint.id)
		)
		shares = session.execute(statement).all()

		return [
			{
				"sharepoint_id": sharepoint.id,
				"caretaker_id": sharepoint.caretaker_id,
				"individual_id": patient.id,
				"username": patient.username,
				"role": patient.role.value,
			}
			for sharepoint, patient in shares
		]


@router.post(
	'/caretaker/{caretaker_id}/user/{individual_id}/query',
	response_model=list[MeasureModel],
)
def query_personal_measures(
	caretaker_id: int,
	individual_id: int,
 query: MeasureQueryParams = Depends(),
) -> list[MeasureModel]:
	start, end = query.start, query.end
	if start > end:
		raise HTTPException(status_code=422, detail="start must be before or equal to end")

	with db.SessionLocal() as session:
		if session.get(User, caretaker_id) is None:
			raise HTTPException(status_code=404, detail="Caretaker not found")
		if session.get(User, individual_id) is None:
			raise HTTPException(status_code=404, detail="Individual not found")

		share_exists = session.scalar(
			select(TotalSharepoint.id).where(
				TotalSharepoint.caretaker_id == caretaker_id,
				TotalSharepoint.individual_id == individual_id,
			)
		)
		if share_exists is None:
			raise HTTPException(status_code=404, detail="Share relationship not found")

		statement = (
			select(MeasureRecord)
			.where(
				MeasureRecord.user_id == individual_id,
				MeasureRecord.timestamp >= start,
				MeasureRecord.timestamp <= end,
			)
			.order_by(MeasureRecord.timestamp)
		)
		return _serialize_measures(session.scalars(statement).all())
