#!/bin/bash

# Função para exibir o uso correto do script em caso de erro
function usage() {
  echo "Usage: $0 [-c] [-b tfile] [-r regexpr] <SRC_DIR> <BACKUP_DIR>"
  exit 1
}

# Função de verificação do regex
function regexCheck() {
  if [[ "" =~ $REGEX ]]; then
    echo ""
  else
    if [[ $? -eq 2 ]]; then
      echo "ERROR: Invalid Regex: $REGEX"
      exit 1
    fi
  fi
}

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

  # Faz com que a opção /* no loop fique vazia, caso necessário, para evitar erros
  shopt -s nullglob

  # Primeiro, processa os arquivos no diretório atual
  for FILE in "$src_dir"/*; do
    if [[ -f "$FILE" && ( -z "$REGEX" || "$(basename "$FILE")" =~ $REGEX ) ]]; then
      FILENAME=$(basename "$FILE" | cut -d. -f1)
      
      # Ignora arquivos na lista de exceções
      if [[ " ${EXCEPTION_FILES[*]} " == *" $FILENAME "* ]]; then
        continue
      fi

      local backup_file="$backup_dir/$(basename "$FILE")"
      
      local file_size=$(stat -c%s "$FILE")

      # Se o arquivo não existe no backup, copia e incrementa o contador e tamanho
      if [[ ! -f "$backup_file" ]]; then
        echo "cp -a $FILE $backup_file"
        dir_file_copy=$((dir_file_copy + 1))
        dir_size_copied=$((dir_size_copied + file_size))
        if [[ "$CHECK_MODE" != "-c" ]]; then
          cp -a "$FILE" "$backup_file"
        fi

        # Se der erro na cópia, incrementa o contador de erros
        if [[ $? -ne 0 ]]; then
          echo "ERROR: Failed to copy '$FILE' to '$backup_file'"
          dir_errors=$((dir_errors + 1))
        fi

      # Se existir e tiver sido mudado, atualiza o ficheiro no backup
      elif [[ "$FILE" -nt "$backup_file" ]]; then
        echo "cp -a $FILE $backup_file"
        local backup_file_size=$(stat -c%s "$backup_dir/$(basename "$FILE")")
        newsize=$((file_size - backup_file_size))
        dir_file_update=$((dir_file_update + 1))
        dir_size_copied=$((dir_size_copied + newsize))
        if [[ "$CHECK_MODE" != "-c" ]]; then
          cp -a "$FILE" "$backup_file"
        fi

        # Se der erro na atualização, incrementa o contador de erros
        if [[ $? -ne 0 ]]; then
          echo "ERROR: Failed to update '$backup_file' with '$FILE'"
          dir_errors=$((dir_errors + 1))
        fi
      fi

      # Se o arquivo de backup foi modificado mais recentemente que o original e os arquivos são diferentes, incrementa o contador de avisos
      if [[ "$FILE" -ot "$backup_file" ]] && ! cmp -s "$FILE" "$backup_file"; then
        echo "WARNING: '$backup_file' was modified more recently than '$FILE'"
        dir_warnings=$((dir_warnings + 1))
      fi
    fi
  done

  # Em seguida, processa os subdiretórios
  for FILE in "$src_dir"/*; do
    if [[ -d "$FILE" ]]; then
      local nested_backup_dir="$backup_dir/$(basename "$FILE")"
      
      # Cria o diretório de backup aninhado, se necessário
      if [[ ! -d "$nested_backup_dir" ]]; then
        echo -e "mkdir $nested_backup_dir"
        if [[ $CHECK_MODE != "-c" ]]; then
          mkdir -p "$nested_backup_dir"
        fi
      fi
      
      # Chamada recursiva para o próximo nível
      backup_files "$FILE" "$nested_backup_dir"
    fi
  done

  # Verifica se o diretório de backup existe: se estiver em check e o diretório de backup não existir, não há ficheiros para copiar 
  if [[ -d "$backup_dir" ]]; then
    # Remove arquivos do backup que não estão no diretório de origem
    for BACKUP_FILE in "$backup_dir"/*; do
      local src_file="$src_dir/$(basename "$BACKUP_FILE")"
      if [[ ! -e "$src_file" ]]; then
        local backup_file_size=$(stat -c%s "$BACKUP_FILE")
        echo "rm -rf $BACKUP_FILE"
        dir_file_deleted=$((dir_file_deleted + 1))
        dir_size_deleted=$((dir_size_deleted + backup_file_size))
        if [[ "$CHECK_MODE" != "-c" ]]; then
          rm -rf "$BACKUP_FILE"
        fi
      fi
    done
  fi

  # Fecha a verificação
  shopt -u nullglob

  # Atualiza os contadores globais com os valores do diretório
  TOTAL_FILE_COPY=$((TOTAL_FILE_COPY + dir_file_copy))
  TOTAL_FILE_UPDATE=$((TOTAL_FILE_UPDATE + dir_file_update))
  TOTAL_FILE_DELETED=$((TOTAL_FILE_DELETED + dir_file_deleted))
  TOTAL_WARNINGS=$((TOTAL_WARNINGS + dir_warnings))
  TOTAL_ERRORS=$((TOTAL_ERRORS + dir_errors))
  TOTAL_SIZE_COPIED=$((TOTAL_SIZE_COPIED + dir_size_copied))
  TOTAL_SIZE_DELETED=$((TOTAL_SIZE_DELETED + dir_size_deleted))

  # Exibe o resumo de operações para o diretório atual
  if [[ CHECK_MODE != "-c"  ]]; then
    echo -e "While backuping $src_dir: $dir_errors Errors; $dir_warnings Warnings; $dir_file_update Updated; $dir_file_copy Copied (${dir_size_copied}B); $dir_file_deleted Deleted (${dir_size_deleted}B)"
  else
    echo -e "While backuping $src_dir: $dir_file_update Updated; $dir_file_copy Copied (${dir_size_copied}B); $dir_file_deleted Deleted (${dir_size_deleted}B)"
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
        echo "ERROR: The file '$TEXT_FILE' does not exist."
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
      echo "ERRO: Invalid argument: -$opt"
      usage
      ;;
  esac
done

# Remove os argumentos processados e deixa apenas os dois diretórios
shift $((OPTIND - 1))

# Define SRC_DIR e BACKUP_DIR
SRC_DIR="$1"
BACKUP_DIR="$2"

# Inicialização dos contadores globais
TOTAL_FILE_COPY=0
TOTAL_FILE_UPDATE=0
TOTAL_FILE_DELETED=0
TOTAL_WARNINGS=0
TOTAL_ERRORS=0
TOTAL_SIZE_COPIED=0
TOTAL_SIZE_DELETED=0

FLAG_ERROR=0

# Verifica se o diretório de origem existe
if [[ ! -d "$SRC_DIR" ]]; then
  echo "ERROR: The source directory '$SRC_DIR' does not exist."
  TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  FLAG_ERROR=1
fi 

# Verifica se o diretório de backup foi especificado
if [[ $BACKUP_DIR == '' ]]; then
  TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  FLAG_ERROR=1
fi

# Cria o diretório de destino, se não existir
if [[ ! -d "$BACKUP_DIR" ]]; then
  echo "mkdir $BACKUP_DIR"
  if [[ $CHECK_MODE != "-c" ]]; then
    mkdir -p "$BACKUP_DIR"
  fi

  # Se houver erro ao criar o diretório de backup, exibe mensagem de erro
  if [[ $? -ne 0 ]]; then
    echo "ERROR: Failed to create the backup directory: $BACKUP_DIR"
    TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
    FLAG_ERROR=1
  fi
fi



# Obtém o caminhos completos
FULL_SRC_DIR=$(realpath "$SRC_DIR")
FULL_BACKUP_DIR=$(realpath "$BACKUP_DIR")

# Obtém o diretório pai de SRC_DIR
PARENT_BACKUP_DIR=$(dirname "$FULL_BACKUP_DIR")

# Obtém o tamanho do diretório de origem
SRC_SIZE=$(du -s "$SRC_DIR" | awk '{print $1}')
# Obtém o espaço disponível no diretório de backup
BACKUP_FREE=$(df "$PARENT_BACKUP_DIR" | awk 'NR==2 {print $4}')

# Verifica se há armazenamento suficiente no diretório de backup
if [[ "$SRC_SIZE" -gt "$BACKUP_FREE" ]]; then
  echo "ERROR: backup directory does not have enough space"
  TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  FLAG_ERROR=1
fi

# Verifica se FULL_SRC_DIR é parte de FULL_BACKUP_DIR
if [[ "$FULL_BACKUP_DIR" == "$FULL_SRC_DIR" || "$FULL_BACKUP_DIR" == "$FULL_SRC_DIR/"* ]]; then
  echo "ERROR: The backup directory cannot be a subdirectory of the source directory."
  TOTAL_ERRORS=$((TOTAL_ERRORS + 1))
  FLAG_ERROR=1
fi 

# Executa a função de backup na raiz se não houver erros que não o permitam
if [[ $FLAG_ERROR -eq 0 ]]; then
  backup_files "$SRC_DIR" "$BACKUP_DIR"
else
    echo -e "\nWhile backuping $SRC_DIR: $TOTAL_ERRORS Errors; $TOTAL_WARNINGS Warnings; $TOTAL_FILE_UPDATE Updated; $TOTAL_FILE_COPY Copied ($TOTAL_SIZE_COPIED B); $TOTAL_FILE_DELETED Deleted($TOTAL_SIZE_DELETED B);"
fi
