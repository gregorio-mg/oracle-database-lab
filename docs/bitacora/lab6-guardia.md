# Guardia operativa Lab 6 — E046

## INC-601 · Bloqueo de fila en ACA_ESTUDIANTES
- Detección: 2026-11-25T18:39:38Z · Aviso de espera al editar ficha en secretaría y consulta 08-diagnostico.
- Impacto: La sesión 215 (ANA_GARCIA, secretaría) quedó bloqueada durante más de 60 segundos sin poder actualizar la fila 101 de ACA_ESTUDIANTES.
- Diagnóstico: En V$SESSION y V$LOCK (08-diagnostico) la sesión 59 (serial 56880, APP_ACADEMIA, módulo matriculas) retenía el bloqueo TX exclusivo (LMODE=6, BLOCK=1) con 1 bloque undo sin confirmar.
- Causa raíz: Transacción abierta en el módulo matriculas que ejecutó un UPDATE sobre ACA_ESTUDIANTES y quedó parada sin COMMIT ni ROLLBACK.
- Intervención: `ALTER SYSTEM KILL SESSION '59,56880' IMMEDIATE;` porque libera el bloqueo y deshace solo esa transacción sin afectar al resto de la PDB.
- Validación: Consulta de bloqueos a 0 filas y comprobación de que la fila 101 volvió a estado ACTIVO.
- Acción preventiva: Alertar cuando una sesión bloquee a otra más de 30 segundos y configurar timeouts de transacción en la app.

## INC-602 · Servicio academia_app parado en FREEPDB1
- Detección: 2026-11-25T18:39:38Z · Comprobación de servicios activos en 08-diagnostico.
- Impacto: La aplicación no podía abrir conexiones nuevas contra FREEPDB1 usando el servicio academia_app.
- Diagnóstico: En la vista V$ACTIVE_SERVICES (08-diagnostico) el servicio academia_app figuraba con ARRANCADO=NO en CON_ID=3.
- Causa raíz: El servicio estaba detenido y no se había guardado su estado abierto en la PDB.
- Intervención: `EXEC DBMS_SERVICE.START_SERVICE('academia_app');` y `ALTER PLUGGABLE DATABASE FREEPDB1 SAVE STATE;` en FREEPDB1, lo mínimo para levantarlo y hacerlo persistente.
- Validación: Verificación en V$ACTIVE_SERVICES (ARRANCADO=SI) y prueba de conexión de APP_ACADEMIA por localhost:1521/academia_app.
- Acción preventiva: Ejecutar SAVE STATE tras cada cambio de servicio y mantener su comprobación en validar-arranque.sql.

## INC-603 · Cuenta APP_ACADEMIA bloqueada
- Detección: 2026-11-25T18:40:06Z · Revisión de estado de cuentas en FREEPDB1 tras fallo de acceso de la aplicación.
- Impacto: Ningún proceso de la aplicación podía autenticarse con APP_ACADEMIA mientras estuvo bloqueada.
- Diagnóstico: Consulta a DBA_USERS en FREEPDB1 mostrando ACCOUNT_STATUS=LOCKED para APP_ACADEMIA.
- Causa raíz: Se superó el límite de intentos fallidos de inicio de sesión configurado en el perfil.
- Intervención: `ALTER USER app_academia ACCOUNT UNLOCK;` en FREEPDB1, acción mínima que reactiva la cuenta sin cambiar clave ni permisos.
- Validación: Comprobación en DBA_USERS (ACCOUNT_STATUS=OPEN) y conexión correcta de APP_ACADEMIA por academia_app.
- Acción preventiva: Usar un perfil propio para cuentas técnicas de servicio y monitorizar fallos de login ORA-01017 / ORA-28000.
