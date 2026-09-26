

import hashlib
import secrets


_SCRYPT_N = 2**14
_SCRYPT_R = 8
_SCRYPT_P = 1
_HASH_BYTES = 64


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


print(hash_password("abc123"))