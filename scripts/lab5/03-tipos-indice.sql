WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT ===== 1. INDICE UNICO (Q13 - DNI/Email) =====
EXEC lab_tools.medir.consulta('Q13 sin indice', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE email = 'cli4711@ts.es']');

PROMPT ===== 2. INDICE COMPUESTO Y CUBRIENTE (Q7 - Historial cliente) =====
EXEC lab_tools.medir.consulta('Q7 con PK', q'[SELECT id_pedido, fecha_pedido, importe FROM tiendasur.pedido WHERE id_cliente = 4711 AND fecha_pedido >= SYSDATE - 365]');

CREATE INDEX tiendasur.ix_ped_cli_fec ON tiendasur.pedido (id_cliente, fecha_pedido);
EXEC lab_tools.medir.consulta('Q7 compuesto', q'[SELECT id_pedido, fecha_pedido, importe FROM tiendasur.pedido WHERE id_cliente = 4711 AND fecha_pedido >= SYSDATE - 365]');

DROP INDEX tiendasur.ix_ped_cli_fec;
EXIT
