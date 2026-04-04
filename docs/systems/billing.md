# Billing System

This document describes the cross-repo billing flow for Points usage and quota enforcement.

## Purpose

Billing is presented externally as Points.
The system needs to support:

- billing cycle totals per tenant
- consumed and remaining points
- trace-level usage visibility for customer admins
- request rejection when a billing cycle has insufficient remaining points
- clear user-facing error messaging

## Repo Responsibilities

### `magicain-cloud`

Owns:

- billing cycle persistence
- summary and detail query APIs
- quota reservation and settlement
- request rejection on insufficient points

### `magicain-agent-ui`

Owns:

- Points usage page for customer admins
- billing cycle summary card
- filtered billing trends and trace-level details

### `magicain-ui`

Owns:

- user-facing handling of quota rejection errors
- display of backend error messages in chat flows
- UI automation for quota-rejection scenarios

### `magicain-nginx`

Owns:

- system-level documentation of the feature
- local routing context
- end-to-end validation harness definition

## Current End-to-End Flow

1. User initiates an agent request from `magicain-ui` or another frontend.
2. The request reaches `magicain-cloud` through nginx routing.
3. Backend quota logic checks whether the active billing cycle can reserve points.
4. If quota is available, request execution continues and points are settled afterward.
5. If quota is exhausted, the backend returns a stable business error.
6. `magicain-ui` surfaces the backend message to the user.
7. `magicain-agent-ui` exposes cycle-level and trace-level usage information to tenant admins.

## Current Source-of-Truth Docs

- Backend design: [`../magicain-cloud/docs/agent/design/llm-tracing-billing/billing-design.md`](../../../magicain-cloud/docs/agent/design/llm-tracing-billing/billing-design.md)
- Backend trace context: [`../magicain-cloud/docs/agent/design/llm-tracing-billing/trace-design.md`](../../../magicain-cloud/docs/agent/design/llm-tracing-billing/trace-design.md)

## Expected Validation Surfaces

- backend unit/integration tests for quota logic
- admin UI build validation for Points pages
- user UI E2E for quota rejection display
- real-tenant smoke checks where appropriate
