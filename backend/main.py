from flask import *
import sqlite3
import hashlib
import re

app = Flask(__name__)

conn = sqlite3.connect("data.db")
cursor = conn.cursor()

cursor.execute("""
CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT NOT NULL UNIQUE,
    password TEXT NOT NULL,
    home_address TEXT,
    public_frogports BOOLEAN NOT NULL,
    balance INT NOT NULL DEFAULT 0,
    token TEXT NOT NULL UNIQUE
)
""")

def is_sha256(s: str) -> bool:
    return bool(re.fullmatch(r"[a-fA-F0-9]{64}", s))

def hash_sha256(s: str) -> str:
  return str(hashlib.sha256(s.encode()).hexdigest())

def create_user(username: str, password: str, home_address: str, public_frogports: bool) -> tuple[int, str]:
  if not all(x is not None for x in (username, password, home_address, public_frogports)):
    return 1, "Missing variables"
  if not is_sha256(password):
    return 2, "Invalid password hash"
  token = hash_sha256(hash_sha256(username)+password)
  try:
    cursor.execute(
    "INSERT INTO users (username, passsword, home_address, public_frogports, token) VALUES (?, ?, ?, ?)",
    (username, password, home_address, int(public_frogports), token)
    )

    conn.commit()
  except sqlite3.IntegrityError:
    return 3, "User already exists"
  except Exception as e:
    return 4, "Other db error: " + str(e)
  return 0, ""