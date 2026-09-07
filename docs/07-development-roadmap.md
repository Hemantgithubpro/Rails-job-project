# 07 — Development Roadmap

Implement in small, verifiable phases. Do not start a later phase while an earlier phase has failing tests or unresolved contract decisions.

## Phase 0 — Bootstrap

Create the Rails API application, PostgreSQL configuration, environment template, RSpec setup, FactoryBot support, lint/security baseline, and README setup instructions.

Done when a fresh checkout can create the database and run an empty passing test suite.

## Phase 1 — Users and authentication

Create users, password hashing, roles, registration, login, bearer-token authentication, current-user resolution, and request helpers.

Done when valid users can register/login and protected endpoints reject missing/invalid tokens with the documented shape.

## Phase 2 — Products and admin authorization

Create product migration/model, validations, constraints, public index/show, admin CRUD, pagination, and active filtering.

Done when public customers see active products and only admins can mutate product data.

## Phase 3 — Cart

Create cart/cart-item models, one-cart-per-user constraint, cart endpoints, quantity validation, active-product checks, and ownership enforcement.

Done when a customer can maintain a cart and the API returns correct integer-cent totals without N+1 queries.

## Phase 4 — Checkout and orders

Implement order/order-item models and the checkout service. Add product row locks, stock checks, historical snapshots, transaction rollback, order listing/detail, and cart clearing after success.

Done when successful and failing checkout scenarios meet every acceptance criterion and all service/request specs pass.

## Phase 5 — Simulated payments

Implement payment model, deterministic simulator, status transitions, safe transaction references, and payment fields in order responses. Add failure-path tests.

Done when success and failure are reproducible in tests and no sensitive payment data is accepted or stored.

## Phase 6 — Hardening

Add idempotency keys, rate-limiting consideration, structured error handling, request IDs, query review, database constraints, and security/lint checks. Add API documentation examples if the contract changed.

Done when repeated requests, invalid inputs, and concurrent stock-sensitive operations are handled predictably.

## Phase 7 — Intermediate Rails extensions

Add an after-commit order confirmation mailer/job, narrowly scoped caching for a read path if justified, and basic instrumentation. Keep these extensions optional to the core checkout path.

Done when background work is tested, enqueued after commit, observable, and cannot corrupt order state if it fails.

## Phase 8 — Final verification

Run setup from a clean database, seed data, full RSpec suite, lint/security checks, and a manual API smoke flow. Review the implementation against all seven planning documents and remove accidental scope creep.

Final deliverable: a documented Rails API whose behavior, schema, tests, and engineering practices agree with one another.
