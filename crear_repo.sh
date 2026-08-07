#!/usr/bin/env bash
# Publica este proyecto como repo en GitHub.
# Requiere: gh CLI autenticado (gh auth login) — o usar la opción manual de abajo.
set -e

REPO_NAME="eif509-demo-sesion3"

git init -b main 2>/dev/null || true
git add .
git commit -m "Demo Sesión 3: PostgreSQL en Docker + migraciones Flyway (V1 esquema, V2 semilla)" 2>/dev/null || true

if command -v gh >/dev/null 2>&1; then
  gh repo create "$REPO_NAME" --private --source=. --push
  echo "Listo: repo '$REPO_NAME' creado y push hecho."
else
  echo "gh CLI no está instalado. Opción manual:"
  echo "  1) Creá el repo vacío en https://github.com/new (nombre: $REPO_NAME)"
  echo "  2) git remote add origin git@github.com:TU_USUARIO/$REPO_NAME.git"
  echo "  3) git push -u origin main"
fi
