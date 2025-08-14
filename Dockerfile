# Dockerfile for Clickhouse 25.7.2
FROM docker.io/clickhouse/clickhouse-server:25.7.2

# Set environment variables for user and password
ENV CLICKHOUSE_USER=test
ENV CLICKHOUSE_PASSWORD=12345678
ENV CLICKHOUSE_DEFAULT_ACCESS_MANAGEMENT=1

# Expose default Clickhouse ports
EXPOSE 8123 9000 9009

# Create a volume for persistent data
VOLUME ["/var/lib/clickhouse"]

# Start Clickhouse server
CMD ["/entrypoint.sh"]

