#!/bin/bash

# Função para dar print do comando correto caso haja algum erro
function usage() {
  echo "Uso: $0 [-c] [-b tfile] [-r regexpr] <SRC_DIR> <BACKUP_DIR>"
  exit 1
}

# Função de verificação do regex
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


# Inicialização das variáveis relativas aos argumentos -b, -r, -c
CHECK_MODE=""
TEXT_FILE=""
REGEX=""

# Cria um array para armazenar os nomes dos arquivos de exceção
declare -a EXCEPTION_FILES=()

# Usa getopts para selecionar os
while getopts "cb:r:" opt; do
  case "$opt" in
  c)
    # Opção c (caso chamada, não copia os ficheiros)
    CHECK_MODE="-c"
    ;;
  b)
    # Opção -b (lẽ o ficheiro e coloca cada linha num array)
    TEXT_FILE="$OPTARG"

    if [[ ! -f "$TEXT_FILE" ]]; then
      echo "O ficheiro '$TEXT_FILE' não existe."
      TEXT_FILE=""
      usage
    elif [[ -n "$TEXT_FILE" ]]; then
      {
        while IFS= read -r LINE || [ -n "$LINE" ]; do
          EXCEPTION_FILES+=("$LINE")
        done
      } < "$TEXT_FILE"
    fi
    ;;
  r)
    # Opção -r (usa um regex e vê se o mesmo é válido)
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

# Atribui os nomes dos diretórios às variáveis
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
  echo "mkdir $BACKUP_DIR"
  # Se não estiver em checking cria a pasta
  if [[ $CHECK_MODE != "-c" ]]; then
    mkdir -p "$BACKUP_DIR"
  fi
fi


# Percorre todos os arquivos no diretório de origem
for FILE in "$SRC_DIR"/*; do
  BASENAME=$(basename "$FILE")

  # Verifica se o ficheiro está na lista de exceções
  if [[ " ${EXCEPTION_FILES[*]} " == *" $BASENAME "* ]]; then

    if [[ -d "$FILE" ]]; then
      TARGET_DIR="$BACKUP_DIR/$BASENAME"
      echo "mkdir $TARGET_DIR"
      if [[ "$CHECK_MODE" != "-c" ]]; then
        mkdir -p "$TARGET_DIR"
      fi
    fi
    continue
  fi

  # Verifica se é ficheiro e se corresponde ao regex fornecido
  if [[ -f "$FILE" && ( -z "$REGEX" || "$BASENAME" =~ $REGEX ) ]]; then

    BACKUP_FILE="$BACKUP_DIR/$BASENAME"
    # Verifica se é ficheiro e se não se encontra na lista de ficheiros a excluír 
    if [[ ! -f "$BACKUP_FILE" || "$FILE" -nt "$BACKUP_FILE" ]]; then
      echo "cp -a $FILE $BACKUP_FILE"
      if [[ "$CHECK_MODE" != "-c" ]]; then
        cp -a "$FILE" "$BACKUP_FILE"
      fi
    fi

  # Para os subdiretórios, chama a função recursivamente e com os mesmos argumentos

  elif [[ -d "$FILE" ]]; then
  
    CMD=(bash "$0")
    [[ -n "$CHECK_MODE" ]] && CMD+=("-c")
    [[ -n "$TEXT_FILE" ]] && CMD+=("-b" "$TEXT_FILE")
    [[ -n "$REGEX" ]] && CMD+=("-r" "$REGEX")
    CMD+=("$FILE" "$BACKUP_DIR/$BASENAME")
    "${CMD[@]}"
  fi
done
