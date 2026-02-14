# Admin UI Integration TODOs (Optional)

These are backend-side tasks to make an admin management UI easy to add later.

## Phase 1: Read-Only Admin APIs

- [ ] Add `GET /v1/admin/summary` for high-level stats (documents, artifacts, storage, recent sync events).
- [ ] Add `GET /v1/admin/documents` with filters (title, updated range, has pdf/musicxml, deleted status).
- [ ] Add `GET /v1/admin/documents/{id}` with joined artifact and event info.
- [ ] Add `GET /v1/admin/events` with cursor-based pagination and event-type filtering.
- [ ] Add `GET /v1/admin/health` with dependency checks (sqlite readable, blob store writable).

## Phase 2: Admin Actions

- [ ] Add `POST /v1/admin/documents/{id}/reindex` to rebuild metadata projections.
- [ ] Add `DELETE /v1/admin/documents/{id}/artifacts/{format}` with soft-delete event logging.
- [ ] Add `POST /v1/admin/cache/cleanup` for stale file cleanup.
- [ ] Add `POST /v1/admin/sync/replay` to rebuild sync state from event log.
- [ ] Add `POST /v1/admin/maintenance/vacuum` for sqlite maintenance.

## Phase 3: Auth and Permissions for Admin UI

- [ ] Split current single API token into scoped tokens (`client`, `admin_read`, `admin_write`).
- [ ] Add middleware for role checks on `/v1/admin/*` endpoints.
- [ ] Add token rotation endpoint and token metadata persistence.
- [ ] Add optional IP allowlist for admin routes.
- [ ] Add request auditing (who, what, when, status) for admin actions.

## Phase 4: Operational Support

- [ ] Add Prometheus-compatible metrics endpoint (`/metrics`) for admin dashboards.
- [ ] Add structured logs with request IDs and admin action tags.
- [ ] Add backup/restore endpoints or scripts for metadata + blobs.
- [ ] Add rate limits specifically for admin routes.
- [ ] Add feature flags to enable/disable admin module independently.

## Phase 5: UI-Facing Contract Stability

- [ ] Define versioned response DTOs for admin endpoints in `packages/sync_protocol`.
- [ ] Add integration tests that lock admin response shapes.
- [ ] Add OpenAPI spec section for `/v1/admin/*`.
- [ ] Add server-side pagination and sort contracts with deterministic defaults.
- [ ] Add deprecation policy notes for future admin API changes.

## Nice-to-Have

- [ ] Server-sent events stream for live admin dashboard updates.
- [ ] Export reports (CSV/JSON) for document and sync activity.
- [ ] Background job queue for long-running admin tasks.
- [ ] Webhook support for admin alerts (failed uploads, storage thresholds).
