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


@shop.route("/api/shops", methods=["GET"])
@auth_required
def get_shops(token):
    conn = get_db_connection()

    try:
        shops = conn.execute(
            """
            SELECT
                shops.id,
                shops.name,
                users.username AS owner
            FROM shops
            JOIN users ON shops.user_id = users.id
            ORDER BY shops.id ASC
            """
        ).fetchall()

        return jsonify([
            {
                "id": shop["id"],
                "shop_name": shop["name"],
                "owner": shop["owner"]
            }
            for shop in shops
        ]), 200

    finally:
        conn.close()


@shop.route("/api/change_shops", methods=["POST"])
@admin_required
def change_shops(token):

    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "error": "JSON body required"
        }), 400

    # Suppression d'un shop
    if data.get("delete") is True:

        shop_id = data.get("id")

        if not shop_id:
            return jsonify({
                "error": "Shop ID required"
            }), 400

        try:
            conn = get_db_connection()

            cursor = conn.execute(
                "DELETE FROM shops WHERE id = ?",
                (shop_id,)
            )

            conn.commit()
            deleted = cursor.rowcount

            conn.close()

            if deleted == 0:
                return jsonify({
                    "error": "Shop not found"
                }), 404

            return jsonify({
                "success": True,
                "deleted": True,
                "id": shop_id
            }), 200

        except Exception as e:
            return jsonify({
                "error": str(e)
            }), 500

    # Ajout d'un shop
    required = (
        "user_id",
        "name"
    )

    missing = [field for field in required if field not in data]

    if missing:
        return jsonify({
            "error": "Missing fields",
            "fields": missing
        }), 400

    try:
        conn = get_db_connection()

        cursor = conn.execute(
            """
            INSERT INTO shops
            (user_id, name)
            VALUES (?, ?)
            """,
            (
                data["user_id"],
                data["name"]
            )
        )

        shop_id = cursor.lastrowid

        conn.commit()
        conn.close()

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500

    return jsonify({
        "success": True,
        "shop": {
            "id": shop_id,
            "user_id": data["user_id"],
            "name": data["name"]
        }
    }), 201
