# 02 — Domain and Database Architecture

Use PostgreSQL as the source of truth. Prefer database constraints for uniqueness, non-null values, and non-negative quantities in addition to Rails validations.

## Tables and fields

### users

- `id` bigint primary key
- `email` string, normalized, unique, not null
- `password_digest` string, not null
- `role` string, not null, default `customer`, limited to `customer` or `admin`
- timestamps

Use `has_secure_password`. Never store or log a plaintext password.

### products

- `id`
- `name` string, not null
- `description` text, nullable
- `price_cents` integer, not null, greater than zero
- `stock_quantity` integer, not null, greater than or equal to zero
- `active` boolean, not null, default true
- timestamps

Use integer cents, never floating-point money. Add indexes appropriate to public listing, such as `active` and timestamps if needed.

### carts

- `id`
- `user_id` foreign key, not null, unique
- timestamps

The unique user index enforces one cart per user. A cart is reusable after checkout.

### cart_items

- `id`
- `cart_id` foreign key, not null
- `product_id` foreign key, not null
- `quantity` integer, not null, greater than zero
- timestamps

Add a unique composite index on `[cart_id, product_id]` and foreign keys. Deleting a cart should delete its items; deleting a product should be restricted if historical references exist.

### orders

- `id`
- `user_id` foreign key, not null
- `status` string, not null, default `pending`
- `total_cents` integer, not null, greater than or equal to zero
- timestamps

Keep `total_cents` as a persisted snapshot, but calculate it from order items during creation and test that it cannot drift.

### order_items

- `id`
- `order_id` foreign key, not null
- `product_id` foreign key, not null
- `product_name` string, not null
- `unit_price_cents` integer, not null, greater than zero
- `quantity` integer, not null, greater than zero
- timestamps

The product association is useful for reference; `product_name` and `unit_price_cents` are the historical snapshot. Do not rely on a product's current name or price for order display or totals.

### payments

- `id`
- `order_id` foreign key, not null, unique
- `status` string, not null, default `pending`
- `amount_cents` integer, not null, greater than zero
- `transaction_reference` string, nullable, unique when present
- timestamps

Do not add card number, CVV, or other sensitive payment fields. The simulator can generate a safe reference such as an application-generated UUID.

## Associations

```ruby
User       has_one  :cart
User       has_many :orders
Cart       belongs_to :user
Cart       has_many :cart_items, dependent: :destroy
CartItem   belongs_to :cart
CartItem   belongs_to :product
Order      belongs_to :user
Order      has_many :order_items, dependent: :restrict_with_error
Order      has_one :payment, dependent: :restrict_with_error
OrderItem  belongs_to :order
OrderItem  belongs_to :product
Payment    belongs_to :order
```

Choose deletion behavior deliberately: historical orders must remain valid even when a product is no longer active. Soft-deactivation is preferred over deleting products referenced by orders.

## Concurrency and transaction rules

Checkout must run in one transaction and lock the relevant product rows while checking and decrementing stock. Re-read stock after acquiring the lock. If any item is unavailable, raise a domain error and roll back every mutation. Use database-level constraints as a final defense, not as the only user-facing validation.

## Seed data

Seeds should be safe to run repeatedly or clearly documented as destructive. Include one admin, one customer, and several products with varied prices and stock. Never commit real credentials; use development-only documented values or environment variables.
