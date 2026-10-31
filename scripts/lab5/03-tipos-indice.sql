-- scripts/lab5/03-tipos-indice.sql — experimentos de tipos de índice medidos con lab_tools.medir
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 250 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN index_name FORMAT A22
COLUMN index_type FORMAT A22

ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

DECLARE
  n NUMBER;
  PROCEDURE quitar(p_ddl VARCHAR2) IS BEGIN EXECUTE IMMEDIATE p_ddl; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_indexes WHERE owner = 'TIENDASUR' AND index_name = 'IX_PED_CLIENTE';
  IF n = 0 THEN
    RAISE_APPLICATION_ERROR(-20005, 'V005 ya está aplicada: este experimento es anterior.');
  END IF;

  quitar('DROP INDEX tiendasur.ux_cli_dni');
  quitar('DROP INDEX tiendasur.ix_ped_cli_fec');
  quitar('DROP INDEX tiendasur.ix_ped_cli_fec_cub');
  quitar('DROP INDEX tiendasur.ix_cli_upper_email');
  quitar('DROP INDEX tiendasur.ix_ped_est_fec');
  quitar('DROP INDEX tiendasur.ix_ped_pendientes');
  quitar('ALTER TABLE tiendasur.pedido DROP COLUMN fecha_pendiente');
  quitar('ALTER TABLE tiendasur.cliente DROP COLUMN dni');
  quitar('ALTER TABLE tiendasur.cliente DROP COLUMN pais');
  quitar('ALTER TABLE tiendasur.cliente DROP COLUMN ciudad');
  quitar('DROP TABLE tiendasur.venta_hecho PURGE');
  quitar('DROP TABLE tiendasur.sesion_heap PURGE');
  quitar('DROP TABLE tiendasur.sesion_iot PURGE');
  quitar('DROP TABLE tiendasur.sesion_hash');
  quitar('DROP CLUSTER tiendasur.cl_sesion');
END;
/

-- Asegurar la existencia de las columnas DNI, PAIS y CIUDAD en CLIENTE
DECLARE
  v_cnt NUMBER;
BEGIN
  -- DNI
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'DNI';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.cliente ADD (dni VARCHAR2(20))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.cliente SET dni = LPAD(id_cliente, 8, ''0'') || ''L''';
  END IF;

  -- PAIS
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'PAIS';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.cliente ADD (pais VARCHAR2(10))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.cliente SET pais = ''ES''';
  END IF;

  -- CIUDAD
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'CIUDAD';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.cliente ADD (ciudad VARCHAR2(50))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.cliente SET ciudad = CASE WHEN MOD(id_cliente, 10) = 0 THEN ''Lorca'' ELSE ''Madrid'' END';
  END IF;

  COMMIT;
END;
/

COLUMN dni NEW_VALUE dni NOPRINT
SELECT dni FROM tiendasur.cliente WHERE id_cliente = 4711;

PROMPT
PROMPT ===== 1. ÚNICO (Q13, verificación de identidad) =====
EXEC lab_tools.medir.consulta('Q13 sin índice', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE dni = '&dni']');
CREATE UNIQUE INDEX tiendasur.ux_cli_dni ON tiendasur.cliente (dni);
EXEC lab_tools.medir.consulta('Q13 con UNIQUE (dni)', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE dni = '&dni']');

WHENEVER SQLERROR CONTINUE
PROMPT Intento de inserción duplicada (esperado ORA-00001):
INSERT INTO tiendasur.cliente (id_cliente, dni, email, nombre) VALUES (999999, '&dni', 'otro@tiendasur.es', 'Cliente Dup');
WHENEVER SQLERROR EXIT FAILURE

PROMPT
PROMPT ===== 2. COMPUESTO y regla del prefijo izquierdo (Q6, clientes de Lorca) =====
EXEC lab_tools.medir.consulta('Q6 solo ciudad', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE ciudad = 'Lorca']');
EXEC lab_tools.medir.consulta('Q6 pais + ciudad', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE pais = 'ES' AND ciudad = 'Lorca']');

