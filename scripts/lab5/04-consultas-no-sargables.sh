#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh

TS=$(ts)
LOG_FILE="$EVID_LAB5/script/${TS}_04-consultas-no-sargables.script.log"

echo "== Midiendo consultas no sargables e indices FBI (Parte E) ==" | tee "$LOG_FILE"
docker exec -i oralab-26ai sqlplus -s / as sysdba < scripts/lab5/04-consultas-no-sargables.sql 2>&1 | tee -a "$LOG_FILE"
echo "== Pruebas de consultas no sargables completadas ==" | tee -a "$LOG_FILE"
