#!/usr/bin/env bash
# Genera blacklist.zip en la raiz del repositorio con el codigo listo para Elastic Beanstalk.
# Uso: bash terraform/scripts/empaquetar.sh
set -euo pipefail

cd "$(dirname "$0")/../.."

rm -f blacklist.zip
items=(Dockerfile .dockerignore application.py requirements.txt app)
[ -d .ebextensions ] && items+=(.ebextensions)

for i in "${items[@]}"; do
  [ -e "$i" ] || { echo "No se encontro '$i' en $(pwd)"; exit 1; }
done

zip -r blacklist.zip "${items[@]}" -x "*/__pycache__/*" "*.pyc"
echo "Zip creado: $(pwd)/blacklist.zip"
