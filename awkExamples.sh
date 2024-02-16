#!/bin/bash

# replace line 3(NR==3), colume 1 ($1) by variable $flashImg in file $CONF_FILE
awk -i inplace 'NR==3{$1="'$flashImg'"};1' $CONF_FILE
# ignore line 1 which output from command 'docker images', and output 'column1:column2' of each line if colume1='ubuntu' and column2='xenial'.
docker images | awk 'NR>1 && $1=="ubuntu" && $2=="xenial" {printf "%s:%s\n", $1, $2}'
# show last field
awk '{print $NF}'
# calculate CPU usage
awk '/cpu /{usage=100-($5*100)/($2+$3+$4+$5+$6+$7+$8)} END {print usage}' /proc/stat
# calculate memory usage
free | awk 'FNR==2 { if ($7 == 0) usage=($2-($4+$6))*100/$2; else usage=($2-$7)*100/$2;} END { printf ("%.2f\%\n",usage) }'
free|awk 'FNR==2{if($7 == 0) free=$4+$6;else free=$7;usage=($2-free)*100/$2} END {printf("%.2f\%\n", usage)}'
# use variables
awk -v line="$line" -v byte="$byte" -v len="$readlen" 'FNR==line {for (i=byte; i<byte+len; i++) print toupper($i)}' $DDM_FILE
# remove last field, input/output delimiter is whitespace (default delimiter)
echo "00 11 22 33"|awk '{NF--};1'
# remove last field, input delimiter is whitespace (default delimiter), output delimiter is ','
echo "00 11 22 33"|awk '{OFS=",";NF--};1'
