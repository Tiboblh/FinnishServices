import sqlite3
from config import DATABASE_PATH


CURRENT_VERSION = 2


def get_db_connection():
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn


def table_exists(conn, table_name):
    return conn.execute(
        """
        SELECT 1
        FROM sqlite_master
        WHERE type = 'table' AND name = ?
        """,
        (table_name,)
    ).fetchone() is not None


def column_exists(conn, table_name, column_name):
    columns = conn.execute(
        f'PRAGMA table_info("{table_name}")'
    ).fetchall()

    return any(column["name"] == column_name for column in columns)


def get_db_version(conn):
    row = conn.execute(
        "PRAGMA user_version"
    ).fetchone()

    return row[0]


def set_db_version(conn, version):
    conn.execute(f"PRAGMA user_version = {version}")


def migration_v2(conn):
    """
    Migration vers la DB v2.

    Ajoute :
        - shops
        - catalog.shop_id
    """

    print("[*] Running migration v2...")

    # ---------------------------------------------------------
    # 1. Create shops table
    # ---------------------------------------------------------

    conn.execute("""
    CREATE TABLE IF NOT EXISTS shops (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL UNIQUE,
        FOREIGN KEY(user_id) REFERENCES users(id)
    )
    """)

    # ---------------------------------------------------------
    # 2. Add shop_id to catalog
    # ---------------------------------------------------------

    if not column_exists(conn, "catalog", "shop_id"):

        print("[+] Adding catalog.shop_id")

        # SQLite ne permet pas facilement d'ajouter directement
        # une colonne NOT NULL sans DEFAULT.
        #
        # On l'ajoute donc temporairement nullable.

        conn.execute("""
        ALTER TABLE catalog
        ADD COLUMN shop_id INTEGER
        """)

    # ---------------------------------------------------------
    # 3. Create a migration shop for old catalog items
    # ---------------------------------------------------------

    # On cherche un utilisateur vendeur.
    vendor = conn.execute("""
        SELECT id
        FROM users
        WHERE is_vendor = 1
        ORDER BY id
        LIMIT 1
    """).fetchone()

    if vendor is None:

        # Si aucun vendeur n'existe, on prend le premier utilisateur.
        vendor = conn.execute("""
            SELECT id
            FROM users
            ORDER BY id
            LIMIT 1
        """).fetchone()

    if vendor is not None:

        shop = conn.execute("""
            SELECT id
            FROM shops
            WHERE user_id = ?
            ORDER BY id
            LIMIT 1
        """, (vendor["id"],)).fetchone()

        if shop is None:

            cursor = conn.execute("""
                INSERT INTO shops (user_id, name)
                VALUES (?, ?)
            """, (
                vendor["id"],
                "Migrated Shop"
            ))

            shop_id = cursor.lastrowid

            print(
                f"[+] Created migration shop #{shop_id}"
            )

        else:
            shop_id = shop["id"]

        # -----------------------------------------------------
        # 4. Associate old catalog items with this shop
        # -----------------------------------------------------

        updated = conn.execute("""
            UPDATE catalog
            SET shop_id = ?
            WHERE shop_id IS NULL
        """, (shop_id,))

        print(
            f"[+] Assigned {updated.rowcount} old catalog items "
            f"to shop #{shop_id}"
        )

    else:
        print(
            "[!] No users exist. Old catalog items will remain "
            "without a shop until a shop is created."
        )

    print("[+] Migration v2 completed.")


def migrate_database():
    conn = get_db_connection()

    try:
        conn.execute("PRAGMA foreign_keys = OFF")

        version = get_db_version(conn)

        print(f"[*] Database version: {version}")
        print(f"[*] Current version: {CURRENT_VERSION}")

        # -----------------------------------------------------
        # v0/v1 -> v2
        # -----------------------------------------------------

        if version < 2:

            migration_v2(conn)

            set_db_version(conn, 2)

            conn.commit()

        elif version == CURRENT_VERSION:

            print("[+] Database already up to date.")

        else:

            raise RuntimeError(
                f"Database version {version} is newer than "
                f"supported version {CURRENT_VERSION}"
            )

    except Exception:
        conn.rollback()
        print("[!] Database migration failed.")
        raise

    finally:
        conn.execute("PRAGMA foreign_keys = ON")
        conn.close()


if __name__ == "__main__":
    migrate_database()