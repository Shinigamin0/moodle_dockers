#!/bin/bash

# 1. Recibir y asignar los parámetros posicionales
METHOD=$1
MOODLE_VERSION=$2
MOODLE_TAG=$3

# 2. Construir las URLs usando la variable MOODLE_VERSION y el dominio correcto para el MD5
moodle_direct_link="https://download.moodle.org/download.php/direct/stable${MOODLE_VERSION}/moodle-latest-${MOODLE_VERSION}.tgz"
moodle_md5_link="https://packaging.moodle.org/stable${MOODLE_VERSION}/moodle-latest-${MOODLE_VERSION}.tgz.md5"

if [ "$METHOD" == "file" ]; then
    echo "Descargando Moodle versión ${MOODLE_VERSION}..."
    wget $moodle_direct_link -O moodle.tgz
    
    echo "Descargando archivo MD5 para validación..."
    wget $moodle_md5_link -O moodle_md5.txt
    
    # Extraer el hash calculado (formato estándar de Linux, el hash es $1)
    md5SumDownloadedFile=$(md5sum moodle.tgz | awk '{print $1}')
    
    # Extraer el hash del archivo de Moodle (formato BSD, el hash es $2)
    md5Downloaded=$(cat moodle_md5.txt | awk '{print $2}')

    # Validar que los hashes coincidan
    if [ "$md5SumDownloadedFile" == "$md5Downloaded" ]; then
        echo "Validación exitosa. Sumas MD5 concuerdan: $md5SumDownloadedFile"
        
        # Descomprimir archivos gzip (.tgz)
        tar -xzf moodle.tgz
        rm -f moodle.tgz moodle_md5.txt
        
        if [ -d ./html ]; then
            mv ./html ./html_old
        fi

        if [ -d ./moodle ] && [ ! -d ./html ]; then
            mv ./moodle ./html
            echo "Moodle instalado en el directorio html correctamente."
        else
            echo "Error: Problemas con los directorios. Valide si la descompresión fue exitosa."
            exit 1
        fi
    else
        echo "Error: Falló la comprobación de sumas MD5."
        echo "Calculado: $md5SumDownloadedFile"
        echo "Esperado:  $md5Downloaded"
        exit 1 # Detener la construcción de Docker si el archivo está corrupto
    fi

elif [ "$METHOD" == "git" ]; then
    echo "Clonando Moodle desde Git con el tag ${MOODLE_TAG}..."
    git clone git://git.moodle.org/moodle.git
    cd moodle
    git branch -a
    git branch --track ${MOODLE_TAG} origin/${MOODLE_TAG}
    git checkout ${MOODLE_TAG}
else
    echo "Error: Método no reconocido."
    echo "Uso: $0 [file|git] [moodle_version] [moodle_tag]"
    exit 1
fi