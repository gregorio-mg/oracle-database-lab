#!/usr/bin/env bash
# scripts/deployment/env/04-desplegar-oracle.sh

echo "== Verificando si existe el contenedor '$CONT_NAME' =="
if docker ps -a --format '{{.Names}}' | grep -q "^${CONT_NAME}$"; then
  echo "El contenedor '$CONT_NAME' ya existe. Si deseas recrearlo, elimínalo primero con:"
  echo "  docker rm -f $CONT_NAME"
  exit 1
fi

echo "== Creando el volumen de persistencia '$VOL_NAME' (si no existe) =="
docker volume create "$VOL_NAME"

echo "== Desplegando el contenedor '$CONT_NAME' =="
docker run -d \
  --name "$CONT_NAME" \
  -p ${PORT_DB}:1521 \
  -p ${PORT_ORDS}:8181 \
  -e ORACLE_PWD="$ORACLE_PWD" \
  -v "$VOL_NAME":/opt/oracle/oradata \
  "$IMG"

echo "== Contenedor creado. Verifica su estado con: docker ps =="
