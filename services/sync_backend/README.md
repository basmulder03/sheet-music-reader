# Sync Backend (Dart)

Self-hosted sync backend for Sheet Music Reader.

This service is intentionally standalone from the Flutter app so it can be moved to a dedicated repository later with minimal changes.

## Current Status

Implemented in this first pass:

- Dart HTTP service (`shelf`)
- Single-tenant auth (`Bearer` token)
- SQLite metadata store
- Filesystem blob store
- Artifact format support (`musicxml`, `pdf`, `image`, `midi`)
- Incremental sync change feed (`/v1/sync/changes`)
- Dockerfile + compose starter

Not yet implemented:

- WebSocket sync stream
- S3/Postgres drivers
- desktop/mobile client integration
- Unraid Community Apps publish pipeline

## Configuration

Environment variables:

- `SYNC_BACKEND_HOST` (default: `0.0.0.0`)
- `SYNC_BACKEND_PORT` (default: `9090`)
- `SYNC_BACKEND_DATA_DIR` (default: `./data`)
- `SYNC_BACKEND_API_TOKEN` (default: `dev-token`)

## Run Locally

```bash
cd services/sync_backend
dart pub get
SYNC_BACKEND_API_TOKEN=local-dev-token dart run bin/sync_backend.dart
```

## API (v1)

Auth for all endpoints except health:

`Authorization: Bearer <token>`

- `GET /v1/health`
- `GET /v1/documents?since=<eventId>&limit=<n>`
- `GET /v1/documents/{id}`
- `PUT /v1/documents/{id}`
- `GET /v1/documents/{id}/artifacts`
- `PUT /v1/documents/{id}/artifacts/{format}`
- `GET /v1/documents/{id}/artifacts/{format}`
- `GET /v1/sync/changes?since=<cursor>&limit=<n>`

## Docker

```bash
cd services/sync_backend
docker compose up --build
```

## Unraid Preparation

The service is designed for Unraid compatibility:

- stateless container process
- persistent data under `/data`
- token via env var
- single exposed port

Planned next step: add an Unraid template XML and publish image tags for `linux/amd64` and `linux/arm64`.
