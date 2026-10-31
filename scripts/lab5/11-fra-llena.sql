-- scripts/lab5/11-fra-llena.sql — simulación y resolución del escenario ORA-00257
WHENEVER SQLERROR CONTINUE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A30
COLUMN message_text FORMAT A100

PROMPT
PROMPT ===== 1. Espacio actual de la FRA =====
SELECT name, ROUND(space_limit / 1048576) AS limite_mb, ROUND(space_used / 1048576, 1) AS usado_mb FROM v$recovery_file_dest;

PROMPT
PROMPT ===== 2. Reducir temporalmente el límite de la FRA (2 MB) =====
ALTER SYSTEM SET db_recovery_file_dest_size = 2M SCOPE = MEMORY;

PROMPT
PROMPT ===== 3. Generar Redo y solicitar archivado (esperado ORA-16038 / ORA-19809) =====
ALTER SESSION SET CONTAINER = FREEPDB1;

DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_tables WHERE owner = 'ADMIN_ACADEMIA' AND table_name = 'ACA_ESTUDIANTES';
  IF v_cnt > 0 THEN
    EXECUTE IMMEDIATE 'UPDATE admin_academia.aca_estudiantes SET estado = estado';
  ELSE
    EXECUTE IMMEDIATE 'UPDATE tiendasur.pedido SET estado = estado WHERE ROWNUM <= 20000';
  END IF;
  COMMIT;
END;
/

ALTER SESSION SET CONTAINER = CDB$ROOT;
ALTER SYSTEM ARCHIVE LOG CURRENT;

PROMPT
PROMPT ===== 4. Diagnóstico de la guardia: alert log y grupos no archivados =====
SELECT group#, sequence#, archived, status FROM v$log ORDER BY group#;
SELECT TO_CHAR(originating_timestamp, 'HH24:MI:SS') AS hora, SUBSTR(REGEXP_SUBSTR(message_text, 'ORA-[0-9]+[^' || CHR(10) || ']*'), 1, 100) AS message_text
FROM v$diag_alert_ext
WHERE originating_timestamp > SYSTIMESTAMP - INTERVAL '5' MINUTE
  AND (message_text LIKE '%ORA-19809%' OR message_text LIKE '%ORA-19815%' OR message_text LIKE '%ORA-16038%' OR message_text LIKE '%ORA-00257%')
ORDER BY originating_timestamp FETCH FIRST 6 ROWS ONLY;

PROMPT
PROMPT ===== 5. Solución: restaurar límite de la FRA a 4 GB =====
ALTER SYSTEM SET db_recovery_file_dest_size = 4G SCOPE = MEMORY;
ALTER SYSTEM ARCHIVE LOG CURRENT;
SELECT group#, sequence#, archived, status FROM v$log ORDER BY group#;
SELECT name, ROUND(space_limit / 1048576) AS limite_mb, ROUND(space_used / 1048576, 1) AS usado_mb FROM v$recovery_file_dest;
EXIT
