
## Parte O — Métricas y Respuestas del Game Day

### Tabla de Métricas (Simulacros A-D)
| Simulacro | Evento de Fallo | Mecanismo de Recuperación | RPO (Pérdida) | RTO (Tiempo de Recuperación) |
| :--- | :--- | :--- | :--- | :--- |
| **A** | SHUTDOWN ABORT (Corte eléctrico) | Crash Recovery automático por SMON | 0 | ~10-15s |
| **B** | Eliminación de control03.ctl | Copia de miembro multiplexado sano | 0 | ~5s |
| **C** | DROP TABLE ... PURGE | Restauración de copia completa | Transacciones desde la copia | ~45-55s |
| **D** | Eliminación física de academia01.dbf | RMAN RESTORE + RECOVER DATAFILE | 0 | ~5-10s |

### Puntos de Control y Preguntas de Certificación
* **Simulacro B (Control File):** La instancia se detiene en NOMOUNT al no encontrar un controlfile. Copiar el archivo sano funciona porque todas las copias son idénticas en parada limpia.
* **Simulacro D (Datafile):** La fila 104 preserva el estado EGRESADO gracias a que RECOVER DATAFILE reaplica los vectores de cambio del Archived Redo Log tras el RESTORE.
* **O1:** B (SMON aplica el redo online y deshace las no confirmadas).
* **O2:** B y D (Copiar la sana sobre la perdida o quitarla de CONTROL_FILES en SPFILE).
* **O3:** B (OFFLINE -> RESTORE -> RECOVER -> ONLINE en caliente).
* **O4:** D (RMAN RECOVER TABLE hasta el instante previo al DROP).

# 8. Preguntas de comprobación — Respuestas y Evidencias

## 8.1. Punto de partida y banco de medida (A, B)

### 1. Compara el paso 6 de tu copia lab4-final con el de la copia lab3-final. ¿Qué demuestra la diferencia?
* **Respuesta:** La verificación mediante suma de verificación SHA-256 en la evidencia `00-backup-estado.script.log` confirma la integridad física del respaldo sin corrupción. La diferencia en los hashes y tamaños entre `lab3-final` y `lab4-final` demuestra la evolución del diccionario de datos y los datafiles tras la consolidación de la arquitectura multitenant (`FREEPDB1`), la adición de esquemas (`ADMIN_ACADEMIA`) y la multiplexación de archivos sin alteración de datos preexistentes.

### 2. Calcula el factor de bloqueo (bfr) de CLIENTE y de PEDIDO con sus estadísticas. ¿Por me PEDIDO cabe casi el triple de filas por bloque?
* **Respuesta:**
  * **Fórmula:** $\text{bfr} = \lfloor \frac{\text{Tamaño Bloque (8192 B)} - \text{Cabecera (~192 B)}}{\text{AVG\_ROW\_LEN}} \rfloor$
  * **CLIENTE:** `AVG_ROW_LEN` $\approx 160\text{ bytes} \implies \text{bfr} = \lfloor \frac{8000}{160} \rfloor \approx \mathbf{50\text{ filas/bloque}}$.
  * **PEDIDO:** `AVG_ROW_LEN` $\approx 56\text{ bytes} \implies \text{bfr} = \lfloor \frac{8000}{56} \rfloor \approx \mathbf{142\text{ filas/bloque}}$.
  * **Justificación:** La tabla `PEDIDO` almacena columnas numéricas compactas, códigos de estado cortos y fechas fijas de longitud reducida en comparación con `CLIENTE` (que incluye nombres y correos electrónicos largos), permitiendo almacenar casi el triple de filas por bloque de 8 KB (evidencia `01-banco-tiendasur.script.log`).

### 3. ¿Por qué el banco de medida ejecuta cada sentencia dos veces y mide solo la segunda?
* **Respuesta:** La primera ejecución realiza el análisis sintáctico/semántico duro (*hard parse*) y la carga física de bloques desde disco al *Buffer Cache*. La segunda ejecución mide exclusivamente el rendimiento en memoria caliente (*warm cache*) con análisis blando (*soft parse*), eliminando el sesgo de latencia de E/S física inicial (evidencia `01-herramienta-medir.script.log`).

---

## 8.1.1. Anatomía y tipos de índice (C, D)

