-- scripts/lab5/09-controlfiles-info.sql — qué guarda el control file y cuántas copias hay
WHENEVER SQLERROR EXIT FAILURE
SET LINESIZE 160 PAGESIZE 100 FEEDBACK OFF
COLUMN name FORMAT A48
COLUMN type FORMAT A28
COLUMN value FORMAT A60

PROMPT
PROMPT ===== 1. Copias del control file (multiplexación) =====
SELECT name, status, block_size, file_size_blks FROM v$controlfile;

PROMPT
PROMPT ===== 2. Qué registra: secciones con más registros ocupados =====
SELECT type, records_total, records_used FROM v$controlfile_record_section
WHERE records_used > 0 ORDER BY records_used DESC FETCH FIRST 10 ROWS ONLY;

PROMPT
PROMPT ===== 3. Cuántos días conserva registros reutilizables =====
SELECT name, value FROM v$parameter WHERE name = 'control_file_record_keep_time';

PROMPT
PROMPT ===== 4. Copia de seguridad LÓGICA del control file (script CREATE CONTROLFILE) =====
ALTER DATABASE BACKUP CONTROLFILE TO TRACE AS '/opt/oracle/oradata/FREE/controlfile_lab5.trc' REUSE;
PROMPT Creado /opt/oracle/oradata/FREE/controlfile_lab5.trc (dentro del volumen)
EXIT
