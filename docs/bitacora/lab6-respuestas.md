# Respuestas Lab 6 — E046

## 9.1. Partes A-C · Rol operativo, parámetros y estados
1. (20261125T172840Z_01-turno.script.log) Aparecieron 10 errores ORA- en las últimas 24 h. Vienen del propio arranque de la imagen y un recuento aislado no basta para dar alarma si no se contrasta con la línea base ni se revisa qué código ORA- concreto saltó.
2. (20261125-174519_01-automatizacion.spool.log) Empieza el miércoles a las 22:00 y dura 4 horas. Se ejecutan auto optimizer stats collection, auto space advisor y sql tuning advisor.
3. (20261125T175019Z_02-parametros.script.log) Tras el cambio con SCOPE=SPFILE, V$SPPARAMETER mostraba 250 en disco mientras V$PARAMETER seguía marcando 200 en memoria porque db_files es estático. Sin RESET habría arrancado con 250 en el siguiente reinicio.
4. (20261125T175028Z_02-init_desde_spfile.ora) RESET borra la entrada del SPFILE; valía para db_files porque no figuraba en él, pero processes sí estaba guardado en la línea `*.processes=200` y quitarlo habría cambiado la configuración de arranque.
5. (20261125T175857Z_02-estados-pdb.script.log) C##OPS_RO recibió ORA-01109: database not open. El mensaje «Database opened» correspondía al CDB$ROOT, mientras que FREEPDB1 quedó en MOUNTED al no tener guardado el estado.

## 9.1.1. Partes D-E · Servicios, sesiones y diccionario
6. (20261125T180856Z_03-sesiones.script.log) La sesión tenía SID 58, SPID 4801 y evento PL/SQL lock timer. USERNAME solo indica la cuenta técnica APP_ACADEMIA, mientras que MODULE (matriculas), ACTION (cierre-periodo) y CLIENT_IDENTIFIER (ana.garcia@ucam) permiten saber qué módulo y qué persona real lanzaron la operación.
7. (20261125T180856Z_03-sesiones.script.log) Después de CANCEL SQL seguía con 1 transacción abierta (USED_UBLK = 1). Tras KILL SESSION quedó con 0 transacciones y la fila 101 volvió a su estado anterior al deshacerse el cambio.
8. (20261125T180849Z_03-cuenta-app.script.log) Está vacío, así que Oracle no exige el prefijo C## para crear usuarios comunes en este contenedor.
9. (20261125T181940Z_04-tres-miradas.script.log) Mirada 1 (C##OPS_RO en CDB$ROOT): ALL_TABLES=0, DBA_USERS=37, CDB_USERS=37/47, V$DATAFILE=16. Mirada 2 (C##OPS_RO en freepdb1): ALL_TABLES=0, DBA_USERS=47, CDB_USERS=47, V$DATAFILE=9. Mirada 3 (APP_ACADEMIA): ALL_TABLES=1, DBA_USERS y CDB_USERS dan ORA-00942. En CDB$ROOT ADMIN_ACADEMIA marca 0 tablas porque su esquema vive dentro de FREEPDB1.
10. (20261125T182513Z_04-deltas.script.log) La carga consumió 5179 lecturas lógicas por recorrido (51792 totales) y 0.56 s de DB time. Al ser DB CPU 0.39 s (casi todo el DB time), la carga estuvo limitada por CPU y apenas sufrió esperas de disco o bloqueos.

## 9.1.2. Partes F-G · Espacio y acceso
11. (20261125T182559Z_05-almacenamiento.script.log) Antes de cargar tenía 10 MB asignados, 3.9 MB libres y 40 MB de techo máximo. Para alertar usaría el máximo porque el fichero es autoextensible y seguirá creciendo hasta alcanzar los 40 MB.
12. (20261125T182559Z_05-almacenamiento.script.log) Insertó APP_ACADEMIA y consumió cuota CARGA_HIST (propietario de la tabla). Ampliar el tablespace no soluciona ORA-01536 porque el tope está en la cuota asignada al usuario, no en el tamaño del datafile.
13. (20261125T182648Z_05-resumable.script.log) Estuvo suspendida dentro del límite de 180 s hasta ampliar la cuota, dejando en el alert log los avisos `statement in resumable session 'carga-historico' was suspended due to...` y `was resumed`.
14. (20261125T182721Z_05-hwm-shrink.script.log) Antes del SHRINK ocupaba 2944 bloques y 23 MB (con 20000 filas y también tras borrar 18000), y después bajó a 2000 filas, 304 bloques y 2.4 MB. El DELETE no libera espacio porque deja intacta la marca de agua alta (HWM).
15. (20261125T183448Z_06-gobierno-acceso.script.log) El perfil DEFAULT tenía FAILED_LOGIN_ATTEMPTS=10, PASSWORD_LIFE_TIME=180, PASSWORD_LOCK_TIME=1 e INACTIVE_ACCOUNT_TIME=365. En PRF_PERSONAS para secretaría se baja FAILED_LOGIN_ATTEMPTS a 3 para cortar intentos de intrusión y se acota IDLE_TIME para cerrar sesiones abiertas sin uso.
16. (20261125T183517Z_06-probar-acceso.script.log) Ana pudo leer ACA_MATRICULAS porque heredó el SELECT a través de su rol de secretaría. Al intentar modificar el nombre saltó ORA-01031: insufficient privileges.

## 9.1.3. Partes H-I · Objetos, diagnóstico y guardia
17. (20261125T183700Z_07-objetos.script.log) Con la columna nueva no se invalidó nada por dependencia de grano fino; en el segundo cambio se invalidó solo la vista dependiente (V_CONTACTO_LAB6) y al ampliar nombres cayeron en cascada F_TOTAL_ACTIVOS_LAB6, V_ACTIVOS_LAB6 y V_CONTACTO_LAB6.
18. (20261125T183723Z_07-memoria.script.log) Según V$SGA_TARGET_ADVICE duplicar la SGA de 1536 MB a 3072 MB no mejora el DB time (ESTD_DB_TIME_FACTOR sigue en 1 y las lecturas físicas en 35233). En V$PGA_TARGET_ADVICE aparecen sobreasignaciones (OVERALLOC > 0) por debajo de 512 MB (en 384 MB hay 1 y en 256/128 MB hay 5).
19. (20261125T183803Z_07-adr-trazas.script.log) La consulta necesitó 247 lecturas lógicas, como indica la línea `total        4      0.00       0.00          0        247          0           1` (columna query).
20. (lab6-guardia.md y 20261125T183938Z_08-diagnostico.script.log) INC-601: bloqueo TX de sesión 59 sobre 215 -> KILL SESSION '59,56880' -> 0 bloqueos y fila 101 en ACTIVO. INC-602: academia_app en ARRANCADO=NO -> START_SERVICE y SAVE STATE -> servicio activo. INC-603: APP_ACADEMIA en LOCKED -> ACCOUNT UNLOCK -> cuenta en OPEN.
