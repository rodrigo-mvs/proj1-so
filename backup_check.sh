#!/bin/bash
# Diretórios de origem e destino (substitua pelos seus diretórios)
SRC_DIR="$1"
DEST_DIR="$2"

# Itera sobre todos os arquivos no diretório de origem
for FILE in "$SRC_DIR"/*; do
    # Obtém o nome do arquivo sem o caminho
    FILENAME=$(basename "$FILE")
    # Construi o caminho completo para o arquivo no diretório de destino
    DEST_FILE="$DEST_DIR/$FILENAME"

    # Verifica se o arquivo existe no diretório de destino
    if [[ -f "$DEST_FILE" ]]; then
        
      SRC_FILE="$FILE"

      # Calcula os hashes MD5 dos dois arquivos
      SRC_HASH=$(md5sum "$SRC_FILE" | cut -d' ' -f1)
      DEST_HASH=$(md5sum "$DEST_FILE" | cut -d' ' -f1)

      # Compara os hashes e imprime a mensagem de erro se forem diferentes
      if [[ "$SRC_HASH" != "$DEST_HASH" ]]; then
          echo "$SRC_FILE $DEST_FILE são diferentes."
      fi

    fi
done