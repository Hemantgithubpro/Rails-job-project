# 03 — API Contract

The API is JSON-only and versioned under `/api/v1`. Use plural resource names, standard HTTP methods, and consistent response envelopes. Dates should be ISO 8601 UTC strings and money should be represented as integer cents plus a human-readable value only if useful.

## Authentication

`POST /api/v1/auth/register` creates a customer and returns `201` with a user representation and bearer token.

`POST /api/v1/auth/login` accepts `{ "email": "user@example.com", "password": "..." }` and returns `200` with a token and user. Invalid credentials return `401` with `{ "error": { "code": "invalid_credentials", "message": "Invalid email or password" } }`.

Send protected requests with `Authorization: Bearer <token>`. The token implementation may be signed stateless tokens or persisted tokens, but it must support expiry and revocation strategy appropriate to the chosen design. Do not put passwords or sensitive data in a token.

## Products

`GET /api/v1/products` is public. Support pagination with `page` and `per_page`, filtering by `active` where authorized, and stable sorting such as `created_at` or `price_cents`. Public results include active products only.

`GET /api/v1/products/:id` is public for active products.

`POST /api/v1/products` requires an admin. Example request:

```json
{"name":"Notebook","description":"A5 notebook","price_cents":1299,"stock_quantity":25,"active":true}
```

`PATCH /api/v1/products/:id` and `DELETE /api/v1/products/:id` require an admin. Prefer deactivation when deletion would violate order history.

Product response:

```json
{"id":1,"name":"Notebook","description":"A5 notebook","price_cents":1299,"stock_quantity":25,"active":true}
```

## Cart

All cart routes require authentication and address the current user's cart:

- `GET /api/v1/cart`
- `POST /api/v1/cart/items` with `{ "product_id": 1, "quantity": 2 }`
- `PATCH /api/v1/cart/items/:id` with `{ "quantity": 3 }`
- `DELETE /api/v1/cart/items/:id`

Adding an existing product should update/increment according to the documented implementation choice; choose one behavior and test it. A cart response includes item product snapshots for display, quantities, `subtotal_cents`, and `total_cents`.

## Checkout and orders

`POST /api/v1/checkout` requires authentication. It accepts an optional idempotency key header, `Idempotency-Key`. The service validates the cart, locks products, creates order items and payment, applies the deterministic simulator, and clears the cart only after success.

Success: `201` with order and payment details.

Failure due to validation or stock: `422` with a stable domain error. Authentication failures remain `401`; authorization failures remain `403`.

`GET /api/v1/orders` returns only the current user's orders, newest first.

`GET /api/v1/orders/:id` returns one order owned by the current user. Include order items, total, status, payment status, and timestamps. Never expose another user's order through an ID lookup.

## Error contract

Use this shape for expected errors:

```json
{
  "error": {
    "code": "out_of_stock",
    "message": "Notebook does not have enough stock",
    "details": {"product_id": 1, "available": 1}
  }
}
```

`details` is optional. Validation errors may use `code: validation_failed` and a field map. Do not leak stack traces, SQL, or internal exception messages in production responses.

## HTTP status guidance

- `200` successful reads/updates
- `201` successful creation
- `204` successful deletion with no body
- `400` malformed request
- `401` missing/invalid authentication
- `403` authenticated but forbidden
- `404` missing or intentionally undiscoverable resource
- `409` conflict/idempotency collision where appropriate
- `422` valid JSON that violates business or validation rules
