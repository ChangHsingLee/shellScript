#!/bin/sh

# read one char.
# arg1: output message
# arg2: return value
confirmYesNo() {
        local confirmYesNo_ans
        while [ -z $(echo $confirmYesNo_ans|grep '[YyNn]') ]; do
                read -n 1 -rp "$1 (y/N): " confirmYesNo_ans
                [ -n "$confirmYesNo_ans" ] && echo
                if [ "$confirmYesNo_ans" == "Y" ] || [ "$confirmYesNo_ans" == "y" ]; then
                        eval $2=Y
                else
                        eval $2=N
                fi
        done
}

# split parameter name & value (expression exapmle: abc=10, abc:10 or abc 10)
# arg1: expression string 
# arg2: delimiter
splitParameterValue() {
  local name
  local value
  
if echo $(realpath $SHELL 2>/dev/null)| grep -q busybox; then
  IFS=$2 read -r name value <<__END__
$1
__END__
else
  # To avoid parsing failed if shell is busybox
  eval "IFS=\$2 read -r name value <<< \$1"
fi
echo "Parameter Name : $name"
echo "Parameter Value: $value"
}
