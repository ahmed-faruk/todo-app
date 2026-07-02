<!-- Source: ApexYard · templates/agdr-migration.md · github.com/me2resh/apexyard · MIT -->

# Add sortOrder column to TodoItems (Drift schemaVersion 1→2)

> In the context of adding drag-to-reorder to the todo list (GH-13), facing the fact that the app has no persisted manual ordering (list order is derived from `createdAt`), I decided to execute a schema migration adding a `sortOrder` integer column to `TodoItems`, backfilled from current `createdAt DESC` order, to achieve manual reorder support, accepting the app's first-ever `MigrationStrategy` complexity in exchange for a minimal, additive, non-destructive change.

**Migration type**: schema
**Affected tables / entities**: `todo_items` (Drift `TodoItems` table)
**Estimated downtime**: none — local SQLite, migration runs synchronously and near-instantly on next app launch, no user-facing downtime window
**Data volume**: unknown exact count, but bounded by a single user's local todo list (realistically tens to low hundreds of rows) — never a scale concern
**Target environment(s)**: dev-only until release, then ships to all users via normal app-store update (no staging/prod split for a local mobile app)

## Context

`reorder-todos` (ahmed-faruk/todo-app#13, technical design: `projects/todo-app/designs/reorder-todos-technical-design.md` in the ops fork) requires a persisted manual sort position. The app's `schemaVersion` has been `1` since inception with no `MigrationStrategy` defined — this is the first schema change the app has needed.

## Options Considered

| Option | Pros | Cons |
|--------|------|------|
| Add `sortOrder` INTEGER column, backfill from `createdAt DESC` | Additive-only, non-destructive, preserves current visual order on upgrade, minimal migration surface | Requires the app's first-ever `MigrationStrategy` (new code path, no precedent to follow in this codebase) |
| Derive order at query time from a separate ordering table | Keeps `TodoItems` unchanged | Unnecessary complexity for a single-user local app; extra join for no benefit |
| Repurpose `createdAt` and rewrite it on reorder | No new column | Destroys the true creation timestamp (a real, separate piece of information); conflates two distinct concepts |

## Decision

Chosen: **add a dedicated `sortOrder` INTEGER column**, because it's the smallest additive change that cleanly separates "when was this created" from "where does the user want it in the list", and backfilling from current `createdAt DESC` order guarantees existing users see zero visual change immediately after upgrading.

## Rollback Plan

**Explicit rollback steps**:

1. If `onUpgrade` throws or the backfill produces incorrect ordering: ship a follow-up patch release with a corrected `onUpgrade` branch. The `from < 2` migration step is idempotent — it always recomputes `sortOrder` from `createdAt DESC`, so re-running it (via the corrected patch) fixes any bad state without a separate down-migration.
2. The added column is strictly additive — `id`, `title`, `isCompleted`, `createdAt` are never touched by this migration, so a failed/buggy migration cannot corrupt or lose existing todo data.
3. Worst case (user hits a persistent crash on upgrade): the existing "clear app data" escape hatch resets the local db entirely — the user loses only manual ordering preference (which didn't exist before this feature anyway), not their todos, since todos are recreated from scratch only in that extreme case. This is the same blast radius as before an app has been used, not a data-loss regression.

**Rollback tested against**: unit fixture — a dedicated migration test (`test/data/drift_todo_repository_test.dart`) builds a v1-shaped in-memory database, inserts rows, runs the v1→v2 `onUpgrade`, and asserts `sortOrder` matches the prior `createdAt DESC` order.
**Rollback window**: not time-bounded in the traditional sense — because the migration is idempotent and additive, a corrected patch release can be shipped at any point after the original release without a fidelity-loss window (unlike migrations where accumulated new-shape writes make reversal lossy).

## Cross-Service Consumers

- **none** — local-only SQLite on-device, single Flutter app, no backend, no other services read or write this table.

Deploy-order constraint: none.

## Testing Plan

- **Dev smoke**: `flutter test test/data/drift_todo_repository_test.dart` — includes the migration test described above.
- **Staging verify**: manual install of the current (v1-schema) release build, add several todos, then install the v2 build over it (simulating a real user upgrade) and confirm (a) existing todos appear in the same order as before, (b) drag-reorder works immediately after.
- **Canary / phased rollout**: n/a — mobile app-store rollout is inherently phased by store update propagation; no separate canary mechanism exists or is needed for a local-data-only change of this size.

## Observability

No telemetry/crash-reporting infrastructure exists in this app (out of scope to add here). Verification is via:

- **During apply**: the migration test assertion (backfilled `sortOrder` matches prior `createdAt DESC` order) run in CI on every PR.
- **Post-apply**: manual staging-verify step above before the release ships; QA Engineer verification per the SDLC's mandatory QA gate covers the user-facing check.
- **Alerts armed**: n/a — no production monitoring surface for this local-only app.

## Consequences

- Enables the `reorder-todos` feature (GH-13) — manual drag-to-reorder becomes possible.
- Establishes the app's first `MigrationStrategy` pattern, which future schema changes will extend rather than re-invent.
- Minor: `watchAll()`'s default ordering changes from `createdAt DESC` to `sortOrder ASC` — behaviorally identical immediately post-migration (since backfill preserves the same visual order), but any future code relying on `createdAt` for list order must be aware this is no longer the sort key.

## Artifacts

- Ticket: ahmed-faruk/todo-app#14 — https://github.com/ahmed-faruk/todo-app/issues/14
- Commits / PRs: to be filled in as the migration ships
- Staging-run log: n/a for this app (no CI staging environment beyond `flutter test` in GitHub Actions)
- Post-apply dashboard snapshot: n/a — no dashboards for this app
