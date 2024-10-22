#!/bin/bash
function usage() {
  echo "Uso: $0 [-c] [-b tfile] [-r regexpr] <SRC_DIR> <BACKUP_DIR>"

  exit 1
}

function summary() {
    echo "While backuping $SRC_DIR: $ERRORS Errors; $WARNINGS Warnings; $UPDATED Updated; $COPIED Copied ($COPIED_SIZE Bytes); $DELETED Deleted (0B)"
}

function regexCheck() {
  if [[ "" =~ $REGEX ]]; then
    echo ""
  else
    if [[ $? -eq 2 ]]; then
      echo "Regex inválido: $REGEX"
      exit 1
    fi
  fi
}

# Inicialização das variáveis relativas aos argumentos
CHECK_MODE=""
TEXT_FILE=""
REGEX=""

# Contadores para o sumário
WARNINGS=0
UPDATED=0
COPIED=0
DELETED=0
COPIED_SIZE=0
UPDATED_SIZE=0

# Cria um array para armazenar os nomes dos arquivos de exceção
declare -a EXCEPTION_FILES=()

# Usa getopts para selecionar os argumentos
while getopts "cb:r:" opt; do
  case "$opt" in
  c)
    CHECK_MODE="-c"
    ;;
  b)
    TEXT_FILE="$OPTARG"

    if [[ ! -f "$TEXT_FILE" ]]; then
      echo "O ficheiro '$TEXT_FILE' não existe."
      TEXT_FILE=""
      usage
    elif [[ -n "$TEXT_FILE" ]]; then
      while IFS= read -r line || [ -n "$line" ]; do
        EXCEPTION_FILES+=("$line")
      done < "$TEXT_FILE"
    fi
    ;;
  r)
    REGEX="$OPTARG"
    regexCheck
    ;;
  *)
    echo "Argumento inválido: -$opt"
    ERRORS=$((ERRORS + 1))
    usage
    ;;
  esac
done

# Remove os argumentos e deixa apenas os dois diretórios
shift $((OPTIND - 1))

# Atribui valores aos argumentos
SRC_DIR="$1"
BACKUP_DIR="$2"

# Verifica se o diretório de origem existe
if [[ ! -d "$SRC_DIR" ]]; then
  echo "O diretório de origem '$SRC_DIR' não existe."
  $ERRORS=$((ERRORS + 1))
  usage
fi 

# Se o argumento de backup estiver vazio, dá erro
if [[ $BACKUP_DIR == '' ]]; then
  usage
fi

# Cria o diretório de destino se não existir
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "mkdir -p '$BACKUP_DIR'"
  if [[ $CHECK_MODE != "-c" ]]; then
    mkdir -p "$BACKUP_DIR"
  fi
fi

# Percorre todos os arquivos no diretório de origem
for FILE in "$SRC_DIR"/*; do

  FILENAME=$(basename "$FILE" | cut -d. -f1)

  # Verifica se o ficheiro está na lista de exceções
  if [[ " ${EXCEPTION_FILES[*]} " == *" $FILENAME "* ]]; then
    continue
  fi

  # Verifica se é um ficheiro e se corresponde à expressão regular, se fornecida
  if [[ -f "$FILE" && ( -z "$REGEX" || "$(basename "$FILE")" =~ $REGEX ) ]]; then

    BACKUP_FILE="$BACKUP_DIR/$(basename "$FILE")"
    FILE_SIZE=$(stat -c%s "$FILE")

    # Verifica se o ficheiro já existe ou se é mais recente que o backup
    if [[ ! -f "$BACKUP_FILE" ]]; then
      echo "cp '$FILE' '$BACKUP_FILE'"
      if [[ "$CHECK_MODE" != "-c" ]]; then
        cp "$FILE" "$BACKUP_FILE"
      fi
      COPIED=$((COPIED + 1))
      COPIED_SIZE=$((COPIED_SIZE + FILE_SIZE))
    elif [[ "$FILE" -nt "$BACKUP_FILE" ]]; then
      echo "cp '$FILE' '$BACKUP_FILE'"
      if [[ "$CHECK_MODE" != "-c" ]]; then
        cp "$FILE" "$BACKUP_FILE"
      fi
      UPDATED=$((UPDATED + 1))
      UPDATED_SIZE=$((UPDATED_SIZE + FILE_SIZE))
    elif [[ "$BACKUP_FILE" -nt "$FILE" ]]; then
      WARNINGS=$((WARNINGS + 1))
      echo "WARNING: backup entry '$BACKUP_FILE' is newer than '$FILE'; Should not happen"
    fi

  # Verifica se é um diretório
  elif [[ -d "$FILE" ]]; then

    CMD=(bash "$0")
    [[ -n "$CHECK_MODE" ]] && CMD+=("-c")
    [[ -n "$TEXT_FILE" ]] && CMD+=("-b" "$TEXT_FILE")
    [[ -n "$REGEX" ]] && CMD+=("-r" "$REGEX")

    CMD+=("$FILE" "$BACKUP_DIR/$(basename "$FILE")")

    "${CMD[@]}"
  fi

done

