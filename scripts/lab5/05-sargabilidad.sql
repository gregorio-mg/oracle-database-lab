-- scripts/lab5/05-sargabilidad.sql — reglas de sargabilidad (Ronda 1 de la Actividad 3.2)
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
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

  quitar('DROP INDEX tiendasur.ix_ped_cp');
  quitar('DROP INDEX tiendasur.ix_cli_apellidos');
  quitar('DROP INDEX tiendasur.ix_cli_telefono');
END;
/

-- Asegurar existencia de columnas necesarias
DECLARE
  v_cnt NUMBER;
BEGIN
  -- APELLIDOS
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'APELLIDOS';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.cliente ADD (apellidos VARCHAR2(100))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.cliente SET apellidos = ''Gonzalez '' || id_cliente';
  END IF;

  -- TELEFONO
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'TELEFONO';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.cliente ADD (telefono VARCHAR2(20))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.cliente SET telefono = ''600'' || LPAD(id_cliente, 6, ''0'')';
  END IF;

  -- CODIGO_POSTAL
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO' AND column_name = 'CODIGO_POSTAL';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.pedido ADD (codigo_postal VARCHAR2(10))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.pedido SET codigo_postal = ''30001''';
  END IF;

  COMMIT;
END;
/

COLUMN tel NEW_VALUE tel NOPRINT
SELECT telefono AS tel FROM tiendasur.cliente WHERE id_cliente = 4711;

CREATE INDEX tiendasur.ix_ped_cp ON tiendasur.pedido (codigo_postal);
CREATE INDEX tiendasur.ix_cli_apellidos ON tiendasur.cliente (apellidos);

PROMPT
PROMPT ===== Regla 1 · FUNCIÓN sobre la columna (Q1) =====
EXEC lab_tools.medir.consulta('Q1 rota', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE UPPER(email) = UPPER('Cliente4711@TiendaSur.es')]');
EXEC lab_tools.medir.consulta('Q1 reescrita', q'[SELECT id_cliente, nombre FROM tiendasur.cliente WHERE email = LOWER('Cliente4711@TiendaSur.es')]');

PROMPT
PROMPT ===== Regla 2 · ARITMÉTICA sobre la columna (Q2) =====
EXEC lab_tools.medir.consulta('Q2 rota', q'[SELECT id_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido + INTERVAL '30' DAY >= CURRENT_DATE]');
EXEC lab_tools.medir.consulta('Q2 reescrita', q'[SELECT id_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido >= CURRENT_DATE - INTERVAL '30' DAY]');

PROMPT
PROMPT ===== Regla 3 · CONVERSIÓN IMPLÍCITA de tipos (Q3) =====
EXEC lab_tools.medir.consulta('Q3 rota', q'[SELECT id_pedido, estado FROM tiendasur.pedido WHERE codigo_postal = 30001]');
EXEC lab_tools.medir.consulta('Q3 reescrita', q'[SELECT id_pedido, estado FROM tiendasur.pedido WHERE codigo_postal = '30001']');

SET SERVEROUTPUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS */ COUNT(estado) FROM tiendasur.pedido WHERE codigo_postal = 30001;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT => 'BASIC +PREDICATE')) WHERE plan_table_output LIKE '%filter%' OR plan_table_output LIKE '%access%';
SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT
PROMPT ===== Regla 4 · COMODÍN a la izquierda (Q4) =====
EXEC lab_tools.medir.consulta('Q4a LIKE %ez', q'[SELECT * FROM tiendasur.cliente WHERE apellidos LIKE '%ez']');
EXEC lab_tools.medir.consulta('Q4b LIKE Gonz%', q'[SELECT * FROM tiendasur.cliente WHERE apellidos LIKE 'Gonz%']');

PROMPT
PROMPT ===== Regla 5 · OR con una columna SIN índice (Q5) =====
EXEC lab_tools.medir.consulta('Q5 OR sin índice en tel.', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' OR telefono = '&tel']');
CREATE INDEX tiendasur.ix_cli_telefono ON tiendasur.cliente (telefono);
EXEC lab_tools.medir.consulta('Q5 OR con los dos índices', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' OR telefono = '&tel']');
EXEC lab_tools.medir.consulta('Q5 como UNION', q'[SELECT * FROM tiendasur.cliente WHERE email = '&tel' UNION SELECT * FROM tiendasur.cliente WHERE telefono = '&tel']');

PROMPT
PROMPT ===== Bonus · Q11: reescribir bien no obliga a usar el índice =====
EXEC lab_tools.medir.consulta('Q11 rota (EXTRACT)', q'[SELECT SUM(importe) FROM tiendasur.pedido WHERE EXTRACT(YEAR FROM fecha_pedido) = 2025]');
EXEC lab_tools.medir.consulta('Q11 reescrita (rango)', q'[SELECT SUM(importe) FROM tiendasur.pedido WHERE fecha_pedido >= DATE '2025-01-01' AND fecha_pedido < DATE '2026-01-01']');

PROMPT
PROMPT ===== Limpieza de índices temporales =====
DROP INDEX tiendasur.ix_ped_cp;
DROP INDEX tiendasur.ix_cli_apellidos;
DROP INDEX tiendasur.ix_cli_telefono;

SELECT COUNT(*) AS indices_tiendasur FROM dba_indexes WHERE owner = 'TIENDASUR';
EXIT
