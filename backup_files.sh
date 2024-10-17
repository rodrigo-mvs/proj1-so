#!/bin/bash

# Verifica a quantidade de argumentos
if [[ $# -ne 3 && $# -ne 2 ]]; then
  echo "Uso: $0 [-c] <src> <backup_dst>"
  exit 1
fi

# Se tiver 3 argumentos
if [[ $# -eq 3 ]]; then

  # Verifica se o argumento -c está na posição correta
  if [[ $1 != "-c" ]]; then
    echo "Erro: argumento inválido. Uso: $0 [-c] <src> <backup_dst>"
    exit 1
  fi

  # Usa o arg 2 e 3 como pasta src e pasta backup, respetivamente
  SOURCE_DIR="$2"
  BACKUP_DIR="$3"

  # Verifica se existe a pasta src
  if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "Erro: A pasta de origem '$SOURCE_DIR' não existe."
    exit 1
  fi

  # Verifica se existe a pasta backup
  if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "A pasta de backup '$BACKUP_DIR' não existe. A criar..."
    mkdir -p "$BACKUP_DIR"
  fi

  # Percorre todos os arquivos na pasta src
  for file in "$SOURCE_DIR"/*; do
    filename=$(basename "$file")
    source_file="$SOURCE_DIR/$filename"
    backup_file="$BACKUP_DIR/$filename"
    
    # Verifica se o ficheiro de backup já existe
    if [[ -f "$backup_file" ]]; then
      # Compara a data de modificação dos ficheiros
      if [[ "$source_file" -nt "$backup_file" ]]; then
        echo "Atualizando: $filename"
        cp "$source_file" "$backup_file"
      else
        echo "Não há necessidade de atualizar: $filename"
      fi
    else
      # Se o ficheiro de backup não existir, copia-o
      echo "Cópia inicial: $filename"
      cp "$source_file" "$backup_file"
    fi
  done

  echo "Backup concluído."

fi

# Caso tenha apenas 2 argumentos
if [[ $# -eq 2 ]]; then


fi

# GEMINI:

# for file in "$src"/*; do
#   if [[ -f "$file" ]]; then
#     target="$dst"/$(basename "$file")
#     if [[ ! -f "$target" || "$file" -nt "$target" ]]; then
#       if [[ "$check" -eq 0 ]]; then
#         cp -a "$file" "$target"
#       fi
#       echo "cp -a $file $target"
#     fi
#   fi
# done

# CHATGPT:

# #!/bin/bash

# # Função para verificar e criar a pasta de backup se não existir
# function check_and_create_backup_dir {
#   if [[ ! -d "$1" ]]; then
#     echo "A pasta de backup '$1' não existe. A criar..."
#     mkdir -p "$1"
#   fi
# }

# # Função para percorrer e copiar ficheiros
# function copy_files {
#   local src_dir="$1"
#   local backup_dir="$2"
#   local check_only="$3"

#   # Percorre todos os arquivos na pasta src
#   for file in "$src_dir"/*; do
#     filename=$(basename "$file")
#     source_file="$src_dir/$filename"
#     backup_file="$backup_dir/$filename"

#     # Verifica se o ficheiro de backup já existe
#     if [[ -f "$backup_file" ]]; then
#       # Compara a data de modificação dos ficheiros
#       if [[ "$source_file" -nt "$backup_file" ]]; then
#         echo "Atualizando: $filename"
#         if [[ "$check_only" == false ]]; then
#           cp "$source_file" "$backup_file"
#         fi
#       else
#         echo "Não há necessidade de atualizar: $filename"
#       fi
#     else
#       # Se o ficheiro de backup não existir, copia-o
#       echo "Cópia inicial: $filename"
#       if [[ "$check_only" == false ]]; then
#         cp "$source_file" "$backup_file"
#       fi
#     fi
#   done
# }

# # Verifica a quantidade de argumentos
# if [[ $# -ne 3 && $# -ne 2 ]]; then
#   echo "Uso: $0 [-c] <src> <backup_dst>"
#   exit 1
# fi

# # Variáveis
# SOURCE_DIR=""
# BACKUP_DIR=""
# CHECK_ONLY=false

# # Se tiver 3 argumentos
# if [[ $# -eq 3 ]]; then
#   # Verifica se o argumento -c está na posição correta
#   if [[ $1 != "-c" ]]; then
#     echo "Erro: argumento inválido. Uso: $0 [-c] <src> <backup_dst>"
#     exit 1
#   fi

#   # Usa o arg 2 e 3 como pasta src e pasta backup, respetivamente
#   CHECK_ONLY=true
#   SOURCE_DIR="$2"
#   BACKUP_DIR="$3"

# # Caso tenha apenas 2 argumentos
# elif [[ $# -eq 2 ]]; then
#   # Usa os arg 1 e 2 como pasta src e pasta backup, respetivamente
#   SOURCE_DIR="$1"
#   BACKUP_DIR="$2"
# fi

# # Verifica se existe a pasta src
# if [[ ! -d "$SOURCE_DIR" ]]; then
#   echo "Erro: A pasta de origem '$SOURCE_DIR' não existe."
#   exit 1
# fi

# # Verifica ou cria a pasta de backup
# check_and_create_backup_dir "$BACKUP_DIR"

# # Executa a função para copiar os ficheiros
# copy_files "$SOURCE_DIR" "$BACKUP_DIR" "$CHECK_ONLY"

# echo "Backup concluído."






