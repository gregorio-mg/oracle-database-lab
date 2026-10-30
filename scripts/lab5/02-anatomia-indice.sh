#!/usr/bin/env bash
set -e

source scripts/deployment/env/00-config.sh

LOG_FILE="$EVID_LAB5/script/$(ts)_02-anatomia-indice.script.log"

echo "== Analizando Anatomia de Indices B-Tree ==" | tee "$LOG_FILE"

docker exec -i oralab-26ai sqlplus -s / as sysdba < database/migrations/V005_anatomia_indice.sql 2>&1 | tee -a "$LOG_FILE"

echo "== Consulta anatomica completada ==" | tee -a "$LOG_FILE"
