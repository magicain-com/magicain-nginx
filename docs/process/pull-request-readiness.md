# Pull Request Readiness

This document defines the documentation workflow that must be completed before opening a pull request.

`AGENTS.md` is only a top-level index.
The actual documentation requirements live here.

## When This Applies

Apply this workflow to every feature and bugfix.

For small single-repo fixes, the amount of documentation may be minimal.
For cross-repo work, interface changes, tenant/auth/billing changes, or features requiring integration testing, the full workflow is required.

## Required Before Opening a PR

### 1. Update the feature record

There must be a single working record for the change:

- preferred location: `docs/exec-plans/active/<feature-name>.md`
- if the change is too small to justify a full execution plan, the PR description must explicitly state why

The working record must describe:

- what changed
- which repos were involved
- acceptance criteria
- validation commands

### 2. Add a Decision Log

Every substantial feature or bugfix must carry a short Decision Log.
The Decision Log should normally live inside the execution plan.

Each entry should capture:

- date
- decision
- reason
- impact

The goal is not to create long design essays.
The goal is to preserve the important development decisions that explain why the implementation looks the way it does.

### 3. Update documents changed by the PR

Before opening the PR, review whether the following need updates:

- top-level architecture docs
- system docs under `docs/systems/`
- harness docs under `docs/testing/`
- release or quality docs
- repo-local design docs in the child repos
- `README.md` files

If any of those are affected by the change, they must be updated in the same iteration.

### 4. Validate documentation coverage

The PR is not ready if the documents do not explain:

- user-visible changes
- cross-repo ownership
- validation path
- key development decisions

## Minimum Documentation Expectations

### Feature

A feature PR should usually include:

- execution plan update
- Decision Log updates
- system or repo design doc update if behavior changed
- README update if setup, usage, or entrypoints changed

### Bugfix

A bugfix PR should usually include:

- execution plan update or a documented exemption in the PR
- Decision Log entry if the fix involved a meaningful tradeoff
- doc update if the fix changes behavior, constraints, or validation

## PR Checklist

Before opening a PR, confirm all of the following:

- the execution plan or feature record is updated
- the PR's own changes are summarized in that document
- the Decision Log is updated
- architecture/design docs were checked
- README updates were checked
- validation commands were run or explicitly marked as not run

## Completion

After merge:

- move completed execution plans from `active/` to `completed/`
- keep the Decision Log with the completed plan
