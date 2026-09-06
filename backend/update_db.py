import sqlite3

from database import (
    SCHEMA,
    FOREIGN_KEYS,
    get_db_connection,
    quote_identifier,
    table_exists,
)


def get_existing_columns(conn, table_name):
    rows = conn.execute(
        f"PRAGMA table_info({quote_identifier(table_name)})"
    ).fetchall()

    return {
        row["name"]
        for row in rows
    }


def get_default_value(column_definition):
    parts = column_definition.upper().split()

    if "DEFAULT" not in parts:
        return None

    index = parts.index("DEFAULT")

    if index + 1 >= len(parts):
        return None

    value = column_definition.split()[index + 1]

    return value


def add_missing_columns(conn, table_name):
    existing_columns = get_existing_columns(
        conn,
        table_name
    )

    definition = SCHEMA[table_name]

    for column_name, column_definition in definition["columns"].items():

        if column_name in existing_columns:
            continue

        # SQLite permet d'ajouter une colonne avec DEFAULT.
        # Pour une colonne nullable, aucun DEFAULT n'est nécessaire.
        sql = f"""
            ALTER TABLE {quote_identifier(table_name)}
            ADD COLUMN {quote_identifier(column_name)}
            {column_definition}
        """

        try:
            conn.execute(sql)

        except sqlite3.OperationalError as e:
            # Certaines définitions comme PRIMARY KEY /
            # AUTOINCREMENT ne peuvent pas être ajoutées
            # à une table existante.
            if "PRIMARY KEY" in column_definition.upper():
                raise RuntimeError(
                    f"Cannot add primary key column "
                    f"{table_name}.{column_name}: {e}"
                ) from e

            raise


def create_missing_tables(conn):
    # Ordre des dépendances.
    for table_name in (
        "users",
        "shops",
        "catalog",
        "orders",
        "order_items",
    ):
        if not table_exists(conn, table_name):
            create_table(conn, table_name)


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


def migrate_catalog_shops(conn):
    """
    Ancienne DB :
        catalog n'avait pas forcément shop_id.

    Si shop_id vient d'être ajouté, on essaye d'associer
    les anciens produits au shop du premier vendeur.
    """

    columns = get_existing_columns(conn, "catalog")

    if "shop_id" not in columns:
        return

    # S'il existe déjà des associations, on ne touche à rien.
    unassigned = conn.execute(
        """
        SELECT COUNT(*)
        FROM catalog
        WHERE shop_id IS NULL
        """
    ).fetchone()[0]

    if unassigned == 0:
        return

    # Cherche d'abord un vendeur.
    user = conn.execute(
        """
        SELECT id
        FROM users
        WHERE is_vendor = 1
        ORDER BY id
        LIMIT 1
        """
    ).fetchone()

    # Sinon, prend le premier utilisateur.
    if user is None:
        user = conn.execute(
            """
            SELECT id
            FROM users
            ORDER BY id
            LIMIT 1
            """
        ).fetchone()

    if user is None:
        return

    user_id = user["id"]

    # Cherche son shop.
    shop = conn.execute(
        """
        SELECT id
        FROM shops
        WHERE user_id = ?
        ORDER BY id
        LIMIT 1
        """,
        (user_id,)
    ).fetchone()

    if shop is None:
        # Génère un nom unique.
        base_name = "Migrated Shop"
        name = base_name
        number = 2

        while conn.execute(
            """
            SELECT 1
            FROM shops
            WHERE name = ?
            """,
            (name,)
        ).fetchone() is not None:
            name = f"{base_name} {number}"
            number += 1

        cursor = conn.execute(
            """
            INSERT INTO shops
            (user_id, name)
            VALUES (?, ?)
            """,
            (user_id, name)
        )

        shop_id = cursor.lastrowid

    else:
        shop_id = shop["id"]

    # Associe les anciens produits au shop.
    conn.execute(
        """
        UPDATE catalog
        SET shop_id = ?
        WHERE shop_id IS NULL
        """,
        (shop_id,)
    )


def migrate():
    conn = get_db_connection()

    try:
        # 1. Création des tables qui n'existent pas.
        create_missing_tables(conn)

        # 2. Ajout des colonnes manquantes.
        for table_name in SCHEMA:
            add_missing_columns(
                conn,
                table_name
            )

        # 3. Migration spéciale pour les anciens catalogues.
        migrate_catalog_shops(conn)

        conn.commit()

    except Exception:
        conn.rollback()
        raise

    finally:
        conn.close()


if __name__ == "__main__":
    migrate()
    print("Database migration completed.")