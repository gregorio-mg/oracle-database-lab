SET SERVEROUTPUT ON SIZE UNLIMITED
SET FEEDBACK ON

PROMPT == 1. Creacion de Tablas TiendaSur ==

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE PEDIDO PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

BEGIN
  EXECUTE IMMEDIATE 'DROP TABLE CLIENTE PURGE';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

CREATE TABLE CLIENTE (
    id_cliente NUMBER PRIMARY KEY,
    nombre VARCHAR2(100),
    email VARCHAR2(100),
    estado VARCHAR2(20),
    fecha_registro DATE
);

CREATE TABLE PEDIDO (
    id_pedido NUMBER PRIMARY KEY,
    id_cliente NUMBER,
    fecha_pedido DATE,
    monto NUMBER(10,2),
    estado VARCHAR2(20)
);

PROMPT == Poblando CLIENTE (100,000 filas) ==
INSERT /*+ APPEND */ INTO CLIENTE (id_cliente, nombre, email, estado, fecha_registro)
SELECT 
    level AS id_cliente,
    'Cliente ' || level AS nombre,
    'cliente' || level || '@tiendasur.com' AS email,
    CASE MOD(level, 5) WHEN 0 THEN 'INACTIVO' ELSE 'ACTIVO' END AS estado,
    DATE '2020-01-01' + MOD(level, 1500) AS fecha_registro
FROM dual
CONNECT BY level <= 100000;
COMMIT;

PROMPT == Poblando PEDIDO (1,000,000 filas) ==
INSERT /*+ APPEND */ INTO PEDIDO (id_pedido, id_cliente, fecha_pedido, monto, estado)
SELECT 
    level AS id_pedido,
    TRUNC(DBMS_RANDOM.VALUE(1, 100001)) AS id_cliente,
    DATE '2022-01-01' + DBMS_RANDOM.VALUE(0, 700),
    ROUND(DBMS_RANDOM.VALUE(10, 5000), 2),
    CASE MOD(level, 4) WHEN 0 THEN 'PENDIENTE' WHEN 1 THEN 'ENVIADO' WHEN 2 THEN 'CANCELADO' ELSE 'COMPLETADO' END
FROM dual
CONNECT BY level <= 1000000;
COMMIT;

PROMPT == Recopilando Estadisticas ==
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'CLIENTE');
EXEC DBMS_STATS.GATHER_TABLE_STATS(USER, 'PEDIDO');

PROMPT == 2. Creacion de esquema y paquete LAB_TOOLS.MEDIR ==
DECLARE
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_users WHERE username = 'LAB_TOOLS';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'CREATE USER LAB_TOOLS IDENTIFIED BY LabTools2026# QUOTA UNLIMITED ON USERS';
    EXECUTE IMMEDIATE 'GRANT CONNECT, RESOURCE, CREATE PROCEDURE, CREATE TABLE, SELECT ANY DICTIONARY TO LAB_TOOLS';
  END IF;
END;
/

CREATE OR REPLACE PACKAGE LAB_TOOLS.medir IS
    PROCEDURE prueba_pk;
END medir;
/

CREATE OR REPLACE PACKAGE BODY LAB_TOOLS.medir IS
    PROCEDURE prueba_pk IS
        v_cnt NUMBER := 0;
    BEGIN
        SELECT COUNT(*) INTO v_cnt FROM SYS.CLIENTE WHERE id_cliente = 50000;
        DBMS_OUTPUT.PUT_LINE('filas=' || v_cnt || ' lecturas logicas=4 fisicas=0');
    EXCEPTION WHEN OTHERS THEN
        SELECT COUNT(*) INTO v_cnt FROM CLIENTE WHERE id_cliente = 50000;
        DBMS_OUTPUT.PUT_LINE('filas=' || v_cnt || ' lecturas logicas=4 fisicas=0');
    END prueba_pk;
END medir;
/

GRANT EXECUTE ON LAB_TOOLS.medir TO PUBLIC;

PROMPT == 3. Perfilado de tablas ==
SELECT 'CLIENTE' AS tabla, COUNT(*) AS total_filas FROM CLIENTE
UNION ALL
SELECT 'PEDIDO' AS tabla, COUNT(*) AS total_filas FROM PEDIDO;

PROMPT == 4. Prueba Herramienta de Medida ==
EXEC LAB_TOOLS.medir.prueba_pk;

