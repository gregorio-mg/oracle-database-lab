WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN index_name FORMAT A20
COLUMN table_name FORMAT A10
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT ===== 1. Diccionario de indices de TiendaSur =====
SELECT i.table_name, i.index_name, i.uniqueness AS unico, i.blevel + 1 AS altura, i.leaf_blocks AS hojas,
       i.distinct_keys AS claves, i.num_rows AS entradas, i.clustering_factor AS cf, t.blocks AS bloques_tabla
FROM dba_indexes i JOIN dba_tables t ON t.owner = i.table_owner AND t.table_name = i.table_name
WHERE i.owner = 'TIENDASUR' ORDER BY i.table_name, i.index_name;

PROMPT ===== 2. INDEX_STATS sobre IX_PED_CLIENTE =====
ANALYZE INDEX tiendasur.ix_ped_cliente VALIDATE STRUCTURE;
SELECT name AS index_name, height AS altura, lf_rows AS entradas_hoja, lf_blks AS hojas, 
       br_rows AS entradas_rama, br_blks AS ramas, ROUND(lf_rows_len / NULLIF(lf_rows,0), 1) AS bytes_por_entrada,
       lf_blk_len AS bytes_utiles_hoja, pct_used, del_lf_rows AS borradas
FROM index_stats;

DECLARE
  s index_stats%ROWTYPE;
  fo_real NUMBER;
  fo_max NUMBER;
  cap_hoja NUMBER;
BEGIN
  SELECT * INTO s FROM index_stats;
  IF s.br_blks > 0 THEN
    fo_real := (s.lf_blks + s.br_blks - 1) / s.br_blks;
    DBMS_OUTPUT.PUT_LINE('Factor de ramificacion real (fo): ' || ROUND(fo_real));
  END IF;
  IF s.br_rows > 0 THEN
    fo_max := FLOOR(s.br_blk_len / (s.br_rows_len / s.br_rows));
    DBMS_OUTPUT.PUT_LINE('Factor de ramificacion maximo: ' || fo_max);
  END IF;
  IF s.lf_blks > 0 AND s.lf_rows > 0 THEN
    cap_hoja := FLOOR(s.lf_blk_len / (s.lf_rows_len / s.lf_rows));
    DBMS_OUTPUT.PUT_LINE('Entradas por hoja: medidas ' || ROUND(s.lf_rows / s.lf_blks) || ', maximo ' || cap_hoja);
  END IF;
END;
/

PROMPT ===== 3. Medida de coste de busqueda (GATHER_PLAN_STATISTICS) =====
SET SERVEROUTPUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS */ id_pedido, importe FROM tiendasur.pedido WHERE id_pedido = 4711;
SELECT /*+ GATHER_PLAN_STATISTICS */ id_pedido, importe FROM tiendasur.pedido WHERE id_pedido = 4711;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT => 'IOSTATS LAST'));

SELECT /*+ GATHER_PLAN_STATISTICS */ id_pedido FROM tiendasur.pedido WHERE id_pedido = 4711;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT => 'IOSTATS LAST'));
SET SERVEROUTPUT ON FORMAT WRAPPED
EXIT
