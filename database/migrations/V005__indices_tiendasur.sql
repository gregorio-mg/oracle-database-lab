-- database/migrations/V005__indices_tiendasur.sql
SET FEEDBACK ON
ALTER SESSION SET CONTAINER = FREEPDB1;

WHENEVER SQLERROR EXIT SUCCESS
DECLARE n NUMBER;
BEGIN
  SELECT COUNT(*) INTO n FROM dba_indexes WHERE owner = 'TIENDASUR' AND index_name = 'UX_CLI_DNI';
  IF n > 0 THEN RAISE_APPLICATION_ERROR(-20005, 'V005 ya aplicada: UX_CLI_DNI existe'); END IF;
END;
/
WHENEVER SQLERROR EXIT SQL.SQLCODE

-- DNI en CLIENTE
DECLARE v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'CLIENTE' AND column_name = 'DNI';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.cliente ADD (dni VARCHAR2(20))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.cliente SET dni = LPAD(id_cliente, 8, ''0'') || ''L''';
    COMMIT;
  END IF;
END;
/

CREATE UNIQUE INDEX tiendasur.ux_cli_dni ON tiendasur.cliente (dni) ONLINE;
CREATE INDEX tiendasur.ix_ped_cli_fec_cub ON tiendasur.pedido (id_cliente, fecha_pedido, importe, estado, id_pedido) ONLINE;

BEGIN
  EXECUTE IMMEDIATE 'DROP INDEX tiendasur.ix_ped_cliente';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

DECLARE v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO' AND column_name = 'FECHA_PENDIENTE';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.pedido ADD (fecha_pendiente AS (CASE WHEN estado = ''P'' THEN fecha_pedido END))';
  END IF;
END;
/

CREATE INDEX tiendasur.ix_ped_pendientes ON tiendasur.pedido (fecha_pendiente) ONLINE;

DECLARE v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM dba_tab_columns WHERE owner = 'TIENDASUR' AND table_name = 'PEDIDO' AND column_name = 'CODIGO_POSTAL';
  IF v_cnt = 0 THEN
    EXECUTE IMMEDIATE 'ALTER TABLE tiendasur.pedido ADD (codigo_postal VARCHAR2(10))';
    EXECUTE IMMEDIATE 'UPDATE tiendasur.pedido SET codigo_postal = ''30001''';
    COMMIT;
  END IF;
END;
/

CREATE INDEX tiendasur.ix_ped_cp ON tiendasur.pedido (codigo_postal) ONLINE;

BEGIN
  EXECUTE IMMEDIATE 'DROP INDEX tiendasur.ix_ped_importe';
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

SET LINESIZE 150 PAGESIZE 50
COLUMN table_name FORMAT A8
COLUMN index_name FORMAT A20
SELECT table_name, index_name, uniqueness, visibility FROM dba_indexes WHERE owner = 'TIENDASUR' ORDER BY table_name, index_name;
EXIT
