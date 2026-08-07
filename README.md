# EIF509 · Demo Sesión 3 — PostgreSQL en Docker + Flyway

Repositorio de respaldo de la demo en vivo: **de cero a una base de datos versionada en 20 minutos**.

- Spring Boot 3.3 · Java 21 · Gradle (Groovy)
- PostgreSQL 16 en Docker Compose
- Migraciones con Flyway (`V1__esquema_inicial.sql`, `V2__datos_semilla.sql`)

## Cómo correr la demo completa

```bash
# 1. Levantar PostgreSQL 16
docker compose up -d
docker ps          # verificar que el contenedor está vivo

# 2. Aplicar la primera migración (V1: esquema)
./gradlew flywayMigrate

# 3. Verificar con psql (o DBeaver: localhost:5432, eif509 / dev / dev)
docker compose exec db psql -U dev -d eif509 -c '\dt'
docker compose exec db psql -U dev -d eif509 -c 'SELECT * FROM cliente;'

# 4. V2 ya está en el repo: al correr flywayMigrate de nuevo,
#    Flyway detecta que V1 ya se aplicó y ejecuta solo V2
./gradlew flywayMigrate
docker compose exec db psql -U dev -d eif509 -c 'SELECT * FROM pedido;'
```

Momento wow — mostrar la tabla de historial de Flyway:

```bash
docker compose exec db psql -U dev -d eif509 -c 'SELECT version, description, installed_on FROM flyway_schema_history;'
```

Y que las reglas protegen los datos aunque la app falle:

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
| Puerto 5432 ocupado | Cambiar a `"5433:5432"` en el compose y `localhost:5433` en la URL de Flyway. |
| Sin internet para bajar la imagen | Este repo ya clonado + imagen descargada de previo (`docker compose pull`). |
| `migration checksum mismatch` | Se editó una V ya aplicada. En dev: `docker compose down -v` y migrar de cero. |

## Reiniciar la demo desde cero (entre ensayo y clase)

```bash
docker compose down -v   # borra el volumen: la base queda vacía
docker compose up -d
```
