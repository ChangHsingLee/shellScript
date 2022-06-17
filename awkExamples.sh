#!/bin/bash

# replace line 3(NR==3), colume 1 ($1) by variable $flashImg in file $CONF_FILE
awk -i inplace 'NR==3{$1="'$flashImg'"};1' $CONF_FILE
