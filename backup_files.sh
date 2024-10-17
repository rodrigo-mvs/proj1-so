#!/bin/bash

# Verifica se o número de argumentos é válido
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Uso: $0 [-c] <src> <backup_dst>"
  exit 1
fi

# Verifica se a opção -c foi fornecida
if [[ "$1" == "-c" ]]; then
  CHECK_MODE="-c"
  shift
  SRC_DIR="$1"
  BACKUP_DIR="$2"
fi

# Atribui valores aos argumentos
SRC_DIR="$1"
BACKUP_DIR="$2"
CHECK_MODE=""


# Verifica se o diretório de origem existe
if [[ ! -d "$SRC_DIR" ]]; then
  echo "O diretório de origem '$SRC_DIR' não existe."
  exit 1
fi

# Cria o diretório de destino caso este não exista
mkdir -p "$BACKUP_DIR" || { echo "Erro ao criar o diretório de destino"; exit 1; }

# Percorre todos os arquivos no diretório de origem
for FILE in "$SRC_DIR"/*; do
  if [[ -f "$FILE" ]]; then
    BACKUP_FILE="$BACKUP_DIR/$(basename "$FILE")"

    if [[ ! -f "$BACKUP_FILE" || "$FILE" -nt "$BACKUP_FILE" ]]; then
      echo "cp '$FILE' '$BACKUP_FILE'"
      if [[ "$CHECK_MODE" != "-c" ]]; then
        cp "$FILE" "$BACKUP_FILE" || { echo "Erro ao copiar '$FILE'"; exit 1; }
      fi
    fi
  fi
done