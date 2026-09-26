import hashlib
import hmac
import secrets
from collections.abc import Callable

from fastapi import Depends, HTTPException, Request
from fastapi.security import HTTPBasic, HTTPBasicCredentials
from sqlalchemy import select

import db
from models import User, UserRole


_SCRYPT_N = 2**14
_SCRYPT_R = 8
_SCRYPT_P = 1
_HASH_BYTES = 64
basic_auth = HTTPBasic()


def hash_password(password: str) -> str:
	salt = secrets.token_bytes(16)
	digest = hashlib.scrypt(
		password.encode("utf-8"),
		salt=salt,
		n=_SCRYPT_N,
		r=_SCRYPT_R,
		p=_SCRYPT_P,
		dklen=_HASH_BYTES,
	)
	return f"scrypt${salt.hex()}${digest.hex()}"


def verify_password(password: str, encoded_hash: str) -> bool:
	try:
		algorithm, salt_hex, digest_hex = encoded_hash.split("$", 2)
		if algorithm != "scrypt":
			return False

		salt = bytes.fromhex(salt_hex)
		expected_digest = bytes.fromhex(digest_hex)
		if len(salt) != 16 or len(expected_digest) != _HASH_BYTES:
			return False

		digest = hashlib.scrypt(
			password.encode("utf-8"),
			salt=salt,
			n=_SCRYPT_N,
			r=_SCRYPT_R,
			p=_SCRYPT_P,
			dklen=_HASH_BYTES,
		)
		return hmac.compare_digest(digest, expected_digest)
	except (ValueError, TypeError):
		return False


def authenticate_basic(
	credentials: HTTPBasicCredentials = Depends(basic_auth),
) -> User:
	with db.SessionLocal() as session:
		user = session.scalar(select(User).where(User.username == credentials.username))
		if (
			user is None
			or user.hashed_password is None
			or not verify_password(credentials.password, user.hashed_password)
		):
			raise HTTPException(
				status_code=401,
				detail="Invalid username or password",
				headers={"WWW-Authenticate": "Basic"},
			)
		return user


def require_path_user(
	path_parameter: str,
	required_role: UserRole,
) -> Callable[..., None]:
	def check_path_user(
		request: Request,
		user: User = Depends(authenticate_basic),
	) -> None:
		path_user_id = request.path_params.get(path_parameter)
		if (
			path_user_id is None
			or user.id != int(path_user_id)
			or user.role != required_role
		):
			raise HTTPException(
				status_code=403,
				detail="Authenticated user does not have access to this route",
			)

	return check_path_user
