#!/bin/bash

# replace line 3(NR==3), colume 1 ($1) by variable $flashImg in file $CONF_FILE
awk -i inplace 'NR==3{$1="'$flashImg'"};1' $CONF_FILE
# ignore line 1 which output from command 'docker images', and output 'column1:column2' of each line if colume1='ubuntu' and column2='xenial'.
docker images | awk 'NR>1 && $1=="ubuntu" && $2=="xenial" {printf "%s:%s\n", $1, $2}'
# show last field
awk '{print $NF}'
