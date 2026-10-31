ALTER SESSION SET CONTAINER = FREEPDB1;
DECLARE
  PROCEDURE q(p VARCHAR2) IS BEGIN EXECUTE IMMEDIATE p; EXCEPTION WHEN OTHERS THEN NULL; END;
BEGIN
  q('DROP INDEX tiendasur.ix_ped_est');
  q('DROP INDEX tiendasur.ix_ped_canal');
  q('DROP INDEX tiendasur.ix_ped_cli_fec');
  q('DROP INDEX tiendasur.ix_ped_fec_cli');
  q('DROP INDEX tiendasur.ix_ped_cp');
END;
/
CREATE INDEX tiendasur.ix_ped_est ON tiendasur.pedido (estado);
CREATE INDEX tiendasur.ix_ped_canal ON tiendasur.pedido (canal);
CREATE INDEX tiendasur.ix_ped_cli_fec ON tiendasur.pedido (id_cliente, fecha_pedido);
CREATE INDEX tiendasur.ix_ped_fec_cli ON tiendasur.pedido (fecha_pedido, id_cliente);
CREATE INDEX tiendasur.ix_ped_cp ON tiendasur.pedido (codigo_postal);
EXIT
