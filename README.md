# FinnishServices

Finnish ComputerCraft apps

## API documentation

The backend exposes the REST API on the Flask app running from the `backend` folder.

Base URL:

- `http://<host>:<port>`
- Default configured port: `9142`

## Authentication

Most authenticated routes require an `Authorization: Bearer <token>` header.

The token is returned by `/api/register` and `/api/login`.

Admin-only routes additionally require the authenticated user's `is_admin` value to be `true`.

---

## User endpoints

### POST `/api/register`

Creates a new user.

Request body:

```json
{
  "username": "alice",
  "password": "<64-char sha256 hash>",
  "home_address": "Some street 1",
  "use_public_frogports": false
}
```

Success response `200`:

```json
{
  "username": "alice",
  "homeaddress": "Some street 1",
  "use_public_frogports": false,
  "balance": 0,
  "token": "<token>",
  "is_vendor": false,
  "is_admin": false
}
```

Possible errors:

- `400` missing variables
- `400` invalid password hash
- `400` user already exists

---

### POST `/api/login`

Logs in a user.

Request body:

```json
{
  "username": "alice",
  "password": "<64-char sha256 hash>"
}
```

Success response `200`:

```json
{
  "username": "alice",
  "homeaddress": "Some street 1",
  "use_public_frogports": false,
  "balance": 0,
  "token": "<token>",
  "is_vendor": false,
  "is_admin": false
}
```

Possible errors:

- `400` missing variables
- `400` username or password is invalid

---

### GET `/api/user_info`

Returns the authenticated user's information.

Headers:

```http
Authorization: Bearer <token>
```

Success response `200`:

```json
{
  "username": "alice",
  "homeaddress": "Some street 1",
  "use_public_frogports": false,
  "balance": 0,
  "token": "<token>",
  "is_vendor": false,
  "is_admin": false
}
```

Possible errors:

- `401` unauthorized
- `404` user not found

---

### POST `/api/user_info`

Partially updates the authenticated user.

Headers:

```http
X-USER-CHANGE: True
Authorization: Bearer <token>
```

Request body example:

```json
{
  "username": "alice2",
  "homeaddress": "New address 42",
  "use_public_frogports": true
}
```

Accepted fields:

- `username`
- `homeaddress`
- `home_address`
- `use_public_frogports`

Behavior:

- `username` must be non-empty and unique
- `homeaddress` / `home_address` must be non-empty
- `use_public_frogports` is converted to `0` or `1`

Success response `200`:

```json
{
  "username": "alice2",
  "homeaddress": "New address 42",
  "use_public_frogports": true,
  "balance": 0,
  "token": "<token>",
  "is_vendor": false,
  "is_admin": false
}
```

Possible errors:

- `400` missing/empty values
- `400` user already exists
- `400` no valid fields to update
- `401` unauthorized

---

# Shops

Shops are owned by users.

Each shop contains:

- `id` — unique shop ID
- `user_id` — ID of the user who owns the shop
- `name` — unique shop name

Database relationship:

```text
users.id
    |
    v
shops.user_id

shops.id
    |
    v
catalog.shop_id
```

A shop can contain multiple catalog items.

Example:

```json
{
  "id": 12,
  "user_id": 5,
  "name": "Bob's Shop"
}
```

---

# Catalog endpoints

### GET `/api/catalog`

Returns all catalog items.

Requires a valid authenticated user token. Admin privileges are not required.

Headers:

```http
Authorization: Bearer <token>
```

Success response `200`:

```json
{
  "catalog": [
    {
      "id": "minecraft:cobblestone",
      "shop_id": 12,
      "name": "Cobblestone",
      "description": "A block of cobblestone",
      "price": 100,
      "stock": 640,
      "pack": 64,
      "locked": false
    }
  ]
}
```

Fields:

- `id` — item identifier
- `shop_id` — ID of the shop selling the item
- `name` — display name
- `description` — item description
- `price` — price of one pack
- `stock` — available stock in raw items
- `pack` — number of raw items in one pack
- `locked` — whether the item is locked

Optional format:

- `?format=lua`
- Header `X-Format: lua`
- Header `Catalog: catalog`

When Lua format is requested, the response is returned as plain text.

Possible errors:

- `401` unauthorized

---

### POST `/api/change_catalog`

Adds a new catalog item.

Requires a valid authenticated user token with admin privileges (`is_admin = 1`).

Headers:

```http
Authorization: Bearer <admin-token>
```

Request body:

```json
{
  "id": "minecraft:cobblestone",
  "shop_id": 12,
  "name": "Cobblestone",
  "description": "A block of cobblestone",
  "price": 100,
  "stock": 640,
  "pack": 64,
  "locked": false
}
```

