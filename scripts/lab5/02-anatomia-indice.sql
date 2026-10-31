WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN index_name FORMAT A20
COLUMN table_name FORMAT A10
COLUMN payload FORMAT A110
COLUMN clave_en_hexadecimal FORMAT A20
COLUMN bloque_hex FORMAT A10

ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT
PROMPT ===== 1. El diccionario: altura, hojas, claves distintas y factor de agrupamiento =====
SELECT i.table_name, i.index_name, i.uniqueness AS unico, i.blevel + 1 AS altura, i.leaf_blocks AS hojas,
       i.distinct_keys AS claves, i.num_rows AS entradas, i.clustering_factor AS cf, t.blocks AS bloques_tabla
FROM dba_indexes i JOIN dba_tables t ON t.owner = i.table_owner AND t.table_name = i.table_name
WHERE i.owner = 'TIENDASUR' ORDER BY i.table_name, i.index_name;

PROMPT
PROMPT ===== 2. Por dentro: ANALYZE INDEX ... VALIDATE STRUCTURE llena INDEX_STATS =====
DECLARE
  v_idx VARCHAR2(128);
BEGIN
  SELECT index_name INTO v_idx 
  FROM dba_indexes 
  WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO' AND index_name LIKE 'IX_PED_CLIENTE%' AND ROWNUM = 1;
  
  EXECUTE IMMEDIATE 'ANALYZE INDEX tiendasur.' || v_idx || ' VALIDATE STRUCTURE';
END;
/

SELECT name AS index_name, height AS altura, lf_rows AS entradas_hoja, lf_blks AS hojas, br_rows AS entradas_rama,
       br_blks AS ramas, ROUND(lf_rows_len / lf_rows, 1) AS bytes_por_entrada, lf_blk_len AS bytes_utiles_hoja,
       pct_used, del_lf_rows AS borradas
FROM index_stats;

DECLARE
  s index_stats%ROWTYPE; fo_real NUMBER; fo_max NUMBER; cap_hoja NUMBER; h NUMBER;
BEGIN
  SELECT * INTO s FROM index_stats;
  fo_real := (s.lf_blks + s.br_blks - 1) / s.br_blks;
  fo_max := FLOOR(s.br_blk_len / (s.br_rows_len / s.br_rows));
  cap_hoja := FLOOR(s.lf_blk_len / (s.lf_rows_len / s.lf_rows));

  DBMS_OUTPUT.PUT_LINE('Factor de ramificación real (fo) = ' || ROUND(fo_real));
  DBMS_OUTPUT.PUT_LINE('Factor de ramificación máximo = ' || fo_max);
  DBMS_OUTPUT.PUT_LINE('Entradas por hoja: medidas ' || ROUND(s.lf_rows / s.lf_blks) || ', máximo ' || cap_hoja 
                       || ' -> llenado ' || ROUND(100 * s.lf_rows / s.lf_blks / cap_hoja) || ' %');
  DBMS_OUTPUT.PUT_LINE('Altura comprobada: ' || (1 + CEIL(LN(s.lf_blks) / LN(fo_max))));

  FOR r IN (SELECT COLUMN_VALUE AS filas FROM TABLE(sys.odcinumberlist(1e6, 2e7, 1e9, 1e11))) LOOP
    h := 1 + CEIL(LN(CEIL(r.filas / cap_hoja / 0.9)) / LN(fo_max));
    DBMS_OUTPUT.PUT_LINE(' Con ' || LPAD(TO_CHAR(r.filas, 'FM999G999G999G999'), 15) || ' filas -> '
                         || LPAD(CEIL(r.filas / cap_hoja / 0.9), 9) || ' hojas -> altura ' || h || ' -> ' || (h + 1)
                         || ' lecturas para encontrar UNA fila');
  END LOOP;
END;
/

PROMPT
PROMPT ===== 3. El entorno de medida: lo que cuesta DE VERDAD una búsqueda =====
SET SERVEROUTPUT OFF
SELECT /*+ GATHER_PLAN_STATISTICS */ id_pedido, importe FROM tiendasur.pedido WHERE id_pedido = 4711;
SELECT /*+ GATHER_PLAN_STATISTICS */ id_pedido, importe FROM tiendasur.pedido WHERE id_pedido = 4711;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT => 'IOSTATS LAST'));

