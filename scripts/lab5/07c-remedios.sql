-- scripts/lab5/07c-remedios.sql — comparación entre COALESCE, SHRINK SPACE y REBUILD
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 170 PAGESIZE 100 FEEDBACK OFF VERIFY OFF TAB OFF
COLUMN paso FORMAT A34
ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED

CREATE TABLE lab5_pruebas.medidas (paso VARCHAR2(34), hojas NUMBER, borradas NUMBER, mb_segmento NUMBER, lecturas_siguiente NUMBER);

DECLARE
  PROCEDURE medir(p VARCHAR2) IS 
    h NUMBER; d NUMBER; mb NUMBER; lr NUMBER; v NUMBER;
    FUNCTION estad RETURN NUMBER IS x NUMBER;
    BEGIN 
      SELECT m.value INTO x FROM v$mystat m JOIN v$statname s ON s.statistic# = m.statistic# WHERE s.name = 'session logical reads'; 
      RETURN x; 
    END;
  BEGIN
    EXECUTE IMMEDIATE 'ANALYZE INDEX lab5_pruebas.ix_cola VALIDATE STRUCTURE';
    SELECT lf_blks, del_lf_rows INTO h, d FROM index_stats;
    SELECT ROUND(bytes / 1048576, 2) INTO mb FROM dba_segments WHERE owner = 'LAB5_PRUEBAS' AND segment_name = 'IX_COLA';
    SELECT id INTO v FROM lab5_pruebas.cola ORDER BY id FETCH FIRST 1 ROWS ONLY;
    lr := estad; 
    SELECT id INTO v FROM lab5_pruebas.cola ORDER BY id FETCH FIRST 1 ROWS ONLY; 
    lr := estad - lr;
    INSERT INTO lab5_pruebas.medidas VALUES (p, h, d, mb, lr); 
    COMMIT;
  END;
BEGIN
  medir('0. cola degradada');
  EXECUTE IMMEDIATE 'ALTER INDEX lab5_pruebas.ix_cola COALESCE';
  medir('1. tras COALESCE');
  EXECUTE IMMEDIATE 'ALTER INDEX lab5_pruebas.ix_cola SHRINK SPACE';
  medir('2. tras SHRINK SPACE');
  EXECUTE IMMEDIATE 'ALTER INDEX lab5_pruebas.ix_cola REBUILD ONLINE';
  medir('3. tras REBUILD ONLINE');
END;
/

PROMPT
PROMPT ===== Remedios para el patrón cola =====
SELECT paso, hojas, borradas, mb_segmento, lecturas_siguiente AS lecturas_siguiente_mensaje 
FROM lab5_pruebas.medidas ORDER BY paso;
EXIT
