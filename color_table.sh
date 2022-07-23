#!/bin/bash

# Hybrid Syntax: 
#   "\e[<style>;<foreground>;<background>m"

# Foreground Color Code
C_BLACK="\e[30m"
C_RED="\e[31m"
C_GREEN="\e[32m"
C_YELLOW="\e[33m"
C_BLUE="\e[34m"
C_MAGENTA="\e[35m"
C_CYAN="\e[36m"
C_LGRAY="\e[37m"
C_GRAY="\e[90m"
C_LRED="\e[91m"
C_LGREEN="\e[92m"
C_LYELLOW="\e[93m"
C_LBLUE="\e[94m"
C_LMAGENTA="\e[95m"
C_LCYAN="\e[96m"
C_WHITE="\e[97m"

# Background Color Code
C_BBLACK="\e[40m"
C_BRED="\e[41m"
C_BGREEN="\e[42m"
C_BYELLOW="\e[43m"
C_BBLUE="\e[44m"
C_BMAGENTA="\e[45m"
C_BCYAN="\e[46m"
C_BLGRAY="\e[47m"
C_GRAY="\e[100m"
C_LRED="\e[101m"
C_LGREEN="\e[102m"
C_LYELLOW="\e[103m"
C_LBLUE="\e[104m"
C_LMAGENTA="\e[105m"
C_LCYAN="\e[106m"
C_WHITE="\e[107m"

# Text Style Code
C_BOLD="\e[1m"
C_FAINT="\e[2m"
C_ITALICS="\e[3m"
C_UNDERLINE="\e[4m"
C_STRIKETHROUGH="\e[9m"

# Reset/Normal
C_END="\e[0m"


set_color(){
  if [ $# -lt 1 ] || [ $# -gt 3 ]; then
    echo -e -n "\e[0m"; return
  fi
  colorStr="\e[$1"; shift
  while [ $# -ne 0 ]; do
    colorStr+=";$1"
    shift
  done
  colorStr+="m"
  echo -e -n $colorStr
}

# example:
# set_color 9 3 41; echo "My Test"; set_color
# echo "My Test"
# set_color 1; echo "My Test"; set_color
# echo -e "${C_RED}My Test${C_END}"
