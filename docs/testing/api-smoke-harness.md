# API Integration And Smoke Context

## Rules

- Backend integration tests live in `../magicain-cloud`.
- Frontend smoke tests live in each frontend repo.
- Frontend smoke hits a local backend on the host.
- Local backend connects to the shared cloud test DB.
- Test data uses one dedicated SaaS tenant.
- Run only the smoke/integration checks for the changed feature.

## Env

Create `.env.smoke` from `.env.smoke.example`.

Common vars:

- `MAGICAIN_AGENT_TENANT_ID`
- `MAGICAIN_AGENT_USERNAME`
- `MAGICAIN_AGENT_PASSWORD`
- `MAGICAIN_ADMIN_TENANT_ID`
- `MAGICAIN_ADMIN_USERNAME`
- `MAGICAIN_ADMIN_PASSWORD`

Optional:

- `MAGICAIN_AGENT_TOKEN`
- `MAGICAIN_ADMIN_TOKEN`
- `MAGICAIN_BILLING_APP_ID`
- `MAGICAIN_BILLING_REQUEST_ID`
- `MAGICAIN_BILLING_START_DATE`
- `MAGICAIN_BILLING_END_DATE`

## Commands

Backend feature integration:

```bash
bash scripts/harness/test-backend-billing-integration.sh
```

Agent UI feature smoke:

```bash
cd ../magicain-agent-ui
npm run test:smoke
```

Admin UI feature smoke:

```bash
cd ../magicain-admin-ui
# run the feature smoke command defined in that repo
```
