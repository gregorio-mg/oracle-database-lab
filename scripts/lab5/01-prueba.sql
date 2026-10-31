ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED LINESIZE 200
EXEC lab_tools.medir.consulta('prueba_pk', 'SELECT id_pedido, importe FROM tiendasur.pedido WHERE id_pedido = 4711');
