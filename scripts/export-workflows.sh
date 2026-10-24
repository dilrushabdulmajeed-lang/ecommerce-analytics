#!/usr/bin/env bash
# Export n8n workflows to workflows/, stripping account info, IDs and pinned test data.
# Usage: ./scripts/export-workflows.sh [name-filter]   (default filter: "At-Risk")
set -euo pipefail
cd "$(dirname "$0")/.."
filter="${1:-At-Risk}"
docker exec n8n sh -c 'rm -rf /tmp/wf && n8n export:workflow --all --separate --output=/tmp/wf/ >/dev/null'
tmp=$(mktemp -d); docker cp n8n:/tmp/wf/. "$tmp/"
python3 - "$tmp" "$filter" <<'PY'
import json, re, sys, pathlib
src, flt = pathlib.Path(sys.argv[1]), sys.argv[2].lower()
for f in src.glob('*.json'):
    d = json.loads(f.read_text())
    if flt not in d['name'].lower():
        continue
    clean = {k: d[k] for k in ('name', 'nodes', 'connections', 'settings') if k in d}
    slug = re.sub(r'[^a-z0-9]+', '-', d['name'].lower()).strip('-')
    pathlib.Path('workflows', f'{slug}.json').write_text(json.dumps(clean, indent=2, ensure_ascii=False) + '\n')
    print('exported', slug)
PY
rm -rf "$tmp"
