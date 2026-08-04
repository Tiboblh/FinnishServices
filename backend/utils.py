import hashlib
import re


def is_sha256(value) -> bool:
    return bool(re.fullmatch(r"[a-fA-F0-9]{64}", value or ""))


def hash_sha256(value) -> str:
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def create_token(username, password) -> str:
    return hash_sha256(hash_sha256(username) + password)