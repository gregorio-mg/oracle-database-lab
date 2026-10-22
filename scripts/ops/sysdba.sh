#!/usr/bin/env bash
set -euo pipefail
source scripts/deployment/env/00-config.sh
FILE="${1:?Uso: sysdba.sh <archivo.sql>}"
docker exec -i "$CONT_NAME" sqlplus -s -L / as sysdba < "$FILE"
