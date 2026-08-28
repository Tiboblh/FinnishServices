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

    conn = get_db_connection()

    items = conn.execute(
        """
        SELECT id, name, description, price, stock, pack, locked
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

    required = ("name", "description", "price", "stock", "pack", "locked")

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
            INSERT INTO catalog (name, description, price, stock, pack, locked)
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
            "description": data["description"],
            "name": data["name"],
            "price": data["price"],
            "stock": data["stock"],
            "pack": data["pack"],
            "locked": bool(data["locked"])
        }
    }), 201