PROMPT
PROMPT ===== 3. COMPUESTO y CUBRIENTE (Q7, historial de cliente) =====
DEFINE q7 = "SELECT id_pedido, fecha_pedido, importe, estado FROM tiendasur.pedido WHERE id_cliente = 4711 AND fecha_pedido >= SYSDATE - 365 ORDER BY fecha_pedido DESC";
EXEC lab_tools.medir.consulta('Q7 con ix_ped_cliente', '&q7');
CREATE INDEX tiendasur.ix_ped_cli_fec ON tiendasur.pedido (id_cliente, fecha_pedido);
EXEC lab_tools.medir.consulta('Q7 (id_cliente, fecha)', '&q7');
CREATE INDEX tiendasur.ix_ped_cli_fec_cub ON tiendasur.pedido (id_cliente, fecha_pedido, importe, estado, id_pedido);
EXEC lab_tools.medir.consulta('Q7 cubriente', '&q7');

PROMPT
PROMPT ===== 4. FUNCIONAL (Q1, UPPER(email)) =====
EXEC lab_tools.medir.consulta('Q1 UPPER(email) tal cual', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE UPPER(email) = UPPER('Cliente4711@TiendaSur.es')]');
CREATE INDEX tiendasur.ix_cli_upper_email ON tiendasur.cliente (UPPER(email));
EXEC lab_tools.medir.consulta('Q1 con índice funcional', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE UPPER(email) = UPPER('Cliente4711@TiendaSur.es')]');

PROMPT
PROMPT ===== 5. PARCIAL vía columna virtual (Q12, pedidos pendientes) =====
CREATE INDEX tiendasur.ix_ped_est_fec ON tiendasur.pedido (estado, fecha_pedido);
ALTER TABLE tiendasur.pedido ADD (fecha_pendiente AS (CASE WHEN estado = 'P' THEN fecha_pedido END));
CREATE INDEX tiendasur.ix_ped_pendientes ON tiendasur.pedido (fecha_pendiente);
EXEC lab_tools.medir.consulta('Q12 (estado, fecha)', q'[SELECT id_pedido, id_cliente, fecha_pedido FROM tiendasur.pedido WHERE estado = 'P' ORDER BY fecha_pedido]');
EXEC lab_tools.medir.consulta('Q12 parcial', q'[SELECT id_pedido, id_cliente, fecha_pedido FROM tiendasur.pedido WHERE fecha_pendiente IS NOT NULL ORDER BY fecha_pendiente]');
SELECT index_name, leaf_blocks AS hojas, num_rows AS entradas FROM dba_indexes WHERE owner = 'TIENDASUR' AND index_name IN ('IX_PED_EST_FEC', 'IX_PED_PENDIENTES') ORDER BY index_name;

PROMPT
PROMPT ===== 6. BITMAP (Q14, almacén de datos) =====
CREATE TABLE tiendasur.venta_hecho NOLOGGING AS
SELECT ROWNUM AS id_venta, 
       2021 + MOD(ORA_HASH(ROWNUM, 4294967295, 21), 5) AS anio,
       'R' || MOD(ORA_HASH(ROWNUM, 4294967295, 22), 6) AS region,
       SUBSTR('WAT', MOD(ORA_HASH(ROWNUM, 4294967295, 23), 3) + 1, 1) AS canal,
       'Cat' || MOD(ORA_HASH(ROWNUM, 4294967295, 24), 25) AS categoria,
       ROUND(MOD(ORA_HASH(ROWNUM, 4294967295, 25), 50000) / 100, 2) AS importe
FROM (SELECT 1 FROM dual CONNECT BY LEVEL <= 1000), (SELECT 1 FROM dual CONNECT BY LEVEL <= 1000);

CREATE INDEX tiendasur.ix_vh_region_btree ON tiendasur.venta_hecho (region);
EXEC DBMS_STATS.GATHER_TABLE_STATS('TIENDASUR', 'VENTA_HECHO');
EXEC lab_tools.medir.consulta('Q14 sin bitmaps', q'[SELECT SUM(importe) FROM tiendasur.venta_hecho WHERE region = 'R1' AND canal = 'W' AND categoria = 'Cat7' AND anio = 2025]');

DROP INDEX tiendasur.ix_vh_region_btree;
CREATE BITMAP INDEX tiendasur.bx_vh_anio ON tiendasur.venta_hecho (anio);
CREATE BITMAP INDEX tiendasur.bx_vh_region ON tiendasur.venta_hecho (region);
CREATE BITMAP INDEX tiendasur.bx_vh_canal ON tiendasur.venta_hecho (canal);
CREATE BITMAP INDEX tiendasur.bx_vh_categoria ON tiendasur.venta_hecho (categoria);
EXEC lab_tools.medir.consulta('Q14 con 4 bitmaps', q'[SELECT SUM(importe) FROM tiendasur.venta_hecho WHERE region = 'R1' AND canal = 'W' AND categoria = 'Cat7' AND anio = 2025]');

