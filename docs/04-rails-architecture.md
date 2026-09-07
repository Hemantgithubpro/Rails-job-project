# 04 — Rails Architecture

## Application shape

Build a JSON-only Rails application with conventional directories:

```text
app/
  controllers/api/v1/
  models/
  services/
  serializers/       # only if a serializer approach is selected
  policies/          # only if policy objects are used
  jobs/
  mailers/
config/
db/
spec/
```

Controllers should authenticate, authorize, parse permitted parameters, call an application operation, and render a response. They should not contain checkout calculations, stock mutation, or multi-model orchestration.

## Recommended boundaries

- `AuthenticationService` or equivalent: verify credentials and issue tokens.
- `CartItems::Add` / `CartItems::Update`: validate product availability and maintain cart invariants.
- `CheckoutService`: own the transaction, row locks, order snapshot creation, payment simulation, stock decrement, and cart clearing.
- `PaymentSimulator`: deterministic success/failure behavior with no external network calls.
- `Orders::Presenter` or serializer: keep response formatting out of models and controllers.

Names may differ if the agent uses an established convention, but each operation should have one clear responsibility and a small public interface.

## Models

Models own associations, basic validations, scopes, and domain predicates. Avoid large callback chains. Do not use callbacks for checkout or payment orchestration. Use enums only if their persistence and API names remain clear; string statuses are acceptable and easier to inspect.

Useful scopes include `Product.active`, `Order.recent`, and `Order.for_user`. Keep scopes composable and avoid hidden ordering that surprises API consumers.

## Authentication and authorization

Use `before_action` only for cross-cutting request concerns. Resolve `current_user` once per request. Centralize bearer-token parsing and return generic authentication errors. Authorization should be explicit for admin product actions and ownership checks for cart/order resources.

## Error handling

Define application-specific exceptions for expected domain failures such as `OutOfStockError`, `EmptyCartError`, and `PaymentFailedError`. Map them in an API base controller to the documented JSON error contract. Let unexpected errors reach error monitoring and return a generic `500` response in production.

## Transactions and idempotency

`CheckoutService` must use `ActiveRecord::Base.transaction`. Lock product rows before checking stock. If idempotency is implemented, persist the key and resulting order for a user, enforce uniqueness, and return the original result on retry. Do not claim idempotency based only on an in-memory variable.

## Background work and mailers

Keep the initial checkout response synchronous because payment is simulated. Add a small background job or mailer in a later roadmap phase for order confirmation; it must be enqueued after commit and must not be required for transaction correctness.

## Configuration

Use environment variables for secrets and deployment-specific settings. Provide `.env.example` only for non-secret names. Keep development defaults documented and test configuration deterministic. Do not commit credentials, generated database dumps, or logs.
