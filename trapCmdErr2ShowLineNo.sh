#!/bin/bash
PROG=$(basename $0)

trapCmdErrIndicator() {
  echo -e "\e[33m!!CMD FAILURE!! \e[31m$PROG[$1] $2\e[0m"
  exit 1
}

trap 'trapCmdErrIndicator ${LINENO} "$BASH_COMMAND"' ERR

# example1: ignore failed
$(cp -f ../$VENDOR/$MODEL/configs/$MODEL.config .config|true)
echo "Ignore command failed!"

#example2: show failed message when command failure
cp -f ../$VENDOR/$MODEL/configs/$MODEL.config .config
echo "This message will not be showing!"
