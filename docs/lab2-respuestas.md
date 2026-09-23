1. ¿Por qué un Issue sin criterios de aceptación es un problema, aunque la descripción general parezca clara?
Sin criterios no se sabe cuándo la tarea está terminada y cada persona puede entender algo distinto. El reviewer no tiene con qué comprobar que se cumple lo pedido.

2. Explica la diferencia entre "Refs #N" y "Closes #N" en un mensaje de commit o en la descripción de un Pull Request.
`Refs #N` solo enlaza con el issue, sin cerrarlo. `Closes #N` lo cierra automáticamente cuando el PR se fusiona con main.

3. ¿Qué ocurre exactamente si intentas hacer git push directamente sobre una branch main protegida? ¿Es un error tuyo o un fallo del sistema?
GitHub rechaza el push con el error GH006 y exige hacer los cambios mediante un Pull Request. No es un fallo, es la protección funcionando como debe.


4. Un compañero te dice: "he aprobado el PR sin mirar los archivos, total ya me fío". ¿Qué riesgo tiene esa forma de revisar?
Pueden colarse bugs o errores sin que nadie los vea. La aprobación no aporta control de calidad y solo da falsa seguridad.

5. Si el reviewer pide un cambio y tú ya habías hecho push de tu branch, ¿tienes que abrir un Pull Request nuevo? Explica qué ocurre técnicamente con el PR existente cuando haces un nuevo commit.
No, se sigue en el mismo PR. Al hacer push a la misma rama, el PR se actualiza solo con el nuevo commit y el reviewer puede volver a revisar.

6. Describe con tus palabras la diferencia entre Merge commit, Squash and merge y Rebase and merge. ¿Cuál usarías para una branch con commits "wip", "fix", "fix2", "ok ya"?
Merge commit conserva todos los commits y añade uno de unión; Squash junta todo en un solo commit; Rebase los coloca en main uno tras otro sin commit de unión. Usaría Squash and merge, porque deja un único commit limpio.

7. ¿Por qué borrar una branch después del merge no elimina el trabajo realizado en ella?
Porque los commits ya están dentro de main tras el merge. Borrar la rama solo elimina el nombre (el puntero), no el contenido.

8. ¿Qué información debería contener siempre la descripción de un Pull Request, como mínimo?
Un resumen (Summary), la lista de cambios (Changes), cómo se ha probado (Testing) y el issue que cierra (`Closes #N`).

9. Un reviewer escribe solo "esto está mal" como comentario. ¿Qué le falta a ese comentario para ser útil? Reescríbelo tú con un ejemplo inventado.
Le falta decir qué está mal, dónde y cómo arreglarlo. Ejemplo: *"issue (blocking): en la línea 12 no se valida el email vacío y puede romper el registro. ¿Añadimos un `if` que lo compruebe?"*

10. ¿Qué diferencia hay entre que main esté protegida y que simplemente el equipo "se ponga de acuerdo" en no hacer push directo?
Un acuerdo depende de que todos lo cumplan y alguien puede saltárselo por error o prisa. La protección lo impide técnicamente.

11. Explica con un ejemplo propio la diferencia entre un comentario issue: (blocking) y uno nitpick: (if-minor) en formato Conventional Comments.
`issue (blocking): la función falla si la lista está vacía` se debe arreglar antes del merge. `nitpick (if-minor): renombra la variable x a total` es un detalle menor que se puede ignorar.

12. Si tu próximo commit es feat!: cambia la firma de la función principal de la API, ¿qué tipo de versión SemVer se dispara y por qué?
Una versión MAJOR (por ejemplo, de 1.4.2 a 2.0.0). El `!` indica un breaking change, ya que cambiar la firma rompe la compatibilidad con quien la usaba.

13. ¿Por qué abrir un Draft PR desde el primer commit estructural puede ahorrar tiempo al equipo, aunque parezca más lento para el autor individual?
El equipo ve el trabajo desde el principio y puede dar feedback pronto, evitando duplicar trabajo o rehacer cosas grandes al final.

