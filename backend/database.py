import sqlite3

from config import DATABASE_PATH


SCHEMA = {
    "users": {
        "columns": {
            "id": "INTEGER PRIMARY KEY AUTOINCREMENT",
            "username": "TEXT NOT NULL UNIQUE",
            "password": "TEXT NOT NULL",
            "home_address": "TEXT NOT NULL",
            "public_frogports": "INTEGER NOT NULL DEFAULT 0",
            "balance": "INTEGER NOT NULL DEFAULT 0",
            "token": "TEXT NOT NULL UNIQUE",
            "is_vendor": "INTEGER NOT NULL DEFAULT 0",
            "is_admin": "INTEGER NOT NULL DEFAULT 0",
        },
        "primary_key": "id",
    },

    "shops": {
        "columns": {
            "id": "INTEGER PRIMARY KEY AUTOINCREMENT",
            "user_id": "INTEGER NOT NULL",
            "name": "TEXT NOT NULL UNIQUE",
        },
        "primary_key": "id",
    },

    "catalog": {
        "columns": {
            "id": "TEXT PRIMARY KEY",
            "shop_id": "INTEGER",
            "name": "TEXT NOT NULL",
            "description": "TEXT NOT NULL",
            "price": "INTEGER NOT NULL CHECK(price >= 0)",
            "stock": "INTEGER NOT NULL DEFAULT 0 CHECK(stock >= 0)",
            "pack": "INTEGER NOT NULL DEFAULT 1 CHECK(pack >= 1)",
            "locked": "INTEGER NOT NULL DEFAULT 0",
        },
        "primary_key": "id",
    },

    "orders": {
        "columns": {
            "id": "INTEGER PRIMARY KEY AUTOINCREMENT",
            "user_id": "INTEGER NOT NULL",
            "total": "INTEGER NOT NULL CHECK(total >= 0)",
            "notes": "TEXT DEFAULT ''",
            "delivered": "INTEGER NOT NULL DEFAULT 0",
            "created_at": "TIMESTAMP DEFAULT CURRENT_TIMESTAMP",
        },
        "primary_key": "id",
    },

    "order_items": {
        "columns": {
            "id": "INTEGER PRIMARY KEY AUTOINCREMENT",
            "order_id": "INTEGER NOT NULL",
            "item_id": "TEXT NOT NULL",
            "quantity": "INTEGER NOT NULL CHECK(quantity > 0)",
            "price": "INTEGER NOT NULL CHECK(price >= 0)",
        },
        "primary_key": "id",
    },
}


FOREIGN_KEYS = {
    "shops": [
        "FOREIGN KEY(user_id) REFERENCES users(id)"
    ],

    "catalog": [
        "FOREIGN KEY(shop_id) REFERENCES shops(id)"
    ],

    "orders": [
        "FOREIGN KEY(user_id) REFERENCES users(id)"
    ],

    "order_items": [
        "FOREIGN KEY(order_id) REFERENCES orders(id)",
        "FOREIGN KEY(item_id) REFERENCES catalog(id)"
    ],
}


def get_db_connection():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row

    conn.execute("PRAGMA foreign_keys = ON")

    return conn


def quote_identifier(identifier):
    return '"' + identifier.replace('"', '""') + '"'


def table_exists(conn, table_name):
    row = conn.execute(
        """
        SELECT 1
        FROM sqlite_master
        WHERE type = 'table'
        AND name = ?
        """,
        (table_name,)
    ).fetchone()

    return row is not None


def create_table(conn, table_name):
    definition = SCHEMA[table_name]

    columns = []

    for column_name, column_type in definition["columns"].items():
        columns.append(
            f"{quote_identifier(column_name)} {column_type}"
        )

    for foreign_key in FOREIGN_KEYS.get(table_name, []):
        columns.append(foreign_key)

    sql = f"""
        CREATE TABLE IF NOT EXISTS {quote_identifier(table_name)}
        (
            {", ".join(columns)}
        )
    """

    conn.execute(sql)


def init_database():
    conn = get_db_connection()

    try:
        # L'ordre est important pour les foreign keys.
        create_table(conn, "users")
        create_table(conn, "shops")
        create_table(conn, "catalog")
        create_table(conn, "orders")
        create_table(conn, "order_items")

        conn.commit()

    finally:
        conn.close()


if __name__ == "__main__":
    init_database()
    print("Database initialized.")