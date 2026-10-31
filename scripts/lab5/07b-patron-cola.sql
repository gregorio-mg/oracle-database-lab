-- scripts/lab5/07b-patron-cola.sql — simulación del patrón cola
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN index_name FORMAT A10
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

CREATE TABLE lab5_pruebas.cola (id NUMBER NOT NULL, estado CHAR(1), carga CHAR(40));
CREATE INDEX lab5_pruebas.ix_cola ON lab5_pruebas.cola (id);

PROMPT
PROMPT ===== 1. Carga de 200k mensajes, borrado de 150k antiguos, inserción de 50k nuevos =====
BEGIN
  FOR i IN 1 .. 200000 LOOP 
    INSERT INTO lab5_pruebas.cola VALUES (i, 'N', 'mensaje'); 
    IF MOD(i, 1000) = 0 THEN COMMIT; END IF; 
  END LOOP;

  FOR i IN 1 .. 150000 LOOP 
    DELETE FROM lab5_pruebas.cola WHERE id = i; 
    IF MOD(i, 1000) = 0 THEN COMMIT; END IF; 
  END LOOP;

  FOR i IN 200001 .. 250000 LOOP 
    INSERT INTO lab5_pruebas.cola VALUES (i, 'N', 'mensaje'); 
    IF MOD(i, 1000) = 0 THEN COMMIT; END IF; 
  END LOOP;
  COMMIT;
END;
/

EXEC DBMS_STATS.GATHER_TABLE_STATS('LAB5_PRUEBAS', 'COLA', cascade => TRUE);
SELECT COUNT(*) AS mensajes_vivos, MIN(id) AS primero, MAX(id) AS ultimo FROM lab5_pruebas.cola;

PROMPT
PROMPT ===== 2. Síntoma de lentitud =====
EXEC lab_tools.medir.consulta('siguiente mensaje (cola)', 'SELECT id FROM lab5_pruebas.cola ORDER BY id FETCH FIRST 1 ROWS ONLY');
EXEC lab_tools.medir.consulta('siguiente mensaje (sano)', 'SELECT k FROM lab5_pruebas.creciente ORDER BY k FETCH FIRST 1 ROWS ONLY');

PROMPT
PROMPT ===== 3. Diagnóstico con INDEX_STATS =====
ANALYZE INDEX lab5_pruebas.ix_cola VALIDATE STRUCTURE;
SELECT name AS index_name, height AS altura, lf_blks AS hojas, lf_rows AS entradas, del_lf_rows AS borradas,
       ROUND(100 * del_lf_rows / NULLIF(lf_rows, 0)) AS pct_borradas, pct_used, ROUND(btree_space / 1048576, 1) AS mb_arbol
FROM index_stats;
EXIT
