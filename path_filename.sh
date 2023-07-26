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
