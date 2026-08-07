# EIF509 · Demo Sesión 3 — PostgreSQL en Docker + Flyway

Repositorio de respaldo de la demo en vivo: **de cero a una base de datos versionada en 20 minutos**.

- Spring Boot 3.3 · Java 21 · Gradle (Groovy)
- PostgreSQL 16 en Docker Compose
- Migraciones con Flyway (`V1__esquema_inicial.sql`, `V2__datos_semilla.sql`)

## Requisitos previos

### Dependencias (macOS con Homebrew)

Si no tenés Homebrew, instalalo primero ([brew.sh](https://brew.sh)):

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Luego las dependencias de la demo:

```bash
# Obligatorias
brew install --cask docker-desktop   # Docker Desktop (contenedor de PostgreSQL)
brew install openjdk@21              # Java 21 (lo pide el toolchain de Gradle)

# Opcionales
brew install --cask dbeaver-community   # DBeaver, para mostrar las tablas con GUI
brew install gh                         # GitHub CLI, solo si vas a publicar tu propio repo
```

No hace falta instalar Gradle (el proyecto trae `gradlew`) ni psql
(se usa el que viene dentro del contenedor, vía `docker compose exec`).

### Checklist antes de correr

1. **Docker Desktop corriendo** (ícono en verde). Es el error #1 de estas demos.
   Después de instalarlo, abrilo una vez desde Aplicaciones para que arranque el daemon.
2. **`JAVA_HOME` apuntando a Java 21.** Ojo: el JDK de Homebrew no se
   registra solo en macOS, así que `/usr/libexec/java_home` no lo encuentra
   de fábrica. Registralo una única vez (pide contraseña):

   ```bash
   sudo ln -sfn /opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-21.jdk
   ```

   Y a partir de ahí, en la terminal donde vas a correr la demo
   (o en tu `~/.zshrc`):

   ```bash
   export JAVA_HOME=$(/usr/libexec/java_home -v 21)
   ```

   Alternativa sin sudo — exportar la ruta de Homebrew directa:

   ```bash
   export JAVA_HOME=/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home
   ```

   Verificá con `"$JAVA_HOME/bin/java" -version`. Sin `JAVA_HOME`,
   `./gradlew` falla con `Unable to locate a Java Runtime`.
3. **Antes de clase, corré la demo completa una vez.** Así la imagen de
   PostgreSQL ya queda descargada y Gradle deja las dependencias en caché
   (la primera corrida tarda ~2 min bajando todo; después, segundos).

## Cómo correr la demo (guion de la clase)

En la demo en vivo, V2 se escribe **después** de la primera migración, para
que `flywayMigrate` corra dos veces y aplique una migración cada vez. Como
este repo ya trae V1 y V2 juntas, el guion aparta V2 al inicio y la devuelve
a mitad de demo — así se replica exactamente el efecto de la clase:

```bash
# 0. Si ya corriste la demo antes, arrancá desde cero:
docker compose down -v   # borra el volumen: la base queda vacía

# 1. Apartar V2 (en la demo en vivo este archivo todavía no existe)
mv src/main/resources/db/migration/V2__datos_semilla.sql /tmp/

# 2. Levantar PostgreSQL 16
docker compose up -d
docker ps          # verificar que el contenedor está vivo

# 3. Aplicar la primera migración (V1: esquema)
./gradlew flywayMigrate

# 4. Verificar con psql (o DBeaver: localhost:5432, eif509 / dev / dev)
#    Las tablas existen pero cliente está vacía: solo corrió V1
docker compose exec db psql -U dev -d eif509 -c '\dt'
docker compose exec db psql -U dev -d eif509 -c 'SELECT * FROM cliente;'

# 5. "Escribir" V2: devolver el archivo de datos semilla
mv /tmp/V2__datos_semilla.sql src/main/resources/db/migration/

# 6. Migrar de nuevo: Flyway detecta que V1 ya corrió y aplica solo V2
./gradlew flywayMigrate
docker compose exec db psql -U dev -d eif509 -c 'SELECT * FROM cliente;'
docker compose exec db psql -U dev -d eif509 -c 'SELECT * FROM pedido;'
```

> **Atajo**: si solo querés comprobar que todo funciona (sin replicar el
> guion), saltate los pasos 1 y 5. El primer `flywayMigrate` aplica V1 y V2
> juntas, y el segundo solo dice `No migration necessary`.

Momento wow — mostrar la tabla de historial de Flyway:

```bash
docker compose exec db psql -U dev -d eif509 -c 'SELECT version, description, installed_on FROM flyway_schema_history;'
```

Y que las reglas protegen los datos aunque la app falle (ambos comandos
**deben dar ERROR** — ese es el punto):

```bash
# FK: rechaza pedido de cliente inexistente
docker compose exec db psql -U dev -d eif509 -c "INSERT INTO pedido (cliente_id, total) VALUES (999, 100);"
# CHECK: rechaza total negativo
docker compose exec db psql -U dev -d eif509 -c "INSERT INTO pedido (cliente_id, total) VALUES (1, -5);"
```

## Nota técnica importante (Flyway 10 + Gradle)

En Flyway 10 el soporte de cada base se separó en módulos. Para que **el plugin de
Gradle** (`./gradlew flywayMigrate`) encuentre PostgreSQL, el módulo va en el
`buildscript.classpath` del `build.gradle` — no basta con `implementation`.
Ya está resuelto en este repo; si solo se agrega `implementation`, el comando
falla con `Unsupported Database: PostgreSQL 16.x`.

## Plan B (si algo falla en clase)

| Problema | Qué hacer |
|---|---|
| `Cannot connect to the Docker daemon` | Docker Desktop no está corriendo. Abrirlo y esperar el ícono verde. |
| `Unable to locate a Java Runtime` | Falta Java o `JAVA_HOME`. Ver «Requisitos previos». |
| Puerto 5432 ocupado | Cambiar a `"5433:5432"` en el compose y `localhost:5433` en la URL de Flyway. |
| Sin internet para bajar la imagen | Este repo ya clonado + imagen descargada de previo (`docker compose pull`). |
| `migration checksum mismatch` | Se editó una V ya aplicada. En dev: `docker compose down -v` y migrar de cero. |

## Reiniciar la demo desde cero (entre ensayo y clase)

```bash
docker compose down -v   # borra el volumen: la base queda vacía
docker compose up -d
```
