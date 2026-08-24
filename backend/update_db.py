import sqlite3
from config import DATABASE_PATH


def get_db_connection():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn


# Database schema
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

    "catalog": {
        "columns": {
            "id": "TEXT PRIMARY KEY",
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
    "orders": [
        "FOREIGN KEY(user_id) REFERENCES users(id)"
    ],
    "order_items": [
        "FOREIGN KEY(order_id) REFERENCES orders(id)",
        "FOREIGN KEY(item_id) REFERENCES catalog(id)"
    ],
}


def quote_identifier(name):
    """Safely quote an SQLite identifier."""
    return '"' + name.replace('"', '""') + '"'


def table_exists(conn, table_name):
    result = conn.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table' AND name = ?
        """,
        (table_name,)
    ).fetchone()

    return result is not None


def get_existing_columns(conn, table_name):
    rows = conn.execute(
        f"PRAGMA table_info({quote_identifier(table_name)})"
    ).fetchall()

    return {row["name"]: row for row in rows}


def get_default_value(column_definition):
    """
    Extract the DEFAULT value from a column definition.

    Returns:
        None if there is no DEFAULT.
        Otherwise returns the default expression as text.
    """
    upper = column_definition.upper()

    if " DEFAULT " not in upper:
        return None

    index = upper.index(" DEFAULT ")
    default_part = column_definition[index + len(" DEFAULT "):].strip()

    return default_part


def is_not_null(column_definition):
    return "NOT NULL" in column_definition.upper()


def create_table(conn, table_name):
    schema = SCHEMA[table_name]

    column_definitions = []

    for column_name, definition in schema["columns"].items():
        column_definitions.append(
            f"{quote_identifier(column_name)} {definition}"
        )

    column_definitions.extend(
        FOREIGN_KEYS.get(table_name, [])
    )

    sql = f"""
    CREATE TABLE IF NOT EXISTS {quote_identifier(table_name)} (
        {", ".join(column_definitions)}
    )
    """

    conn.execute(sql)


def get_item_identifier(row, table_name):
    """
    Get a useful identifier for the prompt.

    For tables with an 'id' column, use it.
    Otherwise use the first available column.
    """
    if "id" in row.keys():
        return row["id"]

    if row.keys():
        return row[0]

    return "unknown"


def ask_for_value(table_name, column_name, row):
    item_id = get_item_identifier(row, table_name)

    while True:
        value = input(
            f"Element {column_name} NOT NULL for item "
            f"{item_id} in table {table_name}: "
        )

        if value != "":
            return value

        print("This value cannot be empty.")


def migrate_table(conn, table_name):
    schema = SCHEMA[table_name]

    if not table_exists(conn, table_name):
        print(f"[+] Creating table: {table_name}")
        create_table(conn, table_name)
        return

    existing_columns = get_existing_columns(conn, table_name)

    missing_columns = [
        column_name
        for column_name in schema["columns"]
        if column_name not in existing_columns
    ]

    if not missing_columns:
        return

    print(f"\n[*] Updating table: {table_name}")

    for column_name in missing_columns:
        definition = schema["columns"][column_name]
        default_value = get_default_value(definition)
        not_null = is_not_null(definition)

        print(f"[+] Missing column: {column_name}")

        # Normal case:
        # NOT NULL column with a DEFAULT can be added directly.
        if default_value is not None:
            sql = f"""
            ALTER TABLE {quote_identifier(table_name)}
            ADD COLUMN {quote_identifier(column_name)} {definition}
            """

            conn.execute(sql)

            print(
                f"    Added {column_name} "
                f"with default {default_value}"
            )

        elif not not_null:
            # Nullable column without a default.
            sql = f"""
            ALTER TABLE {quote_identifier(table_name)}
            ADD COLUMN {quote_identifier(column_name)} {definition}
            """

            conn.execute(sql)

            print(f"    Added nullable column {column_name}")

        else:
            # SQLite cannot directly add a NOT NULL column
            # without a DEFAULT value.
            #
            # We temporarily add it as nullable, ask for values,
            # and fill every existing row.
            temporary_definition = definition.replace(
                " NOT NULL", ""
            )

            sql = f"""
            ALTER TABLE {quote_identifier(table_name)}
            ADD COLUMN {quote_identifier(column_name)}
            {temporary_definition}
            """

            conn.execute(sql)

            rows = conn.execute(
                f"SELECT rowid, * FROM {quote_identifier(table_name)}"
            ).fetchall()

            for row in rows:
                value = ask_for_value(
                    table_name,
                    column_name,
                    row
                )

                conn.execute(
                    f"""
                    UPDATE {quote_identifier(table_name)}
                    SET {quote_identifier(column_name)} = ?
                    WHERE rowid = ?
                    """,
                    (value, row["rowid"])
                )

            print(
                f"    Added {column_name} and filled existing rows."
            )

            print(
                "    Note: SQLite cannot add NOT NULL without a "
                "DEFAULT using ALTER TABLE, so the new column is "
                "currently nullable."
            )


def init_database():
    conn = get_db_connection()

    try:
        # Foreign keys are temporarily disabled during migration.
        conn.execute("PRAGMA foreign_keys = OFF")

        # Create missing tables and update existing ones.
        for table_name in SCHEMA:
            migrate_table(conn, table_name)

        conn.commit()

        print("\nDatabase migration completed successfully.")

    except Exception:
        conn.rollback()
        print("\nDatabase migration failed.")
        raise

    finally:
        conn.execute("PRAGMA foreign_keys = ON")
        conn.close()


if __name__ == "__main__":
    init_database()