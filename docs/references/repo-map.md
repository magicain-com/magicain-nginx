# Repo Map

## Ownership

- `magicain-nginx`: routing, env topology, cross-repo docs
- `magicain-cloud`: backend, API, DB, backend integration tests
- `magicain-agent-ui`: tenant admin UI, feature smoke in repo
- `magicain-admin-ui`: platform admin UI, feature smoke in repo
- `magicain-ui`: end-user UI

## Local Test Model

- Start local services on the host.
- Local backend connects to the shared cloud test DB.
- One dedicated tenant is reserved for test data.
- Backend integration tests stay in `../magicain-cloud`.
- Frontend smoke tests stay in each frontend repo.

## Cross-Repo Rule

1. Find the owning repo.
2. Implement there.
3. Keep cross-repo context in `magicain-nginx`.
4. Run only the smoke/integration checks for the changed feature.
