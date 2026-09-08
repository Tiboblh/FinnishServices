from flask import Blueprint, request, jsonify

from database import get_db_connection
from auth import auth_required, admin_required


orders = Blueprint("orders", __name__)


@orders.route("/api/order", methods=["POST"])
@auth_required
def create_order(token):
    data = request.get_json(silent=True) or {}

    items = data.get("items")

    if not isinstance(items, list) or len(items) == 0:
        return jsonify({
            "error": "Invalid order"
        }), 400

    conn = get_db_connection()

    try:
        user = conn.execute(
            """
            SELECT
                id,
                balance
            FROM users
            WHERE token = ?
            """,
            (token,)
        ).fetchone()

        if user is None:
            return jsonify({
                "error": "Unauthorized"
            }), 401

        total = 0
        checked_items = []

        for item in items:

            if not isinstance(item, dict):
                return jsonify({
                    "error": "Invalid item"
                }), 400

            item_id = str(item.get("id", ""))

            quantity = item.get(
                "qty",
                item.get("quantity", 0)
            )

            try:
                quantity = int(quantity)
            except (TypeError, ValueError):
                return jsonify({
                    "error": "Invalid quantity"
                }), 400

            if quantity <= 0:
                return jsonify({
                    "error": "Invalid quantity"
                }), 400

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
                return jsonify({
                    "error": "Item not found"
                }), 404

            if product["shop_id"] is None:
                return jsonify({
                    "error": "Item has no shop"
                }), 500

            pack = product["pack"]

            if pack <= 0:
                return jsonify({
                    "error": "Invalid product pack"
                }), 500

            # Nombre de packs nécessaires.
            packs = (quantity + pack - 1) // pack

            # Quantité physique retirée du stock.
            stock_used = packs * pack

            if stock_used > product["stock"]:
                return jsonify({
                    "error": "Not enough stock"
                }), 409

            # Le prix du catalogue correspond à UN pack.
            cost = product["price"] * packs

            total += cost

            checked_items.append({
                "id": product["id"],
                "shop_id": product["shop_id"],
                "quantity": quantity,
                "packs": packs,
                "stock_used": stock_used,
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
            (
                user_id,
                total,
                notes,
                delivered
            )
            VALUES (?, ?, ?, 0)
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
                (
                    order_id,
                    item_id,
                    quantity,
                    price
                )
                VALUES (?, ?, ?, ?)
                """,
                (
                    order_id,
                    item["id"],
                    item["quantity"],
                    item["price"]
                )
            )

            # IMPORTANT :
            # on retire la quantité réelle utilisée,
            # pas packs * packs.
            cursor.execute(
                """
                UPDATE catalog
                SET stock = stock - ?
                WHERE id = ?
                """,
                (
                    item["stock_used"],
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


@orders.route("/api/deliver", methods=["GET"])
@admin_required
def get_delivery_orders(token):
    conn = get_db_connection()

    try:

        orders_result = conn.execute(
            """
            SELECT
                orders.id,
                users.home_address AS address
            FROM orders
            JOIN users
                ON users.id = orders.user_id
            WHERE orders.delivered = 0
            ORDER BY orders.id ASC
            """
        ).fetchall()

        result = []

        for order in orders_result:

            items_result = conn.execute(
                """
                SELECT
                    item_id,
                    quantity
                FROM order_items
                WHERE order_id = ?
                ORDER BY id ASC
                """,
                (order["id"],)
            ).fetchall()

            items = []

            for item in items_result:
                items.append({
                    "itemID": item["item_id"],
                    "quantity": item["quantity"]
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


@orders.route("/api/deliver", methods=["POST"])
@admin_required
def satisfy_delivery_orders(token):
    data = request.get_json(silent=True) or {}

    satisfied = data.get("satisfied")

    if not isinstance(satisfied, list):
        return jsonify({
            "error": "Invalid satisfied list"
        }), 400

    conn = get_db_connection()

    try:
        user, error = admin_required(
            conn,
            token
        )

        if error:
            return error

        order_ids = []

        for order_id in satisfied:
            try:
                order_id = int(order_id)
            except (TypeError, ValueError):
                return jsonify({
                    "error": "Invalid order ID"
                }), 400

            if order_id <= 0:
                return jsonify({
                    "error": "Invalid order ID"
                }), 400

            order_ids.append(order_id)

        # Évite les doublons.
        order_ids = list(dict.fromkeys(order_ids))

        updated = []

        for order_id in order_ids:

            cursor = conn.execute(
                """
                UPDATE orders
                SET delivered = 1
                WHERE id = ?
                AND delivered = 0
                """,
                (order_id,)
            )

            if cursor.rowcount > 0:
                updated.append(order_id)

        conn.commit()

        return jsonify({
            "satisfied": updated
        })

    except Exception as e:
        conn.rollback()

        return jsonify({
            "error": str(e)
        }), 500

    finally:
        conn.close()


@orders.route("/api/admin", methods=["GET"])
@admin_required
def admin_get(token):
    conn = get_db_connection()

    try:

        username = request.headers.get("accUsername")
        field = request.headers.get("field")

        if not username or not field:
            return jsonify({
                "error": "Missing accUsername or field"
            }), 400

        allowed_fields = {
            "id",
            "username",
            "home_address",
            "public_frogports",
            "balance",
            "is_vendor",
            "is_admin",
        }

        if field not in allowed_fields:
            return jsonify({
                "error": "Invalid field"
            }), 400

        account = conn.execute(
            f"""
            SELECT
                {field}
            FROM users
            WHERE username = ?
            """,
            (username,)
        ).fetchone()

        if account is None:
            return jsonify({
                "error": "Account not found"
            }), 404

        return jsonify({
            field: account[field]
        })

    except Exception as e:
        return jsonify({
            "error": str(e)
        }), 500

    finally:
        conn.close()