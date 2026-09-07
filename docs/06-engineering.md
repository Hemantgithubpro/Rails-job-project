# 06 — Engineering Practices

This project is intentionally small, but implementation should model habits expected in a professional Rails backend.

## Correctness and maintainability

- Keep controllers thin and service interfaces explicit.
- Prefer clear names and small methods over clever metaprogramming.
- Use integer cents and database transactions for money and inventory.
- Validate at the model and request boundaries, then enforce critical invariants in PostgreSQL.
- Avoid N+1 queries with `includes`/preloading where response data needs associations.
- Paginate collection endpoints and cap `per_page`.
- Add indexes based on actual lookup patterns and explain why each non-obvious index exists.

## Security

- Hash passwords with the framework-supported secure password mechanism.
- Use constant-time or framework-supported credential checks.
- Redact authorization headers, passwords, tokens, and payment-like data from logs.
- Permit only intended attributes; never pass raw request params to models.
- Use generic authentication errors and avoid resource enumeration where security matters.
- Keep secrets out of source control and document rotation expectations.

## API reliability

- Return stable status codes and error codes.
- Keep response fields intentional; do not serialize every database column by default.
- Make list ordering deterministic.
- Handle repeated checkout requests safely with an idempotency design.
- Use request IDs and structured enough logs to trace failures without leaking data.

## Observability

Log important events such as checkout success/failure, payment simulation result, and unexpected exceptions. Include request ID, user ID when safe, and order ID; never include credentials. In a later phase, add metrics for request latency, checkout failures, and stock conflicts.

## Performance

Start with readable queries and verify query counts in critical request specs or profiling. Preload cart/order associations, constrain pagination, and avoid loading entire tables. Do not add caching until a repeated read path is identified; cache invalidation must be documented and tested.

## Git and delivery

Make focused commits by phase. Keep migrations reversible where practical. Update seeds and documentation when the contract changes. Before declaring completion, run the test suite, lint/security checks selected for the project, and a manual smoke flow against a fresh database.

## Definition of implementation quality

The code is acceptable when another Rails developer can find the route, controller, operation, model, and tests for a behavior; failures are understandable from the API response; core invariants survive concurrent requests; and no undocumented feature or dependency has been added merely to increase complexity.
