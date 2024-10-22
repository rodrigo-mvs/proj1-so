#!/bin/bash
function usage() {
  echo "Uso: $0 [-c] [-b tfile] [-r regexpr] <SRC_DIR> <BACKUP_DIR>"
  exit 1
}

function regexCheck() {

        if [[ "" =~ $REGEX ]]; then
          echo ""
        else
        # Quando o registo dá código 2, dá o regex como inválido
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

# Cria um array para armazenar os nomes dos arquivos de exceção
declare -a EXCEPTION_FILES=()

# Usa getopts para selecionar os
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
      {
        while IFS= read -r line || [ -n "$line" ]; do
          EXCEPTION_FILES+=("$line")
        done
      } < "$TEXT_FILE"
    fi
    ;;
  r)
  
    REGEX="$OPTARG"
    regexCheck
    ;;
  *)
    # Caso tenha um argumento diferente de -c, -b, -r, dá erro de argumento inválido
    echo "Argumento inválido: -$opt"
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
  usage
fi 

# Se o argumento de backup estiver vazio, dá erro
if [[ $BACKUP_DIR == '' ]]; then
  usage
fi


# Cria o diretório de destino se não existir
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "mkdir -p '$BACKUP_DIR'"
  # Se não estiver em checking cria a pasta
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

    # Verifica se o ficheiro já existe ou se é mais recente que o backup
    if [[ ! -f "$BACKUP_FILE" || "$FILE" -nt "$BACKUP_FILE" ]]; then
      echo "cp '$FILE' '$BACKUP_FILE'"
      if [[ "$CHECK_MODE" != "-c" ]]; then
        cp "$FILE" "$BACKUP_FILE"
      fi
    fi
    
  # Verifica se é um diretório
  elif [[ -d "$FILE" ]]; then

    # Início do comando para chamar a função recursivamente
    CMD=(bash "$0")
    
    # Adiciona os argumentos usados no script original
    [[ -n "$CHECK_MODE" ]] && CMD+=("-c")
    [[ -n "$TEXT_FILE" ]] && CMD+=("-b" "$TEXT_FILE")
    [[ -n "$REGEX" ]] && CMD+=("-r" "$REGEX")

    # Adiciona os diretórios
    CMD+=("$FILE" "$BACKUP_DIR/$(basename "$FILE")")

    # Volta a chamar a mesma função para o diretório
    "${CMD[@]}"

  fi
  
done