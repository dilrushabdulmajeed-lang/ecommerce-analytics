#!/usr/bin/env bash
# One-time setup: create ClickHouse users, schema, synthetic data and reporting view.
set -euo pipefail
cd "$(dirname "$0")/.."
set -a; . ./.env; set +a
ch() { docker exec -i clickhouse clickhouse-client -u "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --multiquery; }

ch <<SQL
CREATE USER OR REPLACE ${METABASE_CH_USER} IDENTIFIED WITH sha256_password BY '${METABASE_CH_PASSWORD}' SETTINGS readonly = 2;
GRANT SELECT, SHOW ON analytics.* TO ${METABASE_CH_USER};
CREATE USER OR REPLACE ${N8N_CH_USER} IDENTIFIED WITH sha256_password BY '${N8N_CH_PASSWORD}';
GRANT SELECT, INSERT ON analytics.* TO ${N8N_CH_USER};
SQL

for f in sql/*.sql; do echo "running $f"; ch < "$f"; done
echo "done: $(echo "SELECT count() FROM analytics.ecom_events" | ch) events, $(echo "SELECT count() FROM analytics.ecom_orders" | ch) orders"
