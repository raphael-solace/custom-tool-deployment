#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=scripts/lib.sh
source "$SCRIPT_DIR/lib.sh"

require_cmd ssh
require_cmd scp
require_cmd expect

load_local_env

NAMESPACE="${NAMESPACE:-default}"
DB_POD="${DB_POD:-rfq-postgresql-0}"
DB_NAME="${DB_NAME:-rfq_acme_pim}"
SQL_FILE="${SQL_FILE:-$ROOT_DIR/deploy/rfq/sql/seed_rfp_mat_skus.sql}"
REMOTE_SQL="/tmp/seed_rfp_mat_skus.sql"

if [[ ! -f "$SQL_FILE" ]]; then
  log "SQL file not found: $SQL_FILE"
  exit 1
fi

log "Copying SKU seed SQL to remote"
copy_to_remote "$SQL_FILE" "$REMOTE_SQL"

log "Applying SKU seed SQL to $DB_NAME on $DB_POD"
run_remote "
  set -euo pipefail
  PGPASS=\$(kubectl -n $NAMESPACE get secret rfq-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)
  cat $REMOTE_SQL | kubectl -n $NAMESPACE exec -i $DB_POD -- env PGPASSWORD=\$PGPASS psql -v ON_ERROR_STOP=1 -U postgres -d $DB_NAME
"

log "Validating seeded MAT SKUs and supplier pricing"
run_remote "
  set -euo pipefail
  PGPASS=\$(kubectl -n $NAMESPACE get secret rfq-postgresql -o jsonpath='{.data.postgres-password}' | base64 -d)
  kubectl -n $NAMESPACE exec -i $DB_POD -- env PGPASSWORD=\$PGPASS psql -U postgres -d $DB_NAME -Atc \"select 'mat_count='||count(*) from public.products where upper(sku) like 'MAT-%';\"
  kubectl -n $NAMESPACE exec -i $DB_POD -- env PGPASSWORD=\$PGPASS psql -U postgres -d $DB_NAME -Atc \"select p.sku||'|'||ps.supplier_cost::text||'|'||ps.supplier_currency||'|'||ps.purchase_lead_time_days::text from public.products p join public.product_suppliers ps on ps.product_id = p.product_id where p.sku in ('MAT-200120','MAT-300080','MAT-400060','MAT-500200','MAT-700200') and ps.is_primary=true order by p.sku;\"
"

log "RFQ MAT SKU seed completed"
