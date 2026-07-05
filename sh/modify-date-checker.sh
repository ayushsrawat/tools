#!/usr/bin/env /opt/homebrew/bin/bash

# > /opt/homebrew/bin/bash --version
# 	GNU bash, version 5.3.3(1)-release (aarch64-apple-darwin25.0.0)

set -e

TARGET_DIR="$1"

shopt -s nullglob  # Prevents errors if the directory is empty
# shopt -s dotglob   # Includes hidden files

help() {
	echo -e "Usage: \n\t"$0" <TARGET DIR PATH>"
}

if [[ -z "$TARGET_DIR" ]]; then
	echo "Missing Target Directory to execute."
	help
	exit 0
fi

if [[ ! -d "$TARGET_DIR" ]]; then
	echo "Provided Target is not a Directory."
	help
	exit 1
fi

echo "Target Directory : $TARGET_DIR"

declare -A date_ext
for i in {1..31}; do
	case "$i" in
        1|21|31)
            date_ext[$i]="st"
            ;;
        2|22)
            date_ext[$i]="nd"
            ;;
        3|23)
            date_ext[$i]="rd"
            ;;
        *)
            date_ext[$i]="th"
            ;;
    esac
done

declare -A m
max_len=0
for file in "$TARGET_DIR"/*; do
	file_name=$(basename -- "$file")
	modify=$(stat -x "$file" | grep Modify)
	mod_day=$(echo $modify | awk '{print $4}' 2>/dev/null)
	mod_day_ext=${date_ext["$mod_day"]}
	mod_month_year=$(echo $modify | awk '{print $3 ", " $6}' 2>/dev/null)

	m["$file_name"]=$(echo "$mod_day""$mod_day_ext" "$mod_month_year")

	len=${#file_name}
	if [[ "$len" -gt "$max_len" ]]; then
		max_len="$len"
	fi
done

echo "Target File Count : ${#m[@]}"

for key in "${!m[@]}"; do
	len=${#key}
	spaces=$((max_len - len)) 
    printf "| File: | $key %*s| Modify Date: ${m[$key]} \n" "$spaces" ""
done
