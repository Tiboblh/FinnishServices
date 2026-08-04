from flask import *
import sqlite3
import hashlib
import re
from functools import wraps

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

def auth_required(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        auth = request.headers.get("Authorization", "")

        if not auth.startswith("Bearer "):
            return jsonify({"error": "Unauthorized"}), 401

        token = auth[7:]

        cursor.execute(
            "SELECT id, username FROM users WHERE token = ?",
            (token,)
        )

        user = cursor.fetchone()

        if user is None:
            return jsonify({"error": "Unauthorized"}), 401

        return f(token, *args, **kwargs)

    return wrapper

def get_userdata(tokenname: str):
  cursor.execute(
    "SELECT username, password, home_address, public_frogports, token, balance FROM users WHERE username = ?",
    (tokenname,)
  )
  result = cursor.fetchone()
  if result != None:
    return result
  cursor.execute(
    "SELECT username, home_address, public_frogports, token, balance FROM users WHERE token = ?",
    (tokenname,)
  )
  result2 = cursor.fetchone()
  if result2 != None:
    return result
  return None

@app.route("/api/register", methods=["POST"])
def register():
  data = request.get_json()
  try:
    status, message = create_user(data.get("username"), data.get("password"), data.get("home_address"), data.get("use_public_frogports"))
  except Exception as e:
    return jsonify({"error": str(e)}), 400
  if status != 0:
    return jsonify({"error": message}), 400
  userdata = get_userdata(data.get("username"))
  if userdata == None:
    return jsonify({"error": "Your account was created but the userinfo could not be fetched"}), 500
  username,homeaddr,frogports,token, balance = userdata
  return jsonify({"username":username, "homeaddress": homeaddr, "use_public_frogports": str(bool(frogports)), "balance": balance, "token": token}), 200

@app.route("/api/login", methods=["POST"])
def login():
  data = request.get_json()
  cursor.execute(
    "SELECT token FROM users WHERE username = ? AND password = ?",
    (data.get("username"), data.get("password"))
  )

  result = cursor.fetchone()
  if result == None:
    return jsonify({"error": "Username or passsord is invalid"}), 400
  userdata = get_userdata(result)
  if userdata == None:
    return jsonify({"error": "The creditentials you entered were correct but the server could not fetch your user data"}), 500
  username,homeaddr,frogports,token, balance = userdata
  return jsonify({"username":username,  "homeaddress": homeaddr, "use_public_frogports": str(bool(frogports)), "balance": balance, "token": token}), 200

@app.route("/api/user_info", methods=["GET"])
@auth_required
def user_info(token):
  userdata = get_userdata(token)
  if userdata == None:
    return jsonify({"error": "The token given was correct but the server could not fetch user data"}), 500
  username,homeaddr,frogports,token, balance = userdata
  return jsonify({"username":username, "homeaddress": homeaddr, "use_public_frogports": str(bool(frogports)), "balance": balance, "token": token}), 200

if __name__ == "__main__":
  app.run(debug=True,port=9142)
  conn.close()