from database import get_db_connection


CATALOG = [
    {
        "id": "minecraft:dirt",
        "name": "Dirt",
        "price": 25,
        "stock": 10
    },
    {
        "id": "minecraft:redstone",
        "name": "Redstone",
        "price": 8,
        "stock": 100
    },
    {
        "id": "create:package_frogport",
        "name": "Package Frogport",
        "price": 12,
        "stock": 50
    }
]


def populate():
    conn = get_db_connection()

    for item in CATALOG:
        conn.execute(
            """
            INSERT OR REPLACE INTO catalog
            (id, name, price, stock)
            VALUES (?, ?, ?, ?)
            """,
            (
                item["id"],
                item["name"],
                item["price"],
                item["stock"]
            )
        )

    conn.commit()
    conn.close()


if __name__ == "__main__":
    populate()