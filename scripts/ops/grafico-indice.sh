#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
OWNER="${1:?Uso: grafico-indice.sh <ESQUEMA> <INDICE> [evidencia]}"; INDICE="${2:?Falta el nombre del índice}"
LOG="${3:-/dev/null}"
[ "$LOG" = /dev/null ] || mkdir -p "$(dirname "$LOG")"
OWNER="${OWNER^^}"; INDICE="${INDICE^^}"

HOJAS="(SELECT ROW_NUMBER() OVER (ORDER BY line_number) AS pos,
               TO_NUMBER(REGEXP_SUBSTR(payload, 'row:([0-9]+)', 1, 1, NULL, 1)) AS nrow,
               TO_NUMBER(REGEXP_SUBSTR(payload, 'row:[0-9]+[.]([0-9]+)', 1, 1, NULL, 1)) AS rrow,
               TO_NUMBER(REGEXP_SUBSTR(payload, 'avs:([0-9]+)', 1, 1, NULL, 1)) AS avs
        FROM v\$diag_trace_file_contents WHERE trace_filename = '&tf' AND payload LIKE '%leaf: 0x%')"

OCU="CASE WHEN nrow = 0 THEN 0 ELSE (7996 - avs) / 7996 * rrow / nrow END"

docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba <<SQL | tee "$LOG"
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 150 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
ALTER SESSION SET CONTAINER = FREEPDB1;

COLUMN tf NEW_VALUE tf NOPRINT

DECLARE
  v_oid NUMBER;
BEGIN
  SELECT object_id INTO v_oid FROM dba_objects WHERE owner = '$OWNER' AND object_name = '$INDICE' AND object_type = 'INDEX' AND ROWNUM = 1;
  EXECUTE IMMEDIATE 'ALTER SESSION SET tracefile_identifier = ''grafico_$INDICE''';
  EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''immediate trace name treedump level ' || v_oid || '''' ;
EXCEPTION
  WHEN OTHERS THEN NULL;
END;
/

SELECT SUBSTR(value, INSTR(value, '/', -1) + 1) AS tf FROM v\$diag_info WHERE name = 'Default Trace File';
COLUMN ocupacion FORMAT A52
COLUMN mapa FORMAT A66
COLUMN rango FORMAT A9

PROMPT
PROMPT ===== $OWNER.$INDICE · resumen =====
SELECT COUNT(*) AS hojas, SUM(rrow) AS entradas_vivas, SUM(nrow - rrow) AS entradas_borradas,
       ROUND(AVG(rrow)) AS media_entradas_por_hoja,
       ROUND(100 * AVG($OCU), 1) AS pct_ocupacion_viva, ROUND(100 * AVG((7996 - avs) / 7996), 1) AS pct_espacio_usado,
       SUM(CASE WHEN rrow = 0 THEN 1 ELSE 0 END) AS hojas_vacias,
       SUM(CASE WHEN $OCU < 0.5 THEN 1 ELSE 0 END) AS hojas_bajo_50pct
FROM $HOJAS;

PROMPT
PROMPT ===== Histograma de llenado =====
SELECT LPAD(TRUNC(LEAST(99, 100 * $OCU) / 10) * 10, 3) || '-' || RPAD(TRUNC(LEAST(99, 100 * $OCU) / 10) * 10 + 9, 2) || ' %' AS rango,
       COUNT(*) AS hojas,
       RPAD('#', CEIL(50 * COUNT(*) / MAX(COUNT(*)) OVER ()), '#') AS ocupacion
FROM $HOJAS
GROUP BY TRUNC(LEAST(99, 100 * $OCU) / 10) ORDER BY TRUNC(LEAST(99, 100 * $OCU) / 10);

PROMPT
PROMPT ===== Mapa de izquierda a derecha (64 tramos) =====
SELECT '[' || LISTAGG(CASE WHEN o < 0.1 THEN ' ' WHEN o < 0.3 THEN '.' WHEN o < 0.5 THEN ':'
                           WHEN o < 0.7 THEN '-' WHEN o < 0.9 THEN '=' ELSE '#' END) WITHIN GROUP (ORDER BY t)
       || ']' AS mapa
FROM (SELECT t, AVG($OCU) AS o
      FROM (SELECT NTILE(64) OVER (ORDER BY pos) AS t, nrow, rrow, avs FROM $HOJAS) GROUP BY t);
EXIT
SQL
