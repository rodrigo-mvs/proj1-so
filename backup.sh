#!/bin/bash
function usage() {
  echo "Uso: $0 [-c] [-b tfile] [-r regexpr] dir_trabalho dir_backup"
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

# Modo de checking (por default copia os ficheiros)
CHECK_MODE=""
BACKUP_LOG=""
REGEX=""

# Usa getopts para selecionar os
while getopts "cb:r:" opt; do
  case "$opt" in
  c)
    CHECK_MODE="-c"
    ;;
  b)
    BACKUP_LOG="$OPTARG"
    ;;
  r)
    REGEX="$OPTARG"
    regexCheck
    ;;
  *)
    usage
    ;;
  \?)
    echo "Argumento inválido: -$opt"
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
  # Verifica se é um ficheiro e se corresponde à expressão regular, se fornecida
  if [[ -f "$FILE" && ( -z "$REGEX" || "$(basename "$FILE")" =~ $REGEX ) ]]; then
    BACKUP_FILE="$BACKUP_DIR/$(basename "$FILE")"
    # Verifica se o ficheiro já existe ou se é mais recente que o backup
    if [[ ! -f "$BACKUP_FILE" || "$FILE" -nt "$BACKUP_FILE" ]]; then
      echo "cp '$FILE' '$BACKUP_FILE'"
      if [[ "$CHECK_MODE" != "-c" ]]; then
        cp "$FILE" "$BACKUP_FILE"
        # Se foi fornecido um arquivo de log, cria uma log
        if [[ -n "$BACKUP_LOG" ]]; then
          echo "Backup de '$FILE' em '$BACKUP_FILE'" >> "$BACKUP_LOG"
        fi
      fi
    fi
    
  # Verifica se é um diretório
  elif [[ -d "$FILE" ]]; then
    # Início do comando da recursiva
    CMD=(bash "$0")
    
    # Adiciona os argumentos usados no script original
    [[ -n "$CHECK_MODE" ]] && CMD+=("-c")
    [[ -n "$BACKUP_LOG" ]] && CMD+=("-b" "$BACKUP_LOG")
    [[ -n "$REGEX" ]] && CMD+=("-r" "$REGEX")

    # Adiciona os diretórios
    CMD+=("$FILE" "$BACKUP_DIR/$(basename "$FILE")")

    # Volta a chamar a mesma função para a pasta
    "${CMD[@]}"
  fi
done