#!/bin/bash

# Evitar prompts interactivos que bloqueen la construcción
export DEBIAN_FRONTEND=noninteractive

echo "Instalando herramientas base..."

# Se recomienda usar apt-get en scripts en lugar de apt para evitar advertencias
# Se añade --no-install-recommends para no traer dependencias innecesarias
apt-get update && apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    gnupg-agent \
    software-properties-common \
    less \
    unzip \
    curl \
    wget \
    git \
    vim \
    tzdata

# Limpieza estricta para reducir el peso de la capa de Docker
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Herramientas instaladas."