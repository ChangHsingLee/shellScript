#!/bin/sh
# get file name only
echo $(basename $0)
echo ${0##*/}

# get fully real path+filename
echo $(realpath $0)

# get path
echo $(dirname $0)

# get fully real path
echo $(dirname $(realpath $0))

# remove last extension name
echo "${0%.*}"

# get last extension name
echo "${0##*.}"

# check function or command exists or not?
[ -z "$(type -t $1)" ] && echo "function/commmand '$1' not exists!"