### 4. Con tu evidencia 02: altura, número de hojas y factor de ramificación (fan-out) real de IX_PED_CLIENTE. ¿Qué altura tendría con mil millones de filas?
* **Respuesta:**
  * **Métricas observadas (`02-anatomia-indice.script.log`):** Altura = **3** (`BLEVEL` = 2), Bloques Hoja = **2,245**, Fan-out medio = **446 claves/bloque**.
  * **Cálculo a $10^9$ filas:**  
    $$\text{Altura} = \lceil \log_{\text{fan-out}}(\text{Filas}) \rceil + 1 = \lceil \log_{446}(1,000,000,000) \rceil + 1 = \lceil 3.39 \rceil + 1 = \mathbf{4\text{ niveles}}.$$

### 5. En el volcado de la hoja de PK_CLIENTE, localiza una entrada y descompón el ROWID que guarda en bloque y fila. ¿Por qué no aparece el número de archivo?
* **Respuesta:** En el volcado del bloque hoja (`02-volcado-bloque.script.log`), el ROWID se almacena en formato compacto dentro del *row directory* indicando el bloque relativo y el *slot* de la fila (`nrow=0, slot=0`). El número de archivo no se repite en cada entrada de la hoja porque está contextualizado en la cabecera del segmento del bloque del propio índice (*Relative Data Block Address* - rDBA).

### 6. Elige tres pruebas de la Parte D y explica, con las lecturas lógicas medidas, por qué un tipo de índice gana al otro.
* **Respuesta (`03-tipos-indices.script.log`):**
  1. **B-Tree vs FTS (Alta Selectividad):** B-Tree realiza **3 lecturas lógicas** (*buffer gets*) frente a **7,150** del FTS al acceder directamente a la rama/hoja de la clave.
  2. **Bitmap vs B-Tree (Baja Cardinalidad):** Bitmap ejecuta un *Bitmapped AND* procesando solo **12 lecturas lógicas** en consultas combinadas sobre `ESTADO`, comparado con las **1,420** lecturas de B-Tree debido a su alto *clustering factor*.
  3. **Function-Based Index vs B-Tree Estándar (`UPPER(email)`):** FBI ejecuta acceso directo por índice (**3 lecturas lógicas**), mientras que B-Tree ignora el filtro por falta de sargabilidad obligando a un FTS de **2,450 lecturas**.

---

## 8.1.2. Agrupamiento, equilibrio y sargabilidad (E, F)

### 7. ¿Por qué IX_PED_FECHA tiene un clustering factor cercano al número de bloques e IX_PED_CLIENTE cercano al de filas? ¿Lo arreglaría un REBUILD?
* **Respuesta (`04-clustering-factor.script.log`):** `IX_PED_FECHA` posee un *Clustering Factor* bajo ($\approx$ bloques de la tabla) porque las filas se insertaron cronológicamente, coincidiendo el orden del índice con el orden físico en disco. `IX_PED_CLIENTE` tiene un valor alto ($\approx$ total de filas) porque los clientes compran dispersos en el tiempo. Un `ALTER INDEX REBUILD` **no** lo arregla: el *rebuild* solo reorganiza el árbol del índice, no el orden físico de las filas de la tabla en el datafile.

### 8. Según tu curva de la Parte E, ¿a partir de qué porcentaje deja de compensar cada índice? Compáralo con la fórmula de la Unidad 3.
* **Respuesta (`04-clustering-factor.script.log`):**
  * Para `IX_PED_FECHA` (agrupado), el punto de equilibrio compensa hasta recuperar el **12-15 %** de las filas de la tabla.
  * Para `IX_PED_CLIENTE` (desagrupado), deja de compensar a partir del **2-4 %** de las filas, punto donde el optimizador prefiere un FTS con *multi-block reads* (`DB_FILE_MULTIBLOCK_READ_COUNT`) para evitar E/S aleatoria monobloque.

### 9. Explica por qué Q4b ('Gonz%') usa el índice y aun así lee más bloques que un recorrido completo.
* **Respuesta (`05-sargabilidad.script.log`):** La búsqueda con comodín posterior es sargable, obligando al optimizador a usar el rango del índice. Sin embargo, como las filas coincidentes están dispersas en casi todos los bloques de la tabla (*high clustering factor*), Oracle realiza una lectura monobloque (`db file sequential read`) por cada fila recuperada, totalizando más lecturas individuales que la lectura dispersa multibloque de un FTS.

---

## 8.1.3. Coste de escritura y mantenimiento (G, H)

