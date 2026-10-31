
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
