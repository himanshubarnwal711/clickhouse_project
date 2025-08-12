# ---------- Stage 1: Build ClickHouse ----------
FROM clickhouse/clickhouse-server:latest-alpine AS builder

# We already have clickhouse binaries in the Alpine image; no need to build from scratch
# Just copy out the essentials
RUN mkdir -p /clickhouse-min/bin && \
    cp /usr/bin/clickhouse* /clickhouse-min/bin && \
    cp -r /etc/clickhouse-server /clickhouse-min/etc && \
    mkdir -p /clickhouse-min/lib && \
    cp -r /var/lib/clickhouse /clickhouse-min/lib

# ---------- Stage 2: Minimal Runtime ----------
FROM alpine:3.20

# Install only required runtime dependencies
RUN apk add --no-cache bash curl tzdata libstdc++ jemalloc

# Create clickhouse user and group
RUN addgroup -S clickhouse && adduser -S clickhouse -G clickhouse

# Copy binaries and configs from builder
COPY --from=builder /clickhouse-min/bin /usr/bin
COPY --from=builder /clickhouse-min/etc /etc/clickhouse-server
COPY --from=builder /clickhouse-min/lib /var/lib/clickhouse

# Create volumes
VOLUME ["/var/lib/clickhouse", "/var/log/clickhouse-server"]

# Environment vars for default user
ENV CLICKHOUSE_USER=raja
ENV CLICKHOUSE_PASSWORD=12345678
ENV CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1

# Ports
EXPOSE 9000 8123

# Default command
CMD ["clickhouse-server", "--config-file=/etc/clickhouse-server/config.xml"]

