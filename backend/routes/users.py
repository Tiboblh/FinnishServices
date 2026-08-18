from flask import Blueprint, request, jsonify

from database import get_db_connection
from utils import is_sha256, create_token
from auth import auth_required


users = Blueprint("users", __name__)


def get_user(value):
    conn = get_db_connection()

    user = conn.execute(
        """
        SELECT id, username, password, home_address,
               public_frogports, balance, token
        FROM users
        WHERE id = ? OR username = ? OR token = ?
        LIMIT 1
        """,
        (value, value, value)
    ).fetchone()

    conn.close()

    return user


def user_response(user):
    return jsonify({
        "username": user["username"],
        "homeaddress": user["home_address"],
        "use_public_frogports": bool(user["public_frogports"]),
        "balance": user["balance"],
        "token": user["token"]
    })


@users.route("/api/register", methods=["POST"])
def register():
    data = request.get_json(silent=True) or {}

    username = data.get("username")
    password = data.get("password")
    home_address = data.get("home_address")
    public_frogports = data.get("use_public_frogports")

    if None in (username, password, home_address, public_frogports):
        return jsonify({"error": "Missing variables"}), 400

    if not is_sha256(password):
        return jsonify({"error": "Invalid password hash"}), 400

    token = create_token(username, password)

    conn = get_db_connection()

    try:
        conn.execute(
            """
            INSERT INTO users
            (username, password, home_address, public_frogports, token)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                username,
                password,
                home_address,
                int(bool(public_frogports)),
                token
            )
        )

        conn.commit()

    except Exception as e:
        conn.close()

        if "UNIQUE" in str(e):
            return jsonify({"error": "User already exists"}), 400

        return jsonify({"error": str(e)}), 500

    conn.close()

    user = get_user(username)

    return user_response(user)


@users.route("/api/login", methods=["POST"])
def login():
    data = request.get_json(silent=True) or {}

    username = data.get("username")
    password = data.get("password")

    if username is None or password is None:
        return jsonify({"error": "Missing variables"}), 400

    conn = get_db_connection()

    user = conn.execute(
        """
        SELECT *
        FROM users
        WHERE username = ? AND password = ?
        """,
        (
            username,
            password
        )
    ).fetchone()

    conn.close()

    if user is None:
        return jsonify({"error": "Username or password is invalid"}), 400

    return user_response(user)


@users.route("/api/user_info", methods=["GET", "POST"])
@auth_required
def user_info(token):
    user = get_user(token)

    if user is None:
        return jsonify({"error": "User not found"}), 404

    # GET: simply return the current user information
    if request.method == "GET":
        return user_response(user)

    # POST: require the special header
    if request.headers.get("X-USER-CHANGE") != "True":
        return jsonify({
            "error": "X-USER-CHANGE header must be set to True"
        }), 403

    data = request.get_json(silent=True) or {}

    map_fields = {
        "username": "username",
        "homeaddress": "home_address",
        "home_address": "home_address",
        "use_public_frogports": "public_frogports"
    }

    updates = {}

    for key, db_key in map_fields.items():
        if key not in data:
            continue

        value = data[key]

        if value is None:
            continue

        if key == "username":
            if not isinstance(value, str) or not value.strip():
                return jsonify({
                    "error": "Username cannot be empty"
                }), 400

            if value != user["username"]:
                existing = get_user(value)

                if existing is not None and existing["id"] != user["id"]:
                    return jsonify({
                        "error": "User already exists"
                    }), 400

            updates[db_key] = value

        elif key in ("homeaddress", "home_address"):
            if not isinstance(value, str) or not value.strip():
                return jsonify({
                    "error": "Home address cannot be empty"
                }), 400

            updates[db_key] = value

        elif key == "use_public_frogports":
            updates[db_key] = int(bool(value))

    if not updates:
        return jsonify({
            "error": "No valid fields to update"
        }), 400

    conn = get_db_connection()

    try:
        assignments = ", ".join(
            f"{column} = ?" for column in updates
        )

        values = list(updates.values())
        values.append(user["id"])

        conn.execute(
            f"UPDATE users SET {assignments} WHERE id = ?",
            tuple(values)
        )

        conn.commit()

    except Exception as e:
        conn.rollback()
        conn.close()

        if "UNIQUE" in str(e):
            return jsonify({
                "error": "User already exists"
            }), 400

        return jsonify({
            "error": str(e)
        }), 500

    conn.close()

    # Re-fetch the user so POST returns exactly the same
    # information as GET, including any updated values.
    user = get_user(user["id"])

    return user_response(user)