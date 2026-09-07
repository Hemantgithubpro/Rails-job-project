# 05 — Testing Strategy with RSpec

Testing is part of implementation, not a final cleanup phase. Every public behavior and important failure path must be executable in an automated test.

## Test stack

Use RSpec Rails with FactoryBot and Faker. Add shoulda-matchers only where it improves clarity; do not replace meaningful behavior tests with matcher-only coverage. Configure database cleaning through transactional fixtures or an equivalent safe strategy.

## Test layers

### Model specs

Cover associations, presence/format validations, numericality, uniqueness, role/status constraints, scopes, and money/quantity edge cases. Verify that database-backed uniqueness and check constraints are also exercised where practical.

### Request specs

Treat request specs as the API contract. Test route, authentication, authorization, response status, JSON shape, filtering/pagination, and error envelope. Include happy paths and malformed/unauthorized requests.

### Service specs

Test `CheckoutService` and cart operations in isolation from HTTP. Verify totals, snapshots, stock decrement, payment outcomes, cart clearing, rollback behavior, row-lock assumptions, and idempotent retries where implemented.

### Policy/authorization specs

Test customer versus admin permissions and ownership boundaries. Explicitly prove that a customer cannot read or mutate another user's cart/order.

### Job/mailers specs

If background jobs or mailers are introduced, verify enqueue timing and payloads without making external network calls.

## Minimum scenarios

- Register with valid data; reject duplicate and malformed email.
- Login succeeds and invalid credentials fail without revealing which field was wrong.
- Public product listing excludes inactive products.
- Admin can create/update/deactivate a product; customer cannot.
- Add, update, and remove cart items.
- Reject inactive products, zero quantities, and quantities over stock.
- Checkout calculates the exact integer-cent total.
- Order items retain product name and price after product changes.
- Successful payment marks order paid, decrements stock, and clears the cart.
- Failed payment rolls back order, payment, stock, and cart changes.
- Empty cart and insufficient stock return documented errors.
- Two checkout attempts with the same idempotency key do not create duplicate orders.
- Users cannot access another user's resources.
- Missing records return the intended `404` shape.

## Factories and test data

Factories should create valid records by default and use traits for `:admin`, `:inactive`, `:out_of_stock`, and payment outcomes. Avoid excessive global setup. Freeze or control time only when testing timestamps or token expiry.

## Quality gates

The agent must run the full suite, not only the newly written spec. Add linting and security checks if included in the selected Rails baseline. A phase is complete only when tests pass and the behavior has been checked against the API contract.
