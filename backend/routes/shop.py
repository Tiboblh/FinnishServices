from flask import Blueprint, request, jsonify

from database import get_db_connection
from utils import is_sha256, create_token
from auth import auth_required


shop = Blueprint("shop", __name__)

@shop.route("/api/shop", methods=["POST"])
@auth_required
def shop_info(token):
    data = request.get_json(silent=True) or {}
    
    shop_id = data.get("shop_id", "")

    if shop_id == "" or None:
        return {"error": "Missing or invalid shop id"}, 400
    try:
        shop_int = int(shop_id)
    except Exception:
        return {"error": "Given shop id is not a number"}, 400
    
    conn = get_db_connection()

    shop = conn.execute(
        """
        SELECT *
        FROM shops
        WHERE id = ?
        """,
        (
            shop_int
        )
    ).fetchone()
    if shop is None:
        return jsonify({"error": "Unkown shop"}), 400

    conn.close()
    conn = get_db_connection()

    user = conn.execute(
        """
        SELECT *
        FROM users
        WHERE id = ?
        """,
        (
            shop["user_id"]
        )
    ).fetchone()

    conn.close()
    
    return jsonify({"id": shop_int, "shop_name": shop["name"], "owner": user["username"]})
