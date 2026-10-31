#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
TS=$(ts)
mkdir -p "$EVID_LAB5/script" "$EVID_LAB5/config"

bash scripts/ops/sysdba.sh scripts/lab5/02-anatomia-indice.sql "$EVID_LAB5/script/${TS}_02-anatomia-indice.script.log"

PK_PED=$(docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba <<'SQL' | grep -E '^SYS_|^PK_' | head -1 | xargs || true
ALTER SESSION SET CONTAINER = FREEPDB1;
SET HEAD OFF FEEDBACK OFF PAGES 0 LINES 200
SELECT index_name FROM dba_indexes WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO' AND uniqueness = 'UNIQUE' AND ROWNUM = 1;
EXIT
SQL
)

for IDX in "$PK_PED" IX_PED_CLIENTE; do
  [ -n "$IDX" ] && bash scripts/ops/grafico-indice.sh TIENDASUR "$IDX" "$EVID_LAB5/script/${TS}_02-grafico-${IDX}.script.log"
done

TRAZA=$(docker exec "$CONT_NAME" bash -c 'ls -t /opt/oracle/diag/rdbms/free/FREE/trace/*lab5_indice*.trc | head -1')
docker cp "$CONT_NAME:$TRAZA" "$EVID_LAB5/config/${TS}_02-volcado-indice.trc.txt"
echo "Traza del treedump copiada a $EVID_LAB5/config/${TS}_02-volcado-indice.trc.txt"
