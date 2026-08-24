# FinnishServices
Finnish computer craft apps

## API documentation

The backend exposes the REST API on the Flask app running from the `backend` folder.

Base URL:
- `http://<host>:<port>`
- Default configured port: `9142`

Authentication:
- Most routes require an `Authorization: Bearer <token>` header.
- The token is returned by `/api/register` and `/api/login`.

### User endpoints

#### POST /api/register
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
  "is_vendor": true,
  "is_admin": false
}
```

Possible errors:
- `400` missing variables
- `400` invalid password hash
- `400` user already exists

#### POST /api/login
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
  "is_vendor": true,
  "is_admin": false
}
```

Possible errors:
- `400` missing variables
- `400` username or password is invalid

#### GET /api/user_info
Returns the authenticated user info.

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
  "is_vendor": true,
  "is_admin": false
}
```

Possible errors:
- `401` unauthorized
- `404` user not found

#### POST /api/user_info
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
  "is_vendor": true,
  "is_admin": false
}
```

Possible errors:
- `400` missing/empty values
- `400` user already exists
- `400` no valid fields to update
- `401` unauthorized

### Catalog endpoints

#### GET /api/catalog
Returns all catalog items.

Headers:
```http
Authorization: Bearer <token>
```

Success response `200`:
```json
{
  "catalog": [
    {
      "id": "item-1",
      "name": "Example item",
      "description": "Example description",
      "price": 150,
      "stock": 20,
      "pack": 5,
      "locked": false
    }
  ]
}
```

Optional format:
- `?format=lua`
- or header `X-Format: lua`

#### POST /api/catalog
Adds a new catalog item. Only the special token is allowed.

Headers:
```http
Authorization: Bearer <special-token>
```

Request body:
```json
{
  "name": "Example item",
  "description": "Example description"
  "price": 150,
  "stock": 20,
  "pack": 5,
  "locked": false
}
```

Success response `201`:
```json
{
  "success": true,
  "item": {
    "id": "<generated-or-provided id>",
    "description": "Example description",
    "name": "Example item",
    "price": 150,
    "stock": 20,
    "pack": 5,
    "locked": false
  }
}
```

Possible errors:
- `403` unauthorized
- `400` invalid JSON or missing fields
- `500` database error

### Orders endpoints

#### POST /api/order
Creates a new order for the authenticated user.

Headers:
```http
Authorization: Bearer <token>
```

Request body:
```json
{
  "items": [
    { "id": "item-1", "qty": 2 },
    { "id": "item-2", "qty": 1 }
  ],
  "notes": "Optional order notes"
}
```

Success response `200`:
```json
{
  "ok": true,
  "order_id": 1,
  "total": 350
}
```

Possible errors:
- `400` invalid order or quantity
- `402` insufficient funds
- `404` item not found
- `409` not enough stock
- `401` unauthorized

#### GET /api/orders
Returns the authenticated user's order history.

Headers:
```http
Authorization: Bearer <token>
```

Success response `200`:
```json
{
  "orders": [
    {
      "id": 1,
      "total": 350,
      "notes": "Optional order notes",
      "created_at": "2026-08-14 12:00:00"
    }
  ]
}
```

Possible errors:
- `401` unauthorized

## Notes

- Passwords are expected to be SHA-256 hex strings in the API.
- The app uses SQLite and database initialization happens in the backend bootstrap.
