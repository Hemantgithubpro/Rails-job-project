# Mini E-Commerce API

This repository is a learning-focused e-commerce backend built with Ruby on Rails and PostgreSQL. The product domain is intentionally small; the engineering implementation should be realistic enough to teach Rails fundamentals, API design, intermediate Rails patterns, testing, and production-minded engineering.

## Instructions for the implementing AI agent

Treat `docs/01-project-spec.md` as the functional source of truth. Read the remaining documents before making architectural decisions. Keep names, statuses, response shapes, and business rules consistent across the code and documentation. Do not add unrelated marketplace features, a frontend, shipping, coupons, reviews, or real payment-provider integration unless explicitly requested later.

Prefer boring, idiomatic Rails code. Introduce a service object when a use case crosses model boundaries or needs a transaction; do not create abstractions only for theoretical reuse. Every behavior added to the application must have a test and, where useful, a documentation update.

## Scope

The API supports:

- customer registration and token authentication;
- product browsing and admin product CRUD;
- one active cart per user and cart-item management;
- checkout that creates an order from the cart;
- simulated payments with deterministic success/failure behavior;
- order history and order details.

The core domain is:

```text
User 1──1 Cart 1──* CartItem *──1 Product
User 1──* Order 1──* OrderItem *──1 Product
Order 1──1 Payment
```

## Suggested baseline

- Ruby 3.3+ (use the version available in the environment if newer).
- Rails 7.1+ or the current stable Rails version available when implementation begins.
- PostgreSQL.
- JSON-only Rails API application.
- RSpec, FactoryBot, Faker, and shoulda-matchers where appropriate.
- Standard Rails authentication primitives; use a small bearer-token implementation unless the implementation environment already mandates a different library.

## Documentation map

- [Project specification](docs/01-project-spec.md): behavior, actors, requirements, and acceptance criteria.
- [Domain and database](docs/02-domain-and-database.md): entities, relationships, fields, constraints, and lifecycle rules.
- [API specification](docs/03-api-spec.md): routes, authentication, request/response contracts, and errors.
- [Rails architecture](docs/04-rails-architecture.md): application boundaries, services, policies, and conventions.
- [Testing strategy](docs/05-testing-strategy.md): RSpec layers, factories, examples, and coverage expectations.
- [Engineering practices](docs/06-engineering.md): quality, security, transactions, observability, and performance.
- [Development roadmap](docs/07-development-roadmap.md): implementation phases and definition of done.

## Definition of done

The project is complete when the documented API works against PostgreSQL, authentication and authorization are enforced, checkout is transactional and idempotent for a request, simulated payment outcomes are covered, the full RSpec suite passes, database constraints protect core invariants, and the README explains setup and verification commands.

## Setup (Docker-only, Phase 0)

This project runs exclusively through Docker Compose. Do not install Ruby, Rails, Bundler, PostgreSQL, or Node on the host. The Rails container reaches PostgreSQL via the Compose service name `db`, never `localhost`.

Prerequisites: Docker Engine + `docker compose` (Docker Desktop includes both).

```bash
# 1. Copy environment template (never commit real secrets)
cp .env.example .env

# 2. Build images
docker compose build

# 3. Start PostgreSQL and wait for it to become healthy
docker compose up -d db

# 4. Create/migrate databases
docker compose run --rm web bin/rails db:prepare

# 5. Seed (safe placeholder seeds in Phase 0; real admin/products arrive in later phases)
docker compose run --rm web bin/rails db:seed

# 6. Start the API
docker compose up

# 7. In another terminal: run tests, routes, logs
docker compose exec web bundle exec rspec
docker compose exec web bin/rails routes
docker compose logs web
```

Useful equivalents while the stack is down or `web` is not running:

```bash
docker compose run --rm web bundle exec rspec
docker compose run --rm web bin/rails db:prepare
docker compose run --rm web bin/rails db:migrate
```

Notes:

- Health checks: `db` uses `pg_isready`; `web` uses `GET /up` (`rails/health#show`).
- Data persists in the `pgdata` Docker volume; gems persist in `bundle_data`.
- Current status (Phase 0): Rails 8.1 API-only app boots, connects to PostgreSQL, and the (empty) RSpec suite passes. No users, products, carts, orders, or payments are implemented yet.
- Baseline gems: `rspec-rails`, `factory_bot_rails`, `faker`, `shoulda-matchers` (testing strategy), `bcrypt` (Phase 1 `has_secure_password`), `rubocop-rails-omakase` + `brakeman` + `bundler-audit` (lint/security baseline from the Rails generator).
