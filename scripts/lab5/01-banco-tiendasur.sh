#!/usr/bin/env bash
set -e

source scripts/deployment/env/00-config.sh

LOG_FILE="$EVID_LAB5/script/$(ts)_01-banco-tiendasur.script.log"

echo "== Aplicando Migracion V004 y preparando Banco TiendaSur ==" | tee "$LOG_FILE"

docker exec -i oralab-26ai sqlplus -s / as sysdba < database/migrations/V004_banco_tiendasur.sql 2>&1 | tee -a "$LOG_FILE"

echo "== Proceso completado exitosamente ==" | tee -a "$LOG_FILE"
