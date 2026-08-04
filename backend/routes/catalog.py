from flask import Blueprint, jsonify, request

from database import get_db_connection
from auth import auth_required


catalog = Blueprint("catalog", __name__)


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
def get_catalog(token):
    conn = get_db_connection()

    items = conn.execute(
        """
        SELECT id, name, price, stock
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