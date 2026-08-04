from flask import Blueprint, request, jsonify

from database import get_db_connection
from auth import auth_required


orders = Blueprint("orders", __name__)


@orders.route("/api/order", methods=["POST"])
@auth_required
def create_order(token):
    data = request.get_json(silent=True) or {}

    items = data.get("items")

    if not isinstance(items, list) or len(items) == 0:
        return jsonify({"error": "Invalid order"}), 400

    conn = get_db_connection()

    try:
        user = conn.execute(
            """
            SELECT id, balance
            FROM users
            WHERE token = ?
            """,
            (token,)
        ).fetchone()

        if user is None:
            return jsonify({"error": "Unauthorized"}), 401


        total = 0
        checked_items = []


        for item in items:
            item_id = str(item.get("id", ""))

            quantity = item.get(
                "qty",
                item.get("quantity", 0)
            )

            try:
                quantity = int(quantity)
            except:
                return jsonify({"error": "Invalid quantity"}), 400


            if quantity <= 0:
                return jsonify({"error": "Invalid quantity"}), 400


            product = conn.execute(
                """
                SELECT id, name, price, stock
                FROM catalog
                WHERE id = ?
                """,
                (item_id,)
            ).fetchone()


            if product is None:
                return jsonify({"error": "Item not found"}), 404


            if quantity > product["stock"]:
                return jsonify({"error": "Not enough stock"}), 409


            cost = product["price"] * quantity

            total += cost

            checked_items.append({
                "id": product["id"],
                "quantity": quantity,
                "price": product["price"]
            })


        if total > user["balance"]:
            return jsonify({"error": "Insufficient funds"}), 402


        cursor = conn.cursor()


        cursor.execute(
            """
            INSERT INTO orders
            (user_id, total, notes)
            VALUES (?, ?, ?)
            """,
            (
                user["id"],
                total,
                data.get("notes", "")
            )
        )


        order_id = cursor.lastrowid


        for item in checked_items:

            cursor.execute(
                """
                INSERT INTO order_items
                (order_id, item_id, quantity, price)
                VALUES (?, ?, ?, ?)
                """,
                (
                    order_id,
                    item["id"],
                    item["quantity"],
                    item["price"]
                )
            )


            cursor.execute(
                """
                UPDATE catalog
                SET stock = stock - ?
                WHERE id = ?
                """,
                (
                    item["quantity"],
                    item["id"]
                )
            )


        cursor.execute(
            """
            UPDATE users
            SET balance = balance - ?
            WHERE id = ?
            """,
            (
                total,
                user["id"]
            )
        )


        conn.commit()


    except Exception as e:
        conn.rollback()
        conn.close()

        return jsonify({
            "error": str(e)
        }), 500


    conn.close()


    return jsonify({
        "ok": True,
        "order_id": order_id,
        "total": total
    })


@orders.route("/api/orders", methods=["GET"])
@auth_required
def get_orders(token):
    conn = get_db_connection()


    user = conn.execute(
        """
        SELECT id
        FROM users
        WHERE token = ?
        """,
        (token,)
    ).fetchone()


    if user is None:
        conn.close()
        return jsonify({"error": "Unauthorized"}), 401


    result = conn.execute(
        """
        SELECT id, total, notes, created_at
        FROM orders
        WHERE user_id = ?
        ORDER BY id DESC
        """,
        (user["id"],)
    ).fetchall()


    conn.close()


    return jsonify({
        "orders": [
            dict(order)
            for order in result
        ]
    })