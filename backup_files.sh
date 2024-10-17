#!/bin/bash

# Verifica se o número de argumentos é válido
if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "Uso: $0 [-c] <src> <backup_dst>"
  exit 1
fi

# Modo de checking (por default copia os ficheiros)
CHECK_MODE=""

# Verifica se a opção -c foi fornecida
if [[ "$1" == "-c" ]]; then
  CHECK_MODE="-c"
  # Remove o primeiro argumento e deixa os outros no $1 e $2
  shift
fi

  # Atribui valores aos argumentos
  SRC_DIR="$1"
  BACKUP_DIR="$2"

# Verifica se o diretório de origem existe
if [[ ! -d "$SRC_DIR" ]]; then
  echo "O diretório de origem '$SRC_DIR' não existe."
  exit 1
fi 

# Se o argumento de backup estiver vazio, dá erro
if [[ $BACKUP_DIR == '' ]]; then
    echo "Uso: $0 [-c] <src> <backup_dst>"
    exit 1
fi

# Cria o diretório de destino se não existir
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "mkdir -p '$BACKUP_DIR'"
  

  # Se não estiver em checking cria a pasta
  if [[ $CHECK_MODE != "-c" ]]; then
    mkdir -p "$BACKUP_DIR" || { echo "Erro ao criar o diretório de backup"; exit 1;}
  fi
fi

# Percorre todos os arquivos no diretório de origem
for FILE in "$SRC_DIR"/*; do
  # Verifica se é um ficheiro (não diretório)
  if [[ -f "$FILE" ]]; then
    # Guarda o caminho do ficheiro
    BACKUP_FILE="$BACKUP_DIR/$(basename "$FILE")"
    # Verifica se o ficheiro já existe ou, se exstir, a data de modificação.
    if [[ ! -f "$BACKUP_FILE" || "$FILE" -nt "$BACKUP_FILE" ]]; then
      echo "cp '$FILE' '$BACKUP_FILE'"
      # Se não estiver em checking cria cópias dos ficheiros
      if [[ "$CHECK_MODE" != "-c" ]]; then
        cp "$FILE" "$BACKUP_FILE" || { echo "Erro ao copiar '$FILE'"; exit 1;}
      fi
    fi
  fi
done