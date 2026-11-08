
from flask import Blueprint, request, jsonify
from database import get_db_connection
from auth import admin_required

from decimal import Decimal, InvalidOperation


atm = Blueprint("atm", __name__)


def find_user(conn, user):
    if user is None or str(user).strip() == "":
        return None

    user = str(user).strip()

    # Try user ID first
    if user.isdigit():
        result = conn.execute(
            "SELECT id, username, balance FROM users WHERE id = ?",
            (int(user),)
        ).fetchone()

        if result:
            return result

    # Otherwise try username
    return conn.execute(
        "SELECT id, username, balance FROM users WHERE username = ?",
        (user,)
    ).fetchone()


def parse_amount(raw):
    if isinstance(raw, bool) or raw is None:
        return None

    try:
        amount = Decimal(str(raw))

        if not amount.is_finite():
            return None

        if amount != amount.to_integral_value():
            return None

        amount = int(amount)

        if isinstance(raw, str) and raw.startswith("+"):
            if amount <= 0:
                return None
            return "add", amount

        if amount < 0:
            return "remove", abs(amount)

        return "set", amount

    except (InvalidOperation, ValueError, TypeError):
        return None


# ==========================================
# GET USER BALANCE
# ==========================================

@atm.route("/api/atm", methods=["GET"])
@admin_required
def get_money(token):

    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({
            "error": "Expected a JSON object"
        }), 400

    if "amount" in data:
        return jsonify({
            "error": "GET does not accept an amount"
        }), 400

    user_id = data.get("user")

    if user_id is None or str(user_id).strip() == "":
        return jsonify({
            "error": "Missing required parameter: user"
        }), 400

    conn = get_db_connection()

    try:
        user = find_user(conn, user_id)

        if user is None:
            return jsonify({
                "error": "User not found"
            }), 404

        return jsonify({
            "user": user["id"],
            "username": user["username"],
            "balance": user["balance"]
        }), 200

    finally:
        conn.close()


# ==========================================
# MODIFY USER BALANCE
# ==========================================

@atm.route("/api/atm", methods=["POST"])
@admin_required
def modify_money(token):

    data = request.get_json(silent=True)

    if not isinstance(data, dict):
        return jsonify({
            "error": "Expected a JSON object"
        }), 400

    user_id = data.get("user")

    if user_id is None or str(user_id).strip() == "":
        return jsonify({
            "error": "Missing required parameter: user"
        }), 400

    if "amount" not in data:
        return jsonify({
            "error": "Missing required parameter: amount"
        }), 400

    parsed = parse_amount(data["amount"])

    if parsed is None:
        return jsonify({
            "error": "Invalid amount (must be a whole number)"
        }), 400

    operation, amount = parsed

    conn = get_db_connection()

    try:
        conn.execute("BEGIN IMMEDIATE")

        target = find_user(conn, user_id)

        if target is None:
            conn.rollback()
            return jsonify({
                "error": "User not found"
            }), 404

        current_balance = target["balance"]

        if operation == "set":
            new_balance = amount

        elif operation == "add":
            new_balance = current_balance + amount

        else:
            if current_balance < amount:
                conn.rollback()

                return jsonify({
                    "error": "Insufficient funds",
                    "current_balance": current_balance,
                    "requested": amount
                }), 400

            new_balance = current_balance - amount

        conn.execute(
            "UPDATE users SET balance = ? WHERE id = ?",
            (new_balance, target["id"])
        )

        conn.commit()

        return jsonify({
            "message": "Balance updated successfully",
            "user": target["id"],
            "username": target["username"],
            "operation": operation,
            "amount": amount,
            "old_balance": current_balance,
            "new_balance": new_balance
        }), 200

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()
