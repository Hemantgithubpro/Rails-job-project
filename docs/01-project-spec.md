# 01 — Project Specification

## Purpose

Build a small but production-shaped e-commerce JSON API. The application is primarily a Rails learning project: the domain should remain understandable while the implementation demonstrates MVC, Active Record, REST, authentication, authorization, transactions, service objects, background jobs, mailers, caching, query discipline, and automated tests.

## Product definition

A customer can create an account, browse available products, maintain a cart, check out, and inspect past orders. An administrator can manage products and stock. Payments are simulated; no external gateway, real card data, or financial settlement is required.

## Actors and permissions

### Customer

- Register and authenticate.
- Read active products.
- Create, inspect, update, and delete their own cart items.
- Check out their own non-empty cart.
- Read their own orders and payment status.
- Never access another user's cart, order, or payment.

### Administrator

- Do everything a customer can do.
- Create, update, and delete products.
- Set product price, stock, active status, and description.
- May inspect all orders if an admin order endpoint is implemented in a later phase.

Do not expose admin operations merely because a user is authenticated. Authorization must check the role.

## Functional requirements

1. A user has a unique normalized email and a securely stored password.
2. Products have a positive price, non-negative stock, and an active/inactive state.
3. Only active products are returned by the public product index/show endpoints.
4. Each user has at most one active cart.
5. A cart item references one product and has a positive quantity. Adding the same product twice updates or increments the existing item rather than creating an invalid duplicate.
6. A cart cannot add an inactive product or a quantity greater than current stock.
7. Checkout refuses an empty cart and rechecks product availability inside a database transaction.
8. Checkout snapshots product name and unit price into order items. Later product edits must not alter historical orders.
9. The order total is calculated from immutable order-item snapshots, not from current product records.
10. A simulated payment is created for each order. The result is deterministic and documented; no raw payment credentials are stored.
11. Successful checkout clears the cart and creates exactly one order for the checkout operation.
12. A failed checkout rolls back order, payment, stock, and cart mutations.
13. Customers can see only their own orders. Orders are returned newest first.
14. API errors use an appropriate 4xx status and a stable JSON error shape.

## Explicit non-goals

Do not implement product variants, images, search infrastructure, promotions, tax calculation, shipping, refunds, real payment providers, guest carts, multi-currency, inventory reservations, or a frontend in the initial project.

## Business rules and status model

Use these initial statuses:

- `Order`: `pending`, `paid`, `payment_failed`, `cancelled`.
- `Payment`: `pending`, `succeeded`, `failed`.

Checkout creates a pending order, runs the simulator, then marks the order paid or payment_failed. A failed payment does not reduce stock or clear the cart after the transaction rolls back. State transitions should be explicit and tested.

## Acceptance criteria

- A fresh database can be created and seeded with an admin and sample products.
- A complete customer flow works: register → login → list products → add to cart → checkout → list orders.
- An unauthenticated request receives `401` for protected routes.
- A customer attempting admin or another user's data receives `403` or `404` according to the API contract.
- Invalid input is rejected both by model validations and database constraints where possible.
- Concurrent or stale checkout cannot make stock negative.
- `bundle exec rspec` passes, including model, request, service, and authorization coverage.
