#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
NUEVA="$DATA_ROOT/FREE/control03.ctl"
sql() { docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba; }

ACTUAL=$(printf "SET HEADING OFF FEEDBACK OFF PAGESIZE 0 LINESIZE 400\nSELECT value FROM v\$parameter WHERE name = 'control_files';\nEXIT\n" | sql | xargs)
echo "control_files actual: $ACTUAL"

if [[ "$ACTUAL" == *control03.ctl* ]]; then 
  echo "Ya hay tercera copia: nada que hacer."
  exit 0
fi

LISTA="'$(echo "$ACTUAL" | sed "s/, */','/g")','$NUEVA'"

echo "== 1. Nuevo valor en el SPFILE =="
printf "ALTER SYSTEM SET control_files = %s SCOPE = SPFILE;\nEXIT\n" "$LISTA" | sql

echo "== 2. Parada limpia =="
printf "SHUTDOWN IMMEDIATE\nEXIT\n" | sql

echo "== 3. Copia física de una copia sana al nuevo nombre =="
PRIMERA=$(echo "$ACTUAL" | cut -d, -f1 | xargs)
docker exec "$CONT_NAME" cp -p "$PRIMERA" "$NUEVA"
docker exec "$CONT_NAME" ls -l "$DATA_ROOT/FREE/" | grep control

echo "== 4. Arranque con las TRES copias =="
printf "STARTUP\nSET LINESIZE 120\nCOLUMN name FORMAT A48\nSELECT name, status FROM v\$controlfile;\nEXIT\n" | sql
bash scripts/ops/esperar-healthy.sh
