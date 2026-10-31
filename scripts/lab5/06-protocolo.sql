WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 200 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN index_name FORMAT A16
COLUMN redundante FORMAT A16
COLUMN cubierto_por FORMAT A16
COLUMN columnas FORMAT A44
COLUMN columnas_del_otro FORMAT A44
COLUMN veredicto FORMAT A72
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

PROMPT
PROMPT ===== Pregunta 1 · NECESIDAD: Monitoreo de uso =====
BEGIN
  FOR i IN (SELECT index_name FROM dba_indexes WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO' AND index_name <> 'PK_PEDIDO') LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX tiendasur.' || i.index_name || ' MONITORING USAGE';
  END LOOP;
END;
/

EXEC lab_tools.medir.consulta('Q2 último mes', q'[SELECT id_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido >= CURRENT_DATE - INTERVAL '30' DAY]');
EXEC lab_tools.medir.consulta('Q3 código postal', q'[SELECT id_pedido, estado FROM tiendasur.pedido WHERE codigo_postal = '30001']');
EXEC lab_tools.medir.consulta('Q7 historial', q'[SELECT id_pedido, fecha_pedido, importe, estado FROM tiendasur.pedido WHERE id_cliente = 4711 AND fecha_pedido >= SYSDATE - 365 ORDER BY fecha_pedido DESC]');
EXEC lab_tools.medir.consulta('Q8 contador', q'[SELECT COUNT(*) FROM tiendasur.pedido WHERE fecha_pedido >= TRUNC(SYSDATE, 'YYYY')]');
EXEC lab_tools.medir.consulta('Q9 últimos 20', q'[SELECT * FROM tiendasur.pedido ORDER BY fecha_pedido DESC FETCH FIRST 20 ROWS ONLY]');
EXEC lab_tools.medir.consulta('Q12 pendientes', q'[SELECT id_pedido, id_cliente, fecha_pedido FROM tiendasur.pedido WHERE estado = 'P' ORDER BY fecha_pedido]');

SELECT index_name, used AS usado, monitoring FROM dba_object_usage WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO' ORDER BY used, index_name;

BEGIN
  FOR i IN (SELECT index_name FROM dba_object_usage WHERE owner = 'TIENDASUR' AND monitoring = 'YES') LOOP
    EXECUTE IMMEDIATE 'ALTER INDEX tiendasur.' || i.index_name || ' NOMONITORING USAGE';
  END LOOP;
END;
/

PROMPT
PROMPT ===== Pregunta 2 · VIABILIDAD: Selectividad =====
SELECT i.index_name, i.distinct_keys AS claves, ROUND(100 / GREATEST(i.distinct_keys, 1), 3) AS pct_por_valor_medio,
CASE WHEN 100 / GREATEST(i.distinct_keys, 1) > 0.5 THEN 'NO viable para igualdad: cada valor es más del 0,5 % de la tabla'
     ELSE 'viable' END AS veredicto
FROM dba_indexes i WHERE i.owner = 'TIENDASUR' AND i.table_name = 'PEDIDO' ORDER BY i.distinct_keys;

PROMPT
PROMPT ===== Pregunta 4 · REDUNDANCIA =====
WITH c AS (
  SELECT i.index_name, i.table_name, i.uniqueness,
         LISTAGG(c.column_name, ', ') WITHIN GROUP (ORDER BY c.column_position) AS cols
  FROM dba_indexes i JOIN dba_ind_columns c ON c.index_owner = i.owner AND c.index_name = i.index_name
  WHERE i.owner = 'TIENDASUR' GROUP BY i.index_name, i.table_name, i.uniqueness
)
SELECT a.index_name AS redundante, a.cols AS columnas, b.index_name AS cubierto_por, b.cols AS columnas_del_otro
FROM c a JOIN c b ON b.table_name = a.table_name AND b.index_name <> a.index_name AND b.cols LIKE a.cols || ', %'
WHERE a.uniqueness = 'NONUNIQUE' ORDER BY 1;

PROMPT
PROMPT ===== Pregunta 5 · CICLO DE VIDA: Hacer INVISIBLE antes de borrar =====
BEGIN
  EXECUTE IMMEDIATE 'ALTER INDEX tiendasur.ix_ped_importe INVISIBLE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/
SELECT index_name, visibility, status FROM dba_indexes WHERE owner = 'TIENDASUR' AND index_name = 'IX_PED_IMPORTE';
EXEC lab_tools.medir.consulta('Q2 sin ix_ped_importe', q'[SELECT id_pedido, importe FROM tiendasur.pedido WHERE fecha_pedido >= CURRENT_DATE - INTERVAL '30' DAY]');
EXIT
