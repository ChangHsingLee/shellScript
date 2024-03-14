#!/bin/sh

# read one char.
# arg1: output message
# arg2: return value
confirmYesNo() {
  read -n 1 -p "$1 (y/N): " ans
  if [ "$ans" == "Y" ] || [  "$ans" == "y" ]; then
    eval $2="Y"
  else
    eval $2="N"
  fi
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
