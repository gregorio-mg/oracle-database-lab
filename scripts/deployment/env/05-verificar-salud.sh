#!/usr/bin/env bash
# scripts/deployment/env/05-verificar-salud.sh

source scripts/deployment/env/00-config.sh

echo "== Estado de salud de $CONT_NAME =="
docker inspect --format='{{.State.Health.Status}}' "$CONT_NAME"

echo
echo "== Puertos mapeados =="
docker port "$CONT_NAME"