PROMPT
PROMPT ===== 7. HASH e IOT (Q15, validación de sesión por token) =====
CREATE TABLE tiendasur.sesion_heap (token CHAR(64) PRIMARY KEY, id_cliente NUMBER, caduca TIMESTAMP);
CREATE TABLE tiendasur.sesion_iot (token CHAR(64) PRIMARY KEY, id_cliente NUMBER, caduca TIMESTAMP) ORGANIZATION INDEX;
CREATE CLUSTER tiendasur.cl_sesion (token CHAR(64)) SIZE 100 SINGLE TABLE HASHKEYS 200000;
CREATE TABLE tiendasur.sesion_hash (token CHAR(64), id_cliente NUMBER, caduca TIMESTAMP) CLUSTER tiendasur.cl_sesion (token);

INSERT INTO tiendasur.sesion_heap SELECT STANDARD_HASH(TO_CHAR(LEVEL), 'SHA256'), MOD(LEVEL, 100000) + 1, SYSTIMESTAMP + MOD(LEVEL, 120) / 1440 FROM dual CONNECT BY LEVEL <= 200000;
INSERT INTO tiendasur.sesion_iot SELECT * FROM tiendasur.sesion_heap;
INSERT INTO tiendasur.sesion_hash SELECT * FROM tiendasur.sesion_heap;
COMMIT;

COLUMN tok NEW_VALUE tok NOPRINT
SELECT RAWTOHEX(STANDARD_HASH('4711', 'SHA256')) AS tok FROM dual;
EXEC lab_tools.medir.consulta('Q15 montículo + PK', q'[SELECT id_cliente FROM tiendasur.sesion_heap WHERE token = '&tok']');
EXEC lab_tools.medir.consulta('Q15 IOT', q'[SELECT id_cliente FROM tiendasur.sesion_iot WHERE token = '&tok']');
EXEC lab_tools.medir.consulta('Q15 clúster hash', q'[SELECT id_cliente FROM tiendasur.sesion_hash WHERE token = '&tok']');
EXEC lab_tools.medir.consulta('Q15 limpieza en hash', q'[SELECT COUNT(*) FROM tiendasur.sesion_hash WHERE caduca < SYSTIMESTAMP + 1/1440]');

PROMPT
PROMPT ===== 8. Tamaño y ocupación por tipo =====
SELECT s.segment_name AS index_name, i.index_type, ROUND(s.bytes / 1048576, 1) AS mb, i.leaf_blocks AS hojas
FROM dba_segments s JOIN dba_indexes i ON i.owner = s.owner AND i.index_name = s.segment_name
WHERE s.owner = 'TIENDASUR' AND i.table_name IN ('CLIENTE', 'PEDIDO') ORDER BY s.bytes DESC;

PROMPT
PROMPT ===== 9. Limpieza del experimento =====
DECLARE
  PROCEDURE quitar(p_ddl VARCHAR2) IS BEGIN EXECUTE IMMEDIATE p_ddl; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN
  quitar('DROP INDEX tiendasur.ux_cli_dni');
  quitar('DROP INDEX tiendasur.ix_ped_cli_fec');
  quitar('DROP INDEX tiendasur.ix_ped_cli_fec_cub');
  quitar('DROP INDEX tiendasur.ix_cli_upper_email');
  quitar('DROP INDEX tiendasur.ix_ped_est_fec');
  quitar('DROP INDEX tiendasur.ix_ped_pendientes');
  quitar('ALTER TABLE tiendasur.pedido DROP COLUMN fecha_pendiente');
  quitar('ALTER TABLE tiendasur.cliente DROP COLUMN dni');
  quitar('ALTER TABLE tiendasur.cliente DROP COLUMN pais');
  quitar('ALTER TABLE tiendasur.cliente DROP COLUMN ciudad');
  quitar('DROP TABLE tiendasur.venta_hecho PURGE');
  quitar('DROP TABLE tiendasur.sesion_heap PURGE');
  quitar('DROP TABLE tiendasur.sesion_iot PURGE');
  quitar('DROP TABLE tiendasur.sesion_hash');
  quitar('DROP CLUSTER tiendasur.cl_sesion');
END;
/

SELECT COUNT(*) AS indices_tiendasur FROM dba_indexes WHERE owner = 'TIENDASUR';
EXIT
