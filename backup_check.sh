#!/bin/bash

# Diretórios de origem e destino
SRC_DIR="$1"
DEST_DIR="$2"

# Verifica se o diretório de origem existe
if [[ ! -d "$SRC_DIR" ]]; then
  echo "Diretório de origem não existe: $SRC_DIR"
  exit 1
fi

# Verifica se o diretório de destino existe
if [[ ! -d "$DEST_DIR" ]]; then
  echo "Diretório de destino não existe: $DEST_DIR"
  exit 1
fi

# Itera sobre todos os arquivos no diretório de origem
for FILE in "$SRC_DIR"/*; do

  # Construi o caminho completo para o arquivo no diretório de destino
  DEST_FILE="$DEST_DIR/$(basename "$FILE")"

  # Verifica se o arquivo existe no diretório de destino
  if [[ -f "$DEST_FILE" ]]; then
    
    SRC_FILE="$FILE"

    # Calcula os hashes MD5 dos dois arquivos
    SRC_HASH=$(md5sum "$SRC_FILE" | cut -d' ' -f1)
    DEST_HASH=$(md5sum "$DEST_FILE" | cut -d' ' -f1)
    
    # Compara os hashes e imprime a mensagem de erro se forem diferentes
    if [[ "$SRC_HASH" != "$DEST_HASH" ]]; then
      echo ""$SRC_FILE" "$DEST_FILE" differ."
    fi

  fi

  if [[ -d "$DEST_FILE" ]]; then
    bash "$0" "$SRC_DIR/$(basename "$DEST_FILE")" "$DEST_FILE"
  fi

done