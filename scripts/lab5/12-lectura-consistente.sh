#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
SALIDA_A=$(mktemp)
docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba < scripts/lab5/12-sesion-a.sql > "$SALIDA_A" &
PID_A=$!
sleep 5
echo "################ SESIÓN B ################"
docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba < scripts/lab5/12-sesion-b.sql
wait "$PID_A"
echo "################ SESIÓN A (en paralelo) ################"
grep -v '^$' "$SALIDA_A"
rm -f "$SALIDA_A"
