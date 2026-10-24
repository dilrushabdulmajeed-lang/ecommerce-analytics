# Operations guide

| Service    | URL                    | Notes |
|------------|------------------------|-------|
| n8n        | http://localhost:5678  | workflows |
| Metabase   | http://localhost:3000  | dashboards |
| ClickHouse | http://localhost:8123  | db `analytics`; credentials in `.env` |

Metabase connects as the read-only `metabase` ClickHouse user (host `clickhouse`, port 8123).
ClickHouse is pinned to 26.3 LTS: `latest` (26.9) breaks Metabase's bundled JDBC driver ("Invalid LZ4 magic byte").

ClickHouse SQL shell: `docker exec -it clickhouse clickhouse-client -u analyst --password <from .env>`
Re-seed synthetic e-commerce data: `docker exec -i clickhouse clickhouse-client -u analyst --password <pw> --multiquery < sql/01_ecom_schema_and_seed.sql` (then re-run `sql/02_ecom_rfm_view.sql`)

Run these commands from the repo root:

| Task   | Command |
|--------|---------|
| Start  | `docker compose up -d` |
| Stop   | `docker compose down` |
| Logs   | `docker compose logs -f <n8n|clickhouse|metabase>` |
| Update | `docker compose pull && docker compose up -d` |
| Status | `docker compose ps` |

## Backup a volume (n8n shown; same for `<project>_clickhouse_data` / `<project>_metabase_data`)
```sh
docker run --rm -v <project>_n8n_data:/data -v "$PWD":/backup alpine \
  tar czf /backup/n8n_data-$(date +%Y%m%d-%H%M%S).tar.gz -C /data .
```

## Restore (stop n8n first)
```sh
docker compose down
docker run --rm -v <project>_n8n_data:/data -v "$PWD":/backup alpine \
  sh -c "rm -rf /data/* && tar xzf /backup/<file>.tar.gz -C /data"
docker compose up -d
```

## Webhook testing with ngrok (optional)
1. `brew install ngrok` and `ngrok config add-authtoken <token>`
2. `ngrok http 5678` and copy the `https://….ngrok-free.app` URL
3. Add `- WEBHOOK_URL=https://<your-subdomain>.ngrok-free.app/` under `environment:`
4. `docker compose up -d` (recreates the container with the new URL)

## n8n file exports
`./exports` on the host is mounted at `/home/node/exports` in the n8n container (`N8N_RESTRICT_FILE_ACCESS_TO`). The weekly At-Risk workflow writes `at_risk_customers_YYYY-MM-DD.csv` there.

`<project>` is the Docker Compose project name: the folder name by default (e.g. `ecommerce-analytics`).
