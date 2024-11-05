#!/bin/bash
# Função para exibir o uso correto do script em caso de erro
function usage() {
  echo "Uso: $0 [-c] [-b tfile] [-r regexpr] <SRC_DIR> <BACKUP_DIR>"
  exit 1
}

# Função de verificação do regex
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

# Inicialização das variáveis dos argumentos -b, -r, -c
CHECK_MODE=""
TEXT_FILE=""
REGEX=""

# Array para armazenar os nomes dos arquivos de exceção
declare -a EXCEPTION_FILES=()

# Processa os argumentos
while getopts "cb:r:" opt; do
  case "$opt" in
    c) CHECK_MODE="-c" ;;
    b)
      TEXT_FILE="$OPTARG"
      if [[ ! -f "$TEXT_FILE" ]]; then
        echo "O ficheiro '$TEXT_FILE' não existe."
        TEXT_FILE=""
        usage
      elif [[ -n "$TEXT_FILE" ]]; then
        while IFS= read -r LINE || [ -n "$LINE" ]; do
          EXCEPTION_FILES+=("$LINE")
        done < "$TEXT_FILE"
      fi
      ;;
    r)
      REGEX="$OPTARG"
      regexCheck
      ;;
    *)
      echo "Argumento inválido: -$opt"
      usage
      ;;
  esac
done

# Remove os argumentos processados e deixa apenas os dois diretórios
shift $((OPTIND - 1))

# Define SRC_DIR e BACKUP_DIR
SRC_DIR="$1"
BACKUP_DIR="$2"

# Verifica se o diretório de origem existe
if [[ ! -d "$SRC_DIR" ]]; then
  echo "O diretório de origem '$SRC_DIR' não existe."
  usage
fi 

# Verifica se o diretório de backup foi especificado
if [[ $BACKUP_DIR == '' ]]; then
  usage
fi

# Cria o diretório de destino, se não existir
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "mkdir -p '$BACKUP_DIR'"
  if [[ $CHECK_MODE != "-c" ]]; then
    mkdir -p "$BACKUP_DIR"
  fi
fi

# Inicialização dos contadores globais
TOTAL_FILE_COPY=0
TOTAL_FILE_UPDATE=0
TOTAL_FILE_DELETED=0
TOTAL_WARNINGS=0
TOTAL_ERRORS=0
TOTAL_SIZE_COPIED=0
TOTAL_SIZE_DELETED=0

# Função de backup recursiva
function backup_files() {
  local src_dir="$1"
  local backup_dir="$2"

  # Contadores locais para cada diretório
  local dir_file_copy=0
  local dir_file_update=0
  local dir_file_deleted=0
  local dir_warnings=0
  local dir_errors=0
  local dir_size_copied=0
  local dir_size_deleted=0

  # Loop para cada arquivo/diretório em src_dir
  for FILE in "$src_dir"/*; do
    FILENAME=$(basename "$FILE" | cut -d. -f1)
    
    # Ignora arquivos na lista de exceções
    if [[ " ${EXCEPTION_FILES[*]} " == *" $FILENAME "* ]]; then
      continue
    fi

    # Se for arquivo e corresponde ao regex (ou se regex não foi especificado)
    if [[ -f "$FILE" && ( -z "$REGEX" || "$(basename "$FILE")" =~ $REGEX ) ]]; then
      local backup_file="$backup_dir/$(basename "$FILE")"
      local file_size=$(stat -c%s "$FILE")

      # Se o arquivo não existe no backup, copia e incrementa o contador e tamanho
      if [[ ! -f "$backup_file" ]]; then
        echo "cp '$FILE' '$backup_file'"
        dir_file_copy=$((dir_file_copy + 1))
        dir_size_copied=$((dir_size_copied + file_size))
        if [[ "$CHECK_MODE" != "-c" ]]; then
          cp "$FILE" "$backup_file"
        fi
      # Se existir e tiver sido mudado, atualiza o ficheiro no backup
      elif [[ "$FILE" -nt "$backup_file" ]]; then
        echo "cp '$FILE' '$backup_file'"
        dir_file_update=$((dir_file_update + 1))
        dir_size_copied=$((dir_size_copied + file_size))
        if [[ "$CHECK_MODE" != "-c" ]]; then
          cp "$FILE" "$backup_file"
        fi
      fi

    # Se for um diretório, chama a função recursivamente
    elif [[ -d "$FILE" ]]; then
      local nested_backup_dir="$backup_dir/$(basename "$FILE")"
      
      # Cria o diretório de backup aninhado, se necessário
      if [[ ! -d "$nested_backup_dir" && $CHECK_MODE != "-c" ]]; then
        mkdir -p "$nested_backup_dir"
      fi
      
      # Chamada recursiva para o próximo nível
      backup_files "$FILE" "$nested_backup_dir"
    fi
  done

  # Remove arquivos do backup que não estão no diretório de origem
  for BACKUP_FILE in "$backup_dir"/*; do
    local src_file="$src_dir/$(basename "$BACKUP_FILE")"
    if [[ ! -e "$src_file" ]]; then
      local backup_file_size=$(stat -c%s "$BACKUP_FILE")
      echo "rm -rf '$BACKUP_FILE'"
      dir_file_deleted=$((dir_file_deleted + 1))
      dir_size_deleted=$((dir_size_deleted + backup_file_size))
      if [[ "$CHECK_MODE" != "-c" ]]; then
        rm -rf "$BACKUP_FILE"
      fi
    fi
  done

  # Atualiza os contadores globais com os valores do diretório
  TOTAL_FILE_COPY=$((TOTAL_FILE_COPY + dir_file_copy))
  TOTAL_FILE_UPDATE=$((TOTAL_FILE_UPDATE + dir_file_update))
  TOTAL_FILE_DELETED=$((TOTAL_FILE_DELETED + dir_file_deleted))
  TOTAL_WARNINGS=$((TOTAL_WARNINGS + dir_warnings))
  TOTAL_ERRORS=$((TOTAL_ERRORS + dir_errors))
  TOTAL_SIZE_COPIED=$((TOTAL_SIZE_COPIED + dir_size_copied))
  TOTAL_SIZE_DELETED=$((TOTAL_SIZE_DELETED + dir_size_deleted))

  # Exibe o resumo de operações para o diretório atual
  echo "While backuping $src_dir: $dir_errors Errors; $dir_warnings Warnings; $dir_file_update Updated; $dir_file_copy Copied ($dir_size_copied B); $dir_file_deleted Deleted ($dir_size_deleted B)"
}

# Executa a função de backup na raiz
backup_files "$SRC_DIR" "$BACKUP_DIR"

# Exibe o resumo total ao final
echo -e "\nTotal stats: $TOTAL_ERRORS Errors; $TOTAL_WARNINGS Warnings; $TOTAL_FILE_UPDATE Updated; $TOTAL_FILE_COPY Copied ($TOTAL_SIZE_COPIED B); $TOTAL_FILE_DELETED Deleted($TOTAL_SIZE_DELETED B);"
