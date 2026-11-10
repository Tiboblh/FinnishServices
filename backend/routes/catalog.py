from flask import Blueprint, jsonify, request

from database import get_db_connection
from auth import auth_required, admin_required


catalog = Blueprint("catalog", __name__)

 # tibo can we please make this have sum "is admin" tag be used instead of a specific token?
# done, use @admin_required with routes


def format_lua(items):
    def lua_quote(value):
        value = str(value)
        value = value.replace("\\", "\\\\")
        value = value.replace('"', '\\"')
        value = value.replace("\n", "\\n")
        value = value.replace("\r", "\\r")
        return '"' + value + '"'

    lines = ["return {"]

    for item in items:
        lines.append("  {")
        lines.append(f"    id = {lua_quote(item['id'])},")
        lines.append(f"    name = {lua_quote(item['name'])},")
        lines.append(f"    price = {item['price']},")
        lines.append(f"    stock = {item['stock']},")
        lines.append("  },")

    lines.append("}")

    return "\n".join(lines)


@catalog.route("/api/catalog", methods=["GET"])
@auth_required
def catalog_api(token):
    data = request.get_json(silent=True) or {}

    shop_id = data.get("shop_id", "")

    if shop_id != "":
        try:
            shop_id_int = int(shop_id)
        except Exception as e:
            return jsonify({"error": e}), 400
        
        conn = get_db_connection()
        items = conn.execute(
            """
            SELECT id, shop_id, name, description, price, stock, pack, locked
            FROM catalog
            ORDER BY LOWER(name)
            WHERE 
            """, (shop_id_int,)
        ).fetchall()

        items = [dict(item) for item in items]

        force_lua = (
            request.args.get("format", "").lower() == "lua"
            or request.headers.get("X-Format", "").lower() == "lua"
            or request.headers.get("Catalog", "").lower() == "catalog"
        )

        if force_lua:
            return (
                format_lua(items),
                200,
                {"Content-Type": "text/plain; charset=utf-8"}
            )

        return jsonify({
            "catalog": items
        })



    conn = get_db_connection()

    items = conn.execute(
        """
        SELECT id, shop_id, name, description, price, stock, pack, locked
        FROM catalog
        ORDER BY LOWER(name)
        """
    ).fetchall()

    conn.close()

    items = [dict(item) for item in items]

    force_lua = (
        request.args.get("format", "").lower() == "lua"
        or request.headers.get("X-Format", "").lower() == "lua"
        or request.headers.get("Catalog", "").lower() == "catalog"
    )

    if force_lua:
        return (
            format_lua(items),
            200,
            {"Content-Type": "text/plain; charset=utf-8"}
        )

    return jsonify({
        "catalog": items
    })



@catalog.route("/api/change_catalog", methods=["POST"])
@admin_required
def change_catalog(token):

    data = request.get_json(silent=True)

    if not data:
        return jsonify({
            "error": "JSON body required"
        }), 400

    # Suppression d'un produit
    if data.get("delete") is True:

        item_id = data.get("id")

        if not item_id:
            return jsonify({
                "error": "Product ID required"
            }), 400

        try:
            conn = get_db_connection()

            cursor = conn.execute(
                "DELETE FROM catalog WHERE id = ?",
                (item_id,)
            )

            conn.commit()
            deleted = cursor.rowcount

            conn.close()

            if deleted == 0:
                return jsonify({
                    "error": "Product not found"
                }), 404

            return jsonify({
                "success": True,
                "deleted": True,
                "id": item_id
            }), 200

        except Exception as e:
            return jsonify({
                "error": str(e)
            }), 500

    # Ajout d'un produit
    required = (
        "name",
        "description",
        "price",
        "stock",
        "pack",
        "locked"
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
            INSERT INTO catalog
            (name, description, price, stock, pack, locked)
            VALUES (?, ?, ?, ?, ?, ?)
            """,
            (
                data["name"],
                data["description"],
                data["price"],
                data["stock"],
                data["pack"],
                data["locked"]
            )
        )

        item_id = cursor.lastrowid

        conn.commit()
        conn.close()

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500

    return jsonify({
        "success": True,
        "item": {
            "id": item_id,
            "name": data["name"],
            "description": data["description"],
            "price": data["price"],
            "stock": data["stock"],
            "pack": data["pack"],
            "locked": bool(data["locked"])
        }
    }), 201
