# syntax=docker/dockerfile:1
# Development/test image for the Mini E-Commerce API (Phase 0).
# Production hardening (multi-stage, non-root, thruster) is out of scope
# until a later roadmap phase; this image prioritizes fast bundle + rails
# workflows inside Docker Compose.
ARG RUBY_VERSION=3.3.12
FROM docker.io/library/ruby:$RUBY_VERSION-slim

WORKDIR /app

# System dependencies: build tools + PostgreSQL client for pg gem and healthchecks.
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential git curl libpq-dev libyaml-dev pkg-config postgresql-client && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_JOBS="4" \
    BUNDLE_RETRY="3"

# Install gems first for better layer caching. Gemfile.lock may not exist on
# first bootstrap, so the wildcard matches Gemfile with or without the lock.
COPY Gemfile* ./
COPY .ruby-version ./
RUN bundle install

# Copy the rest of the application.
COPY . .

# Ensure Rails bins are executable (preserved across Windows checkouts).
RUN chmod +x bin/*

ENTRYPOINT ["/app/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["./bin/rails", "server", "-b", "0.0.0.0"]
