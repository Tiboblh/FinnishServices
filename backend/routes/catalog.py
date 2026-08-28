from flask import Blueprint, jsonify, request

from database import get_db_connection
from auth import auth_required


catalog = Blueprint("catalog", __name__)

SPECIAL_TOKEN = "c48c42e49730405b65a1fe94e813a601b18273cab760fbfec02635d1457c8356" # tibo can we please make this have sum "is admin" tag be used instead of a specific token?


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


@catalog.route("/api/catalog", methods=["GET", "POST"])
@auth_required
def catalog_api(token):
    if request.method == "POST":
        conn = get_db_connection()

        account = conn.execute(
            """
            SELECT is_admin
            FROM accounts
            WHERE token = ?
            LIMIT 1
            """,
            (token,)
        ).fetchone()

        if account is None:
            account = conn.execute(
                """
                SELECT is_admin
                FROM users
                WHERE token = ?
                LIMIT 1
                """,
                (token,)
            ).fetchone()

        if account is None or not bool(account[0]):
            conn.close()
            return jsonify({
                "error": "unauthorzied"
            }), 403

        data = request.get_json(silent=True)

        if not data:
            conn.close()
            return jsonify({
                "error": "JSON body required"
            }), 400

        required = ("name", "description", "price", "stock", "pack", "locked")

        missing = [field for field in required if field not in data]

        if missing:
            conn.close()
            return jsonify({
                "error": "Missing fields",
                "fields": missing
            }), 400

        try:
            conn.execute(
                """
                INSERT INTO catalog ( name, description, price, stock, pack, locked)
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

            conn.commit()
            conn.close()

        except Exception as e:
            conn.close()
            return jsonify({
                "error": str(e)
            }), 500

        return jsonify({
            "success": True,
            "item": {
                "id": data["id"],
                "description": data["description"],
                "name": data["name"],
                "price": data["price"],
                "stock": data["stock"],
                "pack": data["pack"],
                "locked": bool(data["locked"])
            }
        }), 201

    # GET
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