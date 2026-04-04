# Magicain System Architecture

This repository describes the cross-repo architecture for the Magicain platform.

## Main Repos

- `magicain-nginx`: top-level gateway, docker-compose orchestration, monitoring, and system docs
- `magicain-cloud`: backend services, admin APIs, business logic, persistence, billing enforcement
- `magicain-agent-ui`: customer admin UI and internal operator UI for agent management and billing visibility
- `magicain-ui`: end-user chat UI and user-facing runtime error presentation
- `magicain-admin-ui`: admin console outside the current billing flow

## Request Topology

At a high level:

1. Browser traffic enters through nginx.
2. Nginx routes frontend paths to the corresponding local frontend app.
3. API traffic is proxied to `magicain-cloud`.
4. Backend services talk to PostgreSQL, Redis, Elasticsearch, Langfuse, and monitoring components.

## Key Frontend Routes

- `/admin/` -> admin frontend
- `/agent/` -> agent frontend
- `/c/` -> end-user chat frontend
- `/api/` -> cloud public/backend API
- `/admin-api/` -> cloud admin API

## Cross-Repo Feature Example: Billing

The billing feature currently spans multiple repos:

- `magicain-cloud`
  - point accounting
  - billing cycle management
  - quota enforcement
  - billing summary and detail APIs
- `magicain-agent-ui`
  - admin-facing Points usage page
  - billing cycle summary presentation
  - filters, trend charts, trace-level detail
- `magicain-ui`
  - user-facing quota error display when requests are rejected
  - end-to-end coverage for quota rejection messaging
- `magicain-nginx`
  - integration path documentation
  - local dev and deployment routing
  - cross-repo validation harness documentation

For details, see [docs/systems/billing.md](/Users/admin/Development/github/jackjack-7/magicain/magicain-nginx/docs/systems/billing.md).

## Documentation Ownership

- System behavior across repos: document here
- Repo-internal module behavior: document in the owning repo
- Long-lived implementation specs: keep in the owning repo and link from here

## Integration Philosophy

This repo should make cross-repo work legible by answering:

- which repo owns which behavior
- how a user request flows across repos
- how to start the system locally
- how to validate a feature end-to-end
- what release gates apply before merge or rollout
