SET LINESIZE 160
SET PAGESIZE 100
COLUMN index_name FORMAT A25
COLUMN table_name FORMAT A15
COLUMN blevel FORMAT 9999 HEADING "BLEVEL"
COLUMN altura FORMAT 9999 HEADING "ALTURA"
COLUMN leaf_blocks FORMAT 999,999 HEADING "HOJAS"
COLUMN num_rows FORMAT 9,999,999 HEADING "FILAS"
COLUMN distinct_keys FORMAT 9,999,999 HEADING "CLAVES_DIST"
COLUMN clustering_factor FORMAT 9,999,999 HEADING "CLUST_FACT"

PROMPT == Anatomia de Indices B-Tree (CLIENTE y PEDIDO) ==

SELECT 
    index_name,
    table_name,
    blevel,
    blevel + 1 AS altura,
    leaf_blocks,
    num_rows,
    distinct_keys,
    clustering_factor
FROM user_indexes
WHERE table_name IN ('CLIENTE', 'PEDIDO')
ORDER BY table_name, index_name;