Fields:

- `id` — unique item ID
- `shop_id` — shop that owns the item
- `name` — item name
- `description` — item description
- `price` — price per pack
- `stock` — available stock in raw items
- `pack` — amount of raw items per pack
- `locked` — whether the item is locked

Success response `201`:

```json
{
  "success": true,
  "item": {
    "id": "minecraft:cobblestone",
    "shop_id": 12,
    "description": "A block of cobblestone",
    "name": "Cobblestone",
    "price": 100,
    "stock": 640,
    "pack": 64,
    "locked": false
  }
}
```

Possible errors:

- `401` unauthorized
- `400` invalid JSON or missing fields
- `404` shop not found
- `500` database error

---

# Orders endpoints

## POST `/api/order`

Creates a new order for the authenticated user.

Headers:

```http
Authorization: Bearer <token>
```

Request body:

```json
{
  "items": [
    {
      "id": "minecraft:cobblestone",
      "qty": 64
    },
    {
      "id": "minecraft:dirt",
      "qty": 32
    }
  ],
  "notes": "Optional order notes"
}
```

`qty` represents the raw number of items requested, not the number of packs.

For example, if:

```text
pack = 64
```

then:

```json
{
  "id": "minecraft:cobblestone",
  "qty": 64
}
```

means 64 cobblestone, which corresponds to 1 pack.

The backend handles the pack calculation when determining the price.

The stock is measured in raw items. Therefore, an order for `64` items removes `64` items from the catalog stock.

Success response `200`:

```json
{
  "ok": true,
  "order_id": 1,
  "total": 100
}
```

Possible errors:

- `400` invalid order or quantity
- `401` unauthorized
- `402` insufficient funds
- `404` item not found
- `409` not enough stock
- `500` database error

---

## GET `/api/orders`

Returns the authenticated user's order history.

Headers:

```http
Authorization: Bearer <token>
```

Success response `200`:

```json
[
  {
    "id": 1,
    "address": "testCustomer",
    "items": [
      {
        "shopID": 12,
        "itemID": "minecraft:cobblestone",
        "qty": 64
      },
      {
        "shopID": 15,
        "itemID": "minecraft:dirt",
        "qty": 32
      }
    ]
  }
]
```

### Order fields

| Field | Description |
|---|---|
| `id` | Order ID |
| `address` | Customer's `home_address` |
| `items` | Items contained in the order |

### Order item fields

| Field | Description |
|---|---|
| `shopID` | ID of the shop selling the item |
| `itemID` | Catalog item ID |
| `qty` | Raw quantity to send |

`qty` is not the number of packs.

For example:

```json
{
  "shopID": 12,
  "itemID": "minecraft:cobblestone",
  "qty": 128
}
```

means:

```text
128 cobblestone
```

If the catalog pack size is `64`, this corresponds to 2 packs.

Possible errors:

- `401` unauthorized
- `500` database error

---

# Database structure

The database uses SQLite.

## users

```text
id
username
password
home_address
public_frogports
balance
token
is_vendor
is_admin
```

## shops

```text
id
user_id
name
```

Relationships:

- `shops.user_id` references `users.id`
- A user can own one or more shops
- `shops.name` must be unique

## catalog

```text
id
shop_id
name
description
price
stock
pack
locked
```

Relationships:

- `catalog.shop_id` references `shops.id`
- Each catalog item belongs to a shop

## orders

```text
id
user_id
total
notes
created_at
delivered
```

Relationships:

- `orders.user_id` references `users.id`

## order_items

```text
id
order_id
item_id
quantity
price
```

Relationships:

- `order_items.order_id` references `orders.id`
- `order_items.item_id` references `catalog.id`

Overall structure:

```text
users
  |
  +-- shops
  |     |
  |     +-- catalog
  |
  +-- orders
        |
        +-- order_items
```

---

# Notes

- Passwords are expected to be SHA-256 hex strings in the API.
- Authentication uses Bearer tokens returned by `/api/register` and `/api/login`.
- `/api/catalog` requires authentication but does not require admin privileges.
- `/api/change_catalog` requires authentication and admin privileges.
- Each catalog item belongs to a shop through `catalog.shop_id`.
- Each shop belongs to a user through `shops.user_id`.
- `catalog.price` represents the price of one pack.
- `catalog.pack` represents the number of raw items contained in one pack.
- `catalog.stock` represents the number of raw items currently available.
- Order `qty` values represent raw item quantities, not pack counts.
- `/api/orders` returns `shopID`, `itemID`, and raw `qty` for each ordered item.
- The app uses SQLite.
- Database initialization and migrations happen during backend bootstrap.