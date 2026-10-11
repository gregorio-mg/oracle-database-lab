# Respuestas al Cuestionario del Laboratorio 3

### 8.1.1. Docker

**1. ¿Qué diferencia hay entre una imagen y un contenedor? Usa como ejemplo lo que hiciste en los ejercicios G2 y G4.**
Una imagen es como la receta de cocina o la plantilla (está congelada y no cambia). El contenedor es la comida ya hecha o la máquina funcionando en tiempo real. En el ejercicio G2 solo descargamos la imagen (la plantilla), y hasta el ejercicio G4 no creamos el contenedor para poner a funcionar el programa.

**2. En el Ejercicio G5 el archivo nota.txt desapareció y en el G6 no. Explica por qué.**
En el G5 guardamos el archivo dentro del propio contenedor sin usar carpetas compartidas; al borrar el contenedor, todo lo de dentro se destruyó. En el G6 usamos un volumen (una carpeta guardada fuera del contenedor en el disco), así que aunque el contenedor se borró, el archivo se quedó a salvo en el equipo.

**3. ¿Qué diferencia hay entre docker ps y docker ps -a, y qué significa STATUS = Exited (0)?**
`docker ps` solo te muestra los contenedores que están encendidos en este preciso momento. `docker ps -a` te muestra todos, tanto los encendidos como los apagados. `STATUS = Exited (0)` significa que el contenedor se apagó solo porque ya terminó su trabajo y que lo hizo bien, sin dar ningún error (el 0 significa sin errores).

**4. En -p 8181:8181, ¿qué número corresponde a tu equipo y cuál al contenedor? ¿Qué pasaría con -p 80:8080 en el ejercicio de nginx?**
El primer número (el de la izquierda) es el puerto de mi ordenador real, y el segundo (el de la derecha) es el puerto dentro del contenedor. Si pusiéramos `-p 80:8080` en nginx, nuestro ordenador buscaría la web en el puerto 80, pero intentaría conectarse al puerto 8080 del contenedor, donde nginx no está escuchando (nginx usa el puerto 80 por defecto), por lo que no cargaría la página.

**5. ¿Por qué un contenedor de Oracle se queda en marcha y el de hello-world termina solo?**
Porque `hello-world` solo ejecuta un comando rápido que imprime un texto en pantalla y se apaga de inmediato. En cambio, Oracle enciende un servicio de base de datos que necesita quedarse abierto todo el tiempo esperando a que entren conexiones.

**6. ¿Qué es el digest de una imagen y por qué lo registramos si ya sabemos que usamos :latest?**
El digest es como la huella dactilar o el DNI único de la imagen. Registramos el digest porque la etiqueta `:latest` puede cambiar mañana si los creadores suben una versión nueva, mientras que el digest nos asegura que estamos usando exactamente la misma versión sin que cambie nada.

**7. ¿Qué comando borraría realmente los datos de Oracle? ¿Por qué docker rm oralab-26ai no lo hace?**
El comando que borraría los datos reales sería `docker volume rm <nombre_del_volumen>`. El comando `docker rm oralab-26ai` no borra los datos porque solo elimina la "caja" (el contenedor), pero los datos de la base de datos están guardados fuera, en el volumen persistente.

---

### 8.1.2. Git, organización y evidencia

**8. ¿Por qué este laboratorio se hace dentro del repositorio oracle-database-lab, con Issue, branch y Pull Request, en vez de en una carpeta aparte?**
Porque así es como se trabaja en los equipos de desarrollo reales. Usamos el Issue para saber qué hay que hacer, creamos una rama (`branch`) para trabajar sin romper la versión principal, y hacemos un Pull Request para que otros puedan revisar los cambios antes de juntarlo todo en `main`.

**9. ¿Qué diferencia hay entre source 00-config.sh y bash 00-config.sh? ¿Por qué usamos source?**
`bash 00-config.sh` abre una sub-terminal rápida, guarda las variables ahí y la cierra, por lo que las variables se borran de inmediato. Usamos `source` porque ejecuta el script dentro de nuestra propia terminal activa, dejando las variables guardadas para que las usen los siguientes comandos.

**10. Explica cada parte del nombre 20260915T091230Z_02-docker.script.log.**
- `20260915`: La fecha en formato Año-Mes-Día (15 de Septiembre de 2026).
- `T`: La letra que separa la fecha de la hora.
- `091230`: La hora exacta (09:12:30).
- `Z`: Indica que la hora está en zona horaria UTC (Zulu).
- `_02-docker`: El número de paso y el nombre de la prueba.
- `.script.log`: El tipo de archivo de registro generado por la terminal.

**11. ¿Para qué sirve .gitattributes y qué error evita?**
Sirve para indicarle a Git cómo debe tratar los saltos de línea en los archivos. Evita el error de que los scripts de Linux fallen por culpa de los caracteres invisibles de retorno de carro que añade Windows al guardar texto.

