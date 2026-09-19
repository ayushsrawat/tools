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
max_file_name_len=0
max_modify_date_len=0
for file in "$TARGET_DIR"/*; do
	file_name=$(basename -- "$file")
	modify=$(stat -x "$file" | grep Modify)
	mod_day=$(echo $modify | awk '{print $4}' 2>/dev/null)
	mod_day_ext=${date_ext["$mod_day"]}
	mod_month_year=$(echo $modify | awk '{print $3 ", " $6}' 2>/dev/null)

	m["$file_name"]=$(echo "$mod_day""$mod_day_ext" "$mod_month_year")

	file_name_len=${#file_name}
	modify_date_len=${#m["$file_name"]}
	if [[ "$file_name_len" -gt "$max_file_name_len" ]]; then
		max_file_name_len="$file_name_len"
	fi
	if [[ "$modify_date_len" -gt "$max_modify_date_len" ]]; then
		max_modify_date_len="$modify_date_len"
	fi
done

target_count=${#m[@]}
echo "Target File Count : ${target_count}"

if [[ $target_count -gt 0 ]]; then
	file_name_spaces=$((max_file_name_len - 4))
	modify_date_spaces=$((max_modify_date_len - 11))
	total_width=$((${file_name_spaces} + ${modify_date_spaces} + 22)) 
	printf "| File %*s| Modify Date %*s|\n" "${file_name_spaces}" "" "${modify_date_spaces}" ""
	printf "%${total_width}s\n" | tr ' ' '_'
	for key in "${!m[@]}"; do
		file_name_len=${#key}
		modify_date_len=${#m["$key"]}
		file_name_spaces=$((${max_file_name_len} - ${file_name_len}))
		modify_date_spaces=$((${max_modify_date_len} - ${modify_date_len}))
		printf "| $key %*s| ${m[$key]} %*s|\n" "$file_name_spaces" "" "${modify_date_spaces}" ""
	done
	printf "%${total_width}s\n" | tr ' ' '_'
fi
