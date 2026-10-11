#!/usr/bin/env bash
# scripts/deployment/env/03-descargar-imagen-oracle.sh
echo "== Descargando la imagen oficial de Oracle Database Free =="
echo "Imagen objetivo: $IMG"
docker pull "$IMG"
echo
echo "== Huella digital de la imagen (digest sha256) =="
docker image inspect --format='{{index .RepoDigests 0}}' "$IMG"
echo
echo "== Tamaño real en disco =="
docker image inspect --format='{{.Size}} bytes' "$IMG" | awk '{print $1/1024/1024/1024 " GB"}'
