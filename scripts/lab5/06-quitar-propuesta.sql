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
EXIT