**12. ¿Por qué en este Pull Request elegimos Create a merge commit en lugar de Squash and merge?**
Elegimos `Create a merge commit` porque queremos guardar todo el historial paso a paso de lo que hicimos en cada fase del laboratorio. Si usáramos `Squash`, se juntarían todos los commits en uno solo y perderíamos el detalle de cada parte.

---

### 8.1.3. Seguridad

**13. Describe las cuatro capas de la estrategia de contraseñas (Parte D) y qué pasaría si te saltas la primera.**
- Capa 1: El archivo `.gitignore` que impide subir archivos secretos a Git.
- Capa 2: El archivo `config/.env` donde guardamos las contraseñas reales en local.
- Capa 3: El archivo `config/.env.example` que sirve de plantilla pública sin contraseñas reales.
- Capa 4: Los scripts que leen las contraseñas desde variables y no las tienen escritas a mano.
Si te saltas la primera capa, Git subirá el archivo con las contraseñas reales a GitHub y cualquier persona en internet podrá verlas.

**14. ¿Por qué no escribimos la contraseña directamente en el comando docker run, aunque el script no se suba a Git?**
Porque si la escribimos en la terminal, la contraseña se queda guardada en el historial de comandos del ordenador (`history`) y en los registros del propio Docker, pudiendo ser leída por cualquier usuario del sistema.

**15. Si descubres tu contraseña en un commit ya publicado, ¿basta con borrarla en un commit nuevo? ¿Qué debes hacer?**
No basta con hacer un commit nuevo borrándola, porque Git guarda el historial antiguo para siempre y cualquiera podría ver la contraseña revisando los commits pasados. Lo que hay que hacer es cambiar la contraseña en la base de datos de inmediato y limpiar el historial de Git para eliminar el rastro del commit.

---

### 8.1.4. Oracle y herramientas

**16. ¿Por qué no usamos SPOOL ni @archivo.sql con sqlplus dentro del contenedor, y qué hicimos en su lugar?**
Porque dentro del contenedor no tenemos acceso fácil a las carpetas de nuestro ordenador para guardar los archivos de log. En su lugar, ejecutamos las herramientas SQL desde nuestra consola de Linux conectándonos a la base de datos del contenedor por red.

**17. ¿Qué hace WHENEVER SQLERROR EXIT SQL.SQLCODE al inicio de V000 y V001, y qué pasaría sin esa línea?**
Hace que si ocurre cualquier fallo durante la ejecución de las instrucciones SQL, el script se detenga de inmediato y avise del error. Sin esa línea, si falla una instrucción, el script seguiría ejecutando las siguientes órdenes a ciegas como si nada hubiera pasado.

**18. ¿Qué es una migración y por qué V000 y V001 no se deben editar una vez aplicadas?**
Una migración es un script de base de datos que aplica cambios de forma ordenada y versionada. No se deben editar una vez aplicadas porque romperían la coherencia entre el entorno de pruebas y el de producción; si se quiere hacer un cambio nuevo, hay que crear un archivo de migración distinto (`V002`).

**19. ¿Por qué en SQL Developer se usa el servicio FREEPDB1 y no FREE ni un SID?**
Porque `FREE` es la base de datos contenedora principal que administra el sistema de Oracle, mientras que `FREEPDB1` es la base de datos ejecutable (Pluggable Database) asignada a los usuarios para crear sus tablas y trabajar.

**20. ¿Qué aporta SQLcl frente a SQL*Plus, y por qué un DBA debe dominar ambas?**
SQLcl aporta comodidades modernas como coloreado de código, autocompletado y comandos fáciles para exportar a formatos como CSV o JSON. Un DBA debe dominar ambas porque SQL*Plus viene siempre instalado por defecto en cualquier servidor antiguo o básico, mientras que SQLcl requiere tener Java instalado.

---

### 8.1.5. Entorno de trabajo

**21. ¿Por qué el curso pasa de Git Bash a Ubuntu en WSL 2? Da al menos dos problemas concretos de Git Bash que desaparecen en Ubuntu.**
Porque Ubuntu en WSL 2 es un sistema operativo Linux completo y real, mientras que Git Bash es solo un simulador limitado. Dos problemas que desaparecen son:
1. Las fallas con las rutas de archivos que mezclan barras de Windows y de Linux.
2. La falta de compatibilidad con comandos o herramientas nativas de Linux al intentar manejar programas complejos como Docker.

**22. ¿Por qué clonamos el repositorio en ~/oracle-database-lab y no trabajamos sobre la carpeta de Windows (/mnt/c/...)? ¿Y por qué recomendamos bash frente a zsh para los scripts del curso?**
Clonamos en `~/` porque es el disco interno propio de Linux, donde la lectura y escritura de archivos es muchísimo más rápida que acceder al disco de Windows. Recomendamos `bash` porque es el estándar en casi todos los servidores Linux y garantiza que los scripts se ejecuten exactamente igual sin fallos de compatibilidad.