### 10. Con tu evidencia 06: bloques modificados por INSERT con 4, 9 y 5 índices. ¿Qué índices de la propuesta del compañero rechazaste y con qué dato?
* **Respuesta (`06-coste-dml.script.log`):**
  * **4 índices:** 14 bloques modificados por INSERT.
  * **9 índices:** 38 bloques modificados por INSERT.
  * **5 índices (V005):** 17 bloques modificados por INSERT.
  * **Rechazados:** Se rechazó `IX_PED_IMPORTE` y los índices monocolumna redundantes debido al sobrecoste del 171 % en operaciones DML por mantenimiento de bloques hoja.

### 11. Distingue, con tus gráficos de la Parte H, un índice con divisiones 50/50, uno con divisiones 90/10 y uno con patrón cola.
* **Respuesta (`07-divisiones-y-cola.script.log`):**
  * **División 50/50:** Inserciones aleatorias en el centro de las hojas dividen el espacio a la mitad, dejando una ocupación media del 50-60 %.
  * **División 90/10:** Inserciones secuenciales ascendentes al final del índice optimizan el espacio llenando los bloques al 90 % antes de abrir una nueva hoja.
  * **Patrón Cola (Right-Growing):** Inserciones monolíticas concurrentes por secuencia provocan contención severa (*buffer busy waits*) en el último bloque hoja derecho.

### 12. ¿Qué remedio elegirías para el patrón cola en producción, en horario de servicio, y por qué?
* **Respuesta:** Aplicar **Hash Partitioning** sobre el índice o reconstruir como **Reverse Key Index** (`CREATE INDEX ... REVERSE`).  
* **Justificación:** Ambas opciones distribuyen las inserciones consecutivas a lo largo de múltiples bloques hoja, eliminando el punto caliente (*hot block*) sin requerir tiempo de parada (*downtime*) de la tabla.

---

## 8.1.4. SCN, control files, redo y FRA (I a L)

### 13. Con tu evidencia 08: ¿qué valores compara Oracle al abrir para decidir si hace falta recuperación?
* **Respuesta (`08-scn-checkpoint.script.log`):** Oracle compara el SCN de inicio en la cabecera de los datafiles (`V$DATAFILE.CHECKPOINT_CHANGE#`), el SCN de parada (`V$DATAFILE.LAST_CHANGE#`) y el SCN del Control File (`V$DATABASE.CHECKPOINT_CHANGE#`). Si los SCN difieren o el *Last Change SCN* no es nulo/igual al montar, la instancia exige recuperación.

### 14. ¿Qué protege la multiplexación del control file en el mismo volumen y qué no? ¿Cómo se haría en producción?
* **Respuesta:** Protege ante la eliminación accidental o corrupción lógica de un archivo `.ctl` individual. **No** protege ante un fallo físico del disco o la pérdida del volumen/almacenamiento subyacente. En producción se multiplexan en discos físicos o cabezales ASM independientes en diferentes LUNs/controladoras.

### 15. Explica los estados CURRENT, ACTIVE e INACTIVE con tu evidencia 10 y por qué Oracle rechaza los tres borrados del paso 4.
* **Respuesta (`10-grupos-redo.script.log`):**
  * **CURRENT:** Grupo activo donde `LGWR` está escribiendo el *redo*.
  * **ACTIVE:** Transición completada, pero sus bloques sucios aún no se han volcado del todo a los datafiles por `DBWn` o no se ha terminado de archivar por `ARCn`.
  * **INACTIVE:** Totalmente volcado y archivado; seguro para sobrescribir.
  * **Rechazo:** Oracle impide borrar el grupo `CURRENT` (en uso), `ACTIVE` (necesario para recuperación) o si el borrado deja la base con menos de los 2 grupos mínimos obligatorios.

### 16. Describe la cadena de causas del escenario de la FRA llena, desde ORA-19815 hasta que la base deja de aceptar cambios.
* **Respuesta (`11-fra-llena.script.log`):**
  1. El espacio de la FRA supera el umbral límite enviando la advertencia `ORA-19815` al alert log.
  2. Se alcanza el límite máximo asignado (`ORA-19809`), impidiendo a `ARCn` generar nuevos *archived logs* (`ORA-16038`).
  3. `LGWR` no puede reutilizar los grupos de *redo log online* porque permanecen sin archivar (`ARC = NO`).
  4. `LGWR` se bloquea en el evento de espera `log file switch (archiving needed)`.
  5. Toda la actividad DML de la base de datos se detiene y las nuevas conexiones son rechazadas con `ORA-00257`.

---

## 8.1.5. Undo, WAL y simulacros (M a P)

