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
            except (TypeError, ValueError):
                return jsonify({"error": "Invalid quantity"}), 400

            if quantity <= 0:
                return jsonify({"error": "Invalid quantity"}), 400

            product = conn.execute(
                """
                SELECT
                    id,
                    shop_id,
                    name,
                    price,
                    stock,
                    pack
                FROM catalog
                WHERE id = ?
                """,
                (item_id,)
            ).fetchone()

            if product is None:
                return jsonify({"error": "Item not found"}), 404

            if product["shop_id"] is None:
                return jsonify({
                    "error": "Item has no shop"
                }), 500

            # quantity = quantité brute commandée
            # pack = taille d'un pack
            #
            # Le prix du catalogue correspond à UN pack.
            # On calcule donc le nombre de packs nécessaires.
            pack = product["pack"]

            packs = (quantity + pack - 1) // pack

            if packs * pack > product["stock"]:
                return jsonify({
                    "error": "Not enough stock"
                }), 409

            cost = product["price"] * packs

            total += cost

            checked_items.append({
                "id": product["id"],
                "shop_id": product["shop_id"],
                "quantity": quantity,
                "packs": packs,
                "price": product["price"]
            })

        if total > user["balance"]:
            return jsonify({
                "error": "Insufficient funds"
            }), 402

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

            # Le stock est stocké en quantité brute.
            cursor.execute(
                """
                UPDATE catalog
                SET stock = stock - ?
                WHERE id = ?
                """,
                (
                    item["packs"] * item["packs"],
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

        return jsonify({
            "error": str(e)
        }), 500

    finally:
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

    try:
        user = conn.execute(
            """
            SELECT id
            FROM users
            WHERE token = ?
            """,
            (token,)
        ).fetchone()

        if user is None:
            return jsonify({
                "error": "Unauthorized"
            }), 401

        orders_result = conn.execute(
            """
            SELECT
                orders.id,
                users.home_address AS address
            FROM orders
            JOIN users
                ON users.id = orders.user_id
            WHERE orders.user_id = ?
            ORDER BY orders.id DESC
            """,
            (user["id"],)
        ).fetchall()

        result = []

        for order in orders_result:

            items_result = conn.execute(
                """
                SELECT
                    catalog.shop_id,
                    order_items.item_id,
                    order_items.quantity
                FROM order_items
                JOIN catalog
                    ON catalog.id = order_items.item_id
                WHERE order_items.order_id = ?
                """,
                (order["id"],)
            ).fetchall()

            items = []

            for item in items_result:
                items.append({
                    "shopID": item["shop_id"],
                    "itemID": item["item_id"],
                    "qty": item["quantity"]
                })

            result.append({
                "id": order["id"],
                "address": order["address"],
                "items": items
            })

        return jsonify(result)

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500

    finally:
        conn.close()