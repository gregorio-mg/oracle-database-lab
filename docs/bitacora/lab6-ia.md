He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E046

<!--
CÓMO SE RELLENA (léelo y borra este comentario si quieres; el script de evaluación lo ignora)
- La PRIMERA línea es obligatoria y no se toca: «He leído la política de uso de IA de la asignatura.»
- Copia este archivo como docs/bitacora/lab6-ia.md (junto a lab6-respuestas.md) y pon tu código en el título.
  Cada laboratorio tiene el suyo: en el Lab 7 será docs/bitacora/lab7-ia.md.
- Si NO has usado IA: deja solo la línea «No he usado IA.» y borra la entrada de ejemplo.
- Si la has usado: borra la línea «No he usado IA.» y escribe UNA entrada por cada uso, con los 7 campos.
  Un campo vacío es una entrada incompleta (D3: −0,5 por entrada).
- Preguntar a la IA como tutor o corregir la ortografía de un texto propio está permitido: decláralo también.
  Si no copiaste código, escribe «no aplica» en «Código recibido» y en «Evidencia de ejecución» (no cuentan como vacíos).
  Los demás campos son siempre obligatorios.
- Una entrada con TODOS los campos vacíos (la de ejemplo sin tocar) no cuenta: se ignora.
- El código copiado de una IA puntúa si lo EJECUTAS en tu contenedor, lo EXPLICAS con tus palabras,
  dices para qué lo usaste y adjuntas aquí el código y el prompt LITERAL.
-->

No he usado IA.

## Entrada 1
- **Herramienta:** 
- **Prompt (literal, copiado tal cual):**
```text

```
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
```sql

```
- **Dónde lo usé (parte, script o pregunta): script** 
- **Propósito (para qué lo necesitaba): Lo use a modo de arnes ante algun posible fallo o malineterpretacion en algun tramo** 
- **Qué hace (con mis palabras; línea a línea si es SQL corto):No genera código ni ejecuta consultas por mí; actúa como guía de verificación para interpretar vistas de diagnóstico como V$SESSION o V$LOCK, confirmar que la intervención aplicada (como ALTER SYSTEM KILL SESSION '59,56880' IMMEDIATE;, que cierra la sesión bloqueante y deshace su transacción al instante) es la mínima necesaria, y localizar datos concretos dentro de mis propios logs.** 
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):docs/bitacora/lab6/evidencia/script/20261125T183938Z_08-diagnostico.script.log y docs/bitacora/lab6/evidencia/script/20261125T185127Z_09-verificacion-final.script.log** 
