#!/bin/bash

set -e  # Detener en caso de error

# Variables
WORKDIR="TD5D"
REPO_MANIFIESTOS="https://github.com/IgnacioSaAn/manifiestosTD5.git"
REPO_HTML="https://github.com/IgnacioSaAn/static-website2.git"
HTML_DIR="static-website2"
MANIF_DIR="manifiestosTD5"
MOUNT_PATH="/mnt/web"
LOCAL_MOUNT="$(pwd)/$WORKDIR/$HTML_DIR"

echo "Creando carpeta de trabajo '$WORKDIR'..."
mkdir -p "$WORKDIR"
cd "$WORKDIR"

# Clonar repositorios si no existen
[ ! -d "$MANIF_DIR" ] && git clone "$REPO_MANIFIESTOS"
[ ! -d "$HTML_DIR" ] && git clone "$REPO_HTML"

cd ..  # Volver a la raíz del proyecto

# Crear la carpeta local de montaje si no existe
mkdir -p "$LOCAL_MOUNT"

echo "Iniciando Minikube con montaje de $LOCAL_MOUNT en $MOUNT_PATH..."
minikube start --mount --mount-string="$LOCAL_MOUNT:$MOUNT_PATH"

echo "Aplicando manifiestos (excepto ingress)..."
cd "$WORKDIR/$MANIF_DIR"

# Aplicar manifiestos excepto ingress
for dir in volume service deployment; do
    if [ -d "$dir" ]; then
        echo "Aplicando manifiestos en $dir/"
        kubectl apply -f "$dir"
    else
        echo "Carpeta $dir no encontrada, se omite."
    fi
done

# Esperar a que el pod exista
while true; do
    POD_NAME=$(kubectl get pods --no-headers -o custom-columns=":metadata.name" | grep static-site | head -n 1)
    if [ -n "$POD_NAME" ]; then
        break
    fi
    echo "Esperando a que el pod 'static-site' sea creado..."
    sleep 3
done

# Esperar a que el pod esté Ready
kubectl wait --for=condition=Ready pod/"$POD_NAME" --timeout=400s

echo "Abriendo el servicio web en el navegador..."
minikube service static-site-service

