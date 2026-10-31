# Runbook: Recuperación por Fallo de Medios en Datafile de PDB

## 1. Síntomas
- Errores de aplicación: `ORA-01116`, `ORA-01110`, `ORA-27041` (No such file or directory).
- Aislamiento automático de la PDB en Alert Log: `ORA-63999: data file suffered media failure`.

## 2. Diagnóstico Previo
1. Verificar estado del modo de archivado y PDB:
   ```sql
   SELECT log_mode FROM v$database;
   SELECT name, open_mode FROM v$pdbs WHERE name = 'FREEPDB1';
mkdir -p scripts/lab5 docs/runbooks

# 1.1 Crear scripts/lab5/14a-caida-instancia.sh
cat <<'EOF' > scripts/lab5/14a-caida-instancia.sh
#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
sql() { docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba; }

echo "== 1. Preparar transacciones confirmada y no confirmada =="
sql <<'SQL'
SET FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;

DECLARE v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_tables WHERE owner = 'ADMIN_ACADEMIA' AND table_name = 'ACA_ESTUDIANTES';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE admin_academia.aca_estudiantes (estudiante_id NUMBER PRIMARY KEY, estado VARCHAR2(20))';
    EXECUTE IMMEDIATE 'INSERT INTO admin_academia.aca_estudiantes VALUES (102, ''ACTIVO'')';
    EXECUTE IMMEDIATE 'INSERT INTO admin_academia.aca_estudiantes VALUES (103, ''ACTIVO'')';
    COMMIT;
  END IF;
END;
/

UPDATE admin_academia.aca_estudiantes SET estado = 'EGRESADO' WHERE estudiante_id = 102;
COMMIT;
UPDATE admin_academia.aca_estudiantes SET estado = 'INACTIVO' WHERE estudiante_id = 103;
PROMPT 102 -> EGRESADO (confirmado) | 103 -> INACTIVO (sin confirmar) -> SHUTDOWN ABORT
ALTER SESSION SET CONTAINER = CDB$ROOT;
SHUTDOWN ABORT
SQL

echo "== 2. Arranque normal: Crash Recovery automático =="
printf "STARTUP\nEXIT\n" | sql
bash scripts/ops/esperar-healthy.sh

echo "== 3. Verificación de atomicidad y durabilidad =="
sql <<'SQL'
SET FEEDBACK OFF
ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT estudiante_id, estado FROM admin_academia.aca_estudiantes WHERE estudiante_id IN (102, 103) ORDER BY 1;
UPDATE admin_academia.aca_estudiantes SET estado = 'ACTIVO' WHERE estudiante_id = 102;
COMMIT;
SQL

echo "== 4. Registro en el Alert Log =="
docker exec "$CONT_NAME" bash -c 'tail -n 400 /opt/oracle/diag/rdbms/*/*/trace/alert_*.log' \
  | grep -E 'Shutting down .*\(abort\)|shutdown \(abort\)|Beginning crash recovery|Recovery starting at|redo scan|need recovery|redo application|Completed crash recovery|opened at log sequence' \
  | tail -12
