#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

TS=$(ts)
mkdir -p "$EVID_LAB5/script" "$EVID_LAB5/config"
LOG_FILE="$EVID_LAB5/script/${TS}_02-anatomia-indice.script.log"

echo "== Analizando anatomia de indices B-tree ==" | tee "$LOG_FILE"
docker exec -i oralab-26ai sqlplus -s / as sysdba < scripts/lab5/02-anatomia-indice.sql 2>&1 | tee -a "$LOG_FILE"

for IDX in PK_PEDIDO IX_PED_CLIENTE; do
  if [ -f scripts/ops/grafico-indice.sh ]; then
    bash scripts/ops/grafico-indice.sh TIENDASUR "$IDX" "$EVID_LAB5/script/${TS}_02-grafico-${IDX}.script.log" 2>/dev/null || true
  fi
done

echo "== Anatomia completada ==" | tee -a "$LOG_FILE"
