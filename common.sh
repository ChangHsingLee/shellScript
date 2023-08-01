#!/bin/sh

C_GRAY="\e[37m"
C_RED="\e[91m"
C_GREEN="\e[92m"
C_YELLOW="\e[93m"
C_BLUE="\e[94m"
C_END="\e[0m"

PROG=$(basename $0)

# disable Ctrl-C
trap '' SIGINT
# disable Ctrl-Z
trap '' SIGTSTP

# set SIGINT/SIGTSTP to default action
#trap - SIGINT
#trap - SIGTSTP

# arg1: exit(error) code
# arg2: output message
exitProg() {
	[ $1 -ne 0 ] && echo -en "${C_RED}[ERROR]${C_END} "
	[ -n "$2" ] && echo $2
    if type _exitProg >/dev/null; then
        _exitProg $1 $2
    fi
	exit $1
}

isHexStr() {
    local val
    val=$(echo $1|sed 's/^0x//g')
	if [ -n "$(echo $val | egrep '^[0-9A-Fa-f]+$')" ]; then
		return 0
	fi
	return 1
}

hexStr2val() {
    local val
    if isHexStr $1; then
        val=$(echo $1|sed 's/^0x//g')
        echo $((0x$val))
    fi
}

isDecStr() {
	if [ -n "$(echo $1 | egrep '^[0-9]+$')" ]; then
		return 0
	fi
	return 1
}

decStr2val() {
    if isDecStr $1; then
        echo $1
    fi
}

isOctStr() {
	if [ -n "$(echo $1 | egrep '^0[0-7]+$')" ]; then
		return 0
	fi
	return 1
}

octStr2val() {
    local val=$1
    if isOctStr $val; then
        echo $((val))
    fi
}

# arg1: DEC/OCT/HEX string
str2val() {
    [ -z "$1" ] && return
    if isHexStr $1; then
        hexStr2val $1
        return
    fi
    if isOctStr $1; then
        octStr2val $1
        return
    fi
    decStr2val $1
}

# arg1: PID of background process
# arg2: the message to show
showProgressSign() {
    local idx=1
    # busybox 'ash' is not support array!
    #local progressSign=(- \\ \| /)
    local progressSign0="-"
    local progressSign1="\\"
    local progressSign2="|"
    local progressSign3="/"
    local result
    [ -z "$1" ] && return 0
    if [ -z "$2" ]; then
        echo -en "${C_GRAY}[$1]${C_END}Task in progress... -"
    else
        echo -en "${C_GRAY}[$1]${C_END}${2}... -"
    fi
    while true; do
        # busybox 'ps' is not support option '-p'
        #if ! ps -p $pid >/dev/null; then
        if [ -z "$(ps | awk '{print $1}'| grep $1)" ]; then
            break
        fi
        # busybox 'ash' is not support array!
        #echo -en "\b${progressSign[$idx]}"
        echo -en "\b$(eval echo \$progressSign$idx)"
        idx=$(((idx+1)%4))
        sleep 1
    done
    wait $1
    result=$?
    if [ $result -ne 0 ]; then
        echo -e "\bFailed."
    else
        echo -e "\bDone."
    fi
    return $result
}

