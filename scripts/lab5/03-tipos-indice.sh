#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

TS=$(ts)
LOG_FILE="$EVID_LAB5/script/${TS}_03-tipos-indice.script.log"

echo "== Midiendo tipos de indice (Parte D) ==" | tee "$LOG_FILE"
docker exec -i oralab-26ai sqlplus -s / as sysdba < scripts/lab5/03-tipos-indice.sql 2>&1 | tee -a "$LOG_FILE"
echo "== Pruebas de tipos de indice completadas ==" | tee -a "$LOG_FILE"
