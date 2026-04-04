# Release Gates

This document defines minimum release gates for cross-repo changes.

## Cross-Repo Feature Gate

A feature touching multiple repos should not be considered complete unless:

- the system-level doc in this repo is updated
- each owning repo contains the required implementation and local validation
- the integration harness doc lists concrete validation steps
- the responsible PRs reference each other where appropriate

## Billing Gate

For billing-related changes, minimum expectations are:

- backend quota logic is tested
- backend live billing APIs are checked against the shared test tenant
- changed frontend features pass their own smoke checks
- user quota error presentation is validated
- any new SQL patch is documented
- tenant-facing terminology remains Points rather than provider/model internals

## Documentation Gate

System-level docs in this repo should answer:

- what changed across repos
- which repo owns each part
- how to validate the feature end-to-end

If a change cannot be validated from the repository, the documentation is incomplete.
