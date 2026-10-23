# Respuestas del Laboratorio 4 — Administración de Instancia, Memoria y Procesos

## Preguntas tipo examen (P1 - P12)

* **P1: B** — En `SHUTDOWN IMMEDIATE` la base de datos se cierra ordenadamente ejecutando un checkpoint previo, desconectando sesiones activas y desmontando los archivos sin requerir recuperación en el próximo arranque.
* **P2: A** — En la etapa `NOMOUNT`, la instancia únicamente lee el `SPFILE`/`PFILE`, asigna la memoria global `SGA` y levanta los procesos de background.
* **P3: A, C** — `STARTUP_TIME` en `v$instance` se actualiza con cada arranque del proceso de la instancia, mientras que `CREATED` en `v$database` indica la fecha original de creación física de la base de datos en disco.
* **P4: A, C** — En estado `NOMOUNT`, la memoria SGA ya está asignada permitiendo consultar `v$parameter`, y es el estado requerido para recrear el archivo de control mediante `CREATE CONTROLFILE`.
* **P5: B** — Para cambiar el modo de registro a `ARCHIVELOG` mediante `ALTER DATABASE ARCHIVELOG`, la base de datos debe estar en estado `MOUNT` (archivos de control abiertos, pero datafiles cerrados).
* **P6: B** — Si no se especifica la cláusula `SCOPE` en un parámetro dinámico sobre una instancia iniciada con `SPFILE`, Oracle aplica por defecto `SCOPE = BOTH` (modifica memoria y archivo).
* **P7: C** — Los parámetros a nivel de instancia como `PROCESSES` no son modificables desde una Pluggable Database (PDB), devolviendo el error `ORA-65040`.
* **P8: A, C** — Para recuperar una instancia que no arranca por un `SPFILE` corrupto o con valores erróneos, se puede iniciar indicando un `PFILE` de texto válido (`STARTUP PFILE=...`) y posteriormente regenerar el binario con `CREATE SPFILE FROM PFILE=...`.
* **P9: B** — En el modelo ASMM (`SGA_TARGET > 0`), fijar `DB_CACHE_SIZE` establece un tamaño mínimo garantizado para el búfer de caché que el gestor automático no reducirá.
* **P10: A, D** — En la arquitectura de servidor dedicado, la `PGA` contiene áreas privadas de trabajo como el área de ordenación (`sort area`) y la información del estado de sesión (`UGA`).
* **P11: C** — Al ejecutar `COMMIT`, la transacción no devuelve el control al usuario hasta que el proceso `LGWR` fluye y confirma la escritura física del búfer de redo log en los archivos *online redo log*.
* **P12: B, D** — Los procesos `PMON` (monitor de procesos) y `SMON` (monitor del sistema) son indispensables para la operatividad y recuperación automática de cualquier instancia de Oracle.