SELECT /*+ GATHER_PLAN_STATISTICS */ id_pedido FROM tiendasur.pedido WHERE id_pedido = 4711;
SELECT plan_table_output FROM TABLE(DBMS_XPLAN.DISPLAY_CURSOR(FORMAT => 'IOSTATS LAST -PREDICATE')) WHERE plan_table_output LIKE '|%';

SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT
PROMPT ===== 4. Raíz, rama y hoja: volcado real del índice PK de CLIENTE =====
DECLARE
  v_oid NUMBER;
  v_f NUMBER;
  v_tf VARCHAR2(512);
  v_raiz NUMBER;
  v_hoja1 NUMBER;
BEGIN
  SELECT o.object_id, s.header_file
  INTO v_oid, v_f
  FROM dba_indexes i
  JOIN dba_objects o ON o.owner = i.owner AND o.object_name = i.index_name AND o.object_type = 'INDEX'
  JOIN dba_segments s ON s.owner = i.owner AND s.segment_name = i.index_name
  WHERE i.owner = 'TIENDASUR' 
    AND i.table_name = 'CLIENTE'
    AND i.index_name NOT LIKE 'UX_%'
    AND ROWNUM = 1;

  EXECUTE IMMEDIATE 'ALTER SESSION SET tracefile_identifier = ''lab5_indice''';
  EXECUTE IMMEDIATE 'ALTER SESSION SET EVENTS ''immediate trace name treedump level ' || v_oid || '''';

  SELECT SUBSTR(value, INSTR(value, '/', -1) + 1) INTO v_tf 
  FROM v$diag_info WHERE name = 'Default Trace File';

  BEGIN
    SELECT MAX(CASE WHEN payload LIKE '%branch: 0x%' THEN TO_NUMBER(REGEXP_SUBSTR(payload, 'branch: 0x[0-9a-f]+ ([0-9]+)', 1, 1, NULL, 1)) END),
           MIN(CASE WHEN payload LIKE '%leaf: 0x%' AND payload LIKE '%(-1:%' THEN TO_NUMBER(REGEXP_SUBSTR(payload, 'leaf: 0x[0-9a-f]+ ([0-9]+)', 1, 1, NULL, 1)) END)
    INTO v_raiz, v_hoja1
    FROM v$diag_trace_file_contents 
    WHERE trace_filename = v_tf AND (payload LIKE '%branch: 0x%' OR payload LIKE '%leaf: 0x%');
  EXCEPTION
    WHEN OTHERS THEN NULL;
  END;

  IF v_raiz IS NOT NULL THEN
    EXECUTE IMMEDIATE 'ALTER SYSTEM DUMP DATAFILE ' || v_f || ' BLOCK ' || v_raiz;
  END IF;
  IF v_hoja1 IS NOT NULL THEN
    EXECUTE IMMEDIATE 'ALTER SYSTEM DUMP DATAFILE ' || v_f || ' BLOCK ' || v_hoja1;
  END IF;

  DBMS_OUTPUT.PUT_LINE('Treedump y volcados completados (Raíz bloque=' || NVL(TO_CHAR(v_raiz), 'N/A') || ', Hoja bloque=' || NVL(TO_CHAR(v_hoja1), 'N/A') || ')');
EXCEPTION
  WHEN OTHERS THEN
    DBMS_OUTPUT.PUT_LINE('Aviso en volcado: ' || SQLERRM);
END;
/

PROMPT
PROMPT ===== Comprobación ROWID y clave =====
SELECT id_cliente, DUMP(id_cliente, 16) AS clave_en_hexadecimal,
       DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE') AS bloque,
       TO_CHAR(DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID, 'BIGFILE'), 'FM0XXXXXXX') AS bloque_hex,
       DBMS_ROWID.ROWID_ROW_NUMBER(ROWID) AS ranura
FROM tiendasur.cliente WHERE id_cliente = 1;

EXIT
