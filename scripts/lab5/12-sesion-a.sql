-- scripts/lab5/12-sesion-a.sql — SESIÓN A: modifica la fila 101 y mantiene la transacción abierta
SET FEEDBACK ON LINESIZE 140
ALTER SESSION SET CONTAINER = FREEPDB1;

-- Asegurar la existencia de la tabla y la fila 101 para la prueba
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_tables WHERE owner = 'ADMIN_ACADEMIA' AND table_name = 'ACA_ESTUDIANTES';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'CREATE TABLE admin_academia.aca_estudiantes (estudiante_id NUMBER PRIMARY KEY, estado VARCHAR2(20))';
    EXECUTE IMMEDIATE 'INSERT INTO admin_academia.aca_estudiantes VALUES (101, ''ACTIVO'')';
    COMMIT;
  END IF;
  
  SELECT COUNT(*) INTO v_cnt FROM admin_academia.aca_estudiantes WHERE estudiante_id = 101;
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'INSERT INTO admin_academia.aca_estudiantes VALUES (101, ''ACTIVO'')';
    COMMIT;
  END IF;
END;
/

PROMPT [A] UPDATE de la fila 101 a EGRESADO, sin COMMIT todavía
UPDATE admin_academia.aca_estudiantes SET estado = 'EGRESADO' WHERE estudiante_id = 101;
EXEC DBMS_SESSION.SLEEP(25);
COMMIT;
PROMPT [A] COMMIT hecho
EXIT