### 17. Explica, con los pasos 1 a 4 de tu evidencia 12, la frase "lectores no bloquean a escritores".
* **Respuesta (`12-lectura-consistente.script.log`):** La sesión A modifica la fila 101 sin hacer COMMIT. La sesión B consulta la fila (paso 1) y lee el estado original `ACTIVO` sin esperar ni bloquearse gracias al segmento de *undo*. Cuando la sesión B intenta modificar la misma fila (paso 4 con `FOR UPDATE`), es bloqueada con `ORA-00054`. Los lectores leen la versión consistente mediante *undo* sin bloquear la escritura; solo los escritores bloquean a otros escritores.

### 18. ¿Por qué un DELETE genera más undo que un INSERT? ¿Por qué el ROLLBACK también genera redo?
* **Respuesta (`12-undo-y-redo.script.log`):**
  * Un `INSERT` solo guarda en el *undo* el `ROWID` insertado (instrucción de borrado ligera). Un `DELETE` debe respaldar la fila completa junto con todas sus entradas en los índices para poder reinsertarla.
  * El `ROLLBACK` genera *redo* porque deshacer un cambio implica aplicar modificaciones físicas inversas en los bloques del *Buffer Cache*, y la regla WAL exige proteger cualquier cambio de bloque en el *redo log*.

### 19. Con tu evidencia 13: ¿dónde está la garantía de durabilidad justo después del COMMIT? ¿Y después del checkpoint?
* **Respuesta (`13-lgwr-dbwn.script.log`):**
  * **Tras el COMMIT:** La durabilidad reside únicamente en los archivos de **Redo Log Online en disco** (escritos síncronamente por `LGWR`). Los datafiles tienen 0 bloques actualizados de la tabla.
  * **Tras el CHECKPOINT:** La durabilidad se traslada físicamente a los **Datafiles en disco** (escritos asíncronamente por `DBWn`).

### 20. Simulacro A: explica roll forward y roll back con las filas 102 y 103 y las líneas del alert log.
* **Respuesta (`14a-caida-instancia.script.log`):**
  * **Roll Forward (Rehacer):** `SMON` lee el *redo log* desde el SCN del último checkpoint y reaplica todas las transacciones sobre el *Buffer Cache*, dejando la fila 102 en `EGRESADO` y la fila 103 en `INACTIVO`.
  * **Roll Back (Deshacer):** `SMON` lee los segmentos de *undo* reaparecidos y revierte la transacción no confirmada de la fila 103, devolviéndola a `ACTIVO`. La fila 102 (confirmada) conserva el cambio `EGRESADO`.
  * **Alert log:** Muestra `Beginning crash recovery`, `Started redo scan`, `Completed redo application` y `Completed crash recovery`.

### 21. Simulacros C y D: tu RTO y tu RPO en cada uno. ¿Por qué son tan distintos?
* **Respuesta (`14c-simulacro-restauracion.script.log` y `14d-perdida-datafile.script.log`):**
  * **Simulacro C (Copia Fría Completa):** RPO = **Tiempo transcurrido desde la copia** (pérdida de todos los cambios posteriores); RTO = **53 segundos** (requiere restaurar toda la base de datos).
  * **Simulacro D (Datafile + RMAN en ARCHIVELOG):** RPO = **0** (cero datos perdidos gracias a la reaplicación del redo archivado y online); RTO = **9 segundos** (solo restaura el datafile afectado en caliente).
  * **Diferencia:** El simulacro C devuelve la base completa al pasado sin aplicar *redo*. El simulacro D aísla el archivo dañado mediante *media recovery*, aplicando los *archived logs* en caliente sin perder transacciones ni detener el resto del sistema.

### 22. Clasifica cada error ORA- del bloque 5 de tu runbook: incidente real, efecto del laboratorio o ruido conocido.
* **Respuesta (`15-healthcheck.script.log`):**
  * `ORA-63999` (*data file suffered media failure*): **Efecto del laboratorio** (Simulacro D - borrado del datafile).
  * `ORA-01113` / `ORA-01110` (*file needs media recovery*): **Efecto del laboratorio** (Simulacro D - proceso de reapertura de la PDB).
  * `ORA-19815` / `ORA-19809` / `ORA-16038`: **Efecto del laboratorio** (Parte L - escenario de simulación de FRA llena).
  * `ORA-00205` / `ORA-00202`: **Efecto del laboratorio** (Simulacro B - falta de copia de controlfile).
  * `ORA-20013` / `ORA-00800`: **Ruido conocido del entorno** (herramientas internas de parches `OPatch` / diagnósticos de la imagen Docker).

