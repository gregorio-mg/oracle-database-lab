WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT ===== 1. CONSULTA NO SARGABLE (Uso de funcion UPPER sobre columna) =====
EXEC lab_tools.medir.consulta('Sin FBI (Full Table Scan)', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE UPPER(nombre) = 'CLIENTE 5000']');

PROMPT ===== 2. CREACION DE INDICE BASADO EN FUNCION (FBI) =====
CREATE INDEX tiendasur.ix_cli_nombre_upper ON tiendasur.cliente (UPPER(nombre));
EXEC DBMS_STATS.GATHER_TABLE_STATS('TIENDASUR', 'CLIENTE');

EXEC lab_tools.medir.consulta('Con FBI (Index Range Scan)', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE UPPER(nombre) = 'CLIENTE 5000']');

PROMPT ===== 3. BUSQUEDAS POR RANGO Y SELECTIVIDAD =====
EXEC lab_tools.medir.consulta('Rango alta selectividad (pocos registros)', q'[SELECT id_pedido, fecha_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido >= SYSDATE - 5]');
EXEC lab_tools.medir.consulta('Rango baja selectividad (mayoría de registros)', q'[SELECT id_pedido, fecha_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido >= SYSDATE - 350]');

DROP INDEX tiendasur.ix_cli_nombre_upper;
EXIT
