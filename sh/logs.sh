#!/bin/zsh

RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)
CYAN=$(tput setaf 39)
RESET=$(tput sgr0)

function usage() {
  printf "Usage:\n\t./logs.sh ${GREEN}<file-to-tail>\n${RESET}"
}

FILE_PATH="$1"

if [[ ! -f "$FILE_PATH" ]]; then
  printf "${RED}Invalid file: ${FILE_PATH} \n${RESET}"
  usage
  exit 1
fi

printf "${CYAN}Logging...\n"
printf "running command : tail -f ${FILE_PATH}${RESET}\n"

# tail the log file and use awk to color lines
tail -f $FILE_PATH | awk -v red="$RED" -v yellow="$YELLOW" -v cyan="$CYAN" -v reset="$RESET" '
{
  if ($0 ~ /ERROR|Exception|SEVERE|FATAL|FAIL|^\s+at / || $0 ~ /^java\./) {
    print red $0 reset
  } else if ($0 ~ /WARNING|WARN/) {
    print yellow $0 reset
  } else {
     print cyan $0 reset
  }
  fflush()
}'
