#!/bin/bash
# save as: download-lfs.sh

LFS=${LFS:-/mnt/lfs}
SOURCES_DIR="$LFS/sources"
ERROR_FILE="$SOURCES_DIR/errorDownload.txt"
WGET_LIST="wget-list-sysv"
MAX_RETRIES=3
TIMEOUT=30

# Crear directorio si no existe
mkdir -pv "$SOURCES_DIR"

# Limpiar archivo de errores anterior
> "$ERROR_FILE"

echo "Iniciando descarga de paquetes LFS..."
echo "Archivos con errores se guardarán en: $ERROR_FILE"

# Leer la lista de URLs
while IFS= read -r url; do
    if [[ -z "$url" || "$url" =~ ^# ]]; then
        continue  # Saltar líneas vacías o comentarios
    fi
    
    filename=$(basename "$url")
    echo "Descargando: $filename"
    
    # Intentar descarga con reintentos
    for ((retry=1; retry<=MAX_RETRIES; retry++)); do
        echo "Intento $retry de $MAX_RETRIES..."
        
        if wget --continue --timeout=$TIMEOUT --tries=3 --directory-prefix="$SOURCES_DIR" "$url"; then
            echo "✓ Descarga completada: $filename"
            break
        else
            echo "✗ Falló intento $retry para: $filename"
            
            if [[ $retry -eq $MAX_RETRIES ]]; then
                echo "Agregando a lista de errores: $filename"
                # Convertir http a https en el URL fallado
                https_url="${url/http:/https:}"
                echo "$https_url" >> "$ERROR_FILE"
            fi
            
            # Esperar antes del reintento
            sleep 5
        fi
    done
    echo "---"
    
done < "$WGET_LIST"

echo "Descarga completada."
if [[ -s "$ERROR_FILE" ]]; then
    echo "Archivos con errores (convertidos a HTTPS):"
    cat "$ERROR_FILE"
else
    echo "✓ Todas las descargas fueron exitosas."
fi