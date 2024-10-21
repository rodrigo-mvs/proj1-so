{
lines=()
  while IFS= read -r line || [ -n "$line" ]; do
    lines+=("$line")
  done
} < "$1"


for line in "${lines[@]}"; do
  echo "$line"
done