from functools import wraps
from flask import request, jsonify

from database import get_db_connection


def auth_required(function):
    @wraps(function)
    def wrapper(*args, **kwargs):
        authorization = request.headers.get("Authorization", "")

        if not authorization.startswith("Bearer "):
            return jsonify({"error": "Unauthorized"}), 401

        token = authorization[7:]

        conn = get_db_connection()

        user = conn.execute(
            "SELECT id, username FROM users WHERE token = ?",
            (token,)
        ).fetchone()

        conn.close()

        if user is None:
            return jsonify({"error": "Unauthorized"}), 401

        return function(token, *args, **kwargs)

    return wrapper

def admin_required(function):
    @wraps(function)
    def wrapper(*args, **kwargs):
        authorization = request.headers.get("Authorization", "")

        if not authorization.startswith("Bearer "):
            return jsonify({"error": "Unauthorized"}), 401

        token = authorization[7:]

        conn = get_db_connection()

        user = conn.execute(
            "SELECT id, username, is_admin FROM users WHERE token = ?",
            (token,)
        ).fetchone()

        conn.close()

        if user is None:
            return jsonify({"error": "Unauthorized"}), 401
        if user["is_admin"] != 1:
            return jsonify({"error": "Unauthorized"}), 401

        return function(token, *args, **kwargs)

    return wrapper