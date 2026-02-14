FROM dart:stable AS build

WORKDIR /app

COPY packages/sync_protocol /app/packages/sync_protocol
COPY services/sync_backend /app/services/sync_backend

WORKDIR /app/services/sync_backend
RUN dart pub get
RUN dart compile exe bin/sync_backend.dart -o /app/build/sync_backend

FROM debian:bookworm-slim

RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=build /app/build/sync_backend /app/sync_backend

ENV SYNC_BACKEND_HOST=0.0.0.0
ENV SYNC_BACKEND_PORT=9090
ENV SYNC_BACKEND_DATA_DIR=/data
ENV SYNC_BACKEND_API_TOKEN=change-me

EXPOSE 9090
VOLUME ["/data"]

ENTRYPOINT ["/app/sync_backend"]
