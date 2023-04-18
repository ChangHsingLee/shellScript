#!/bin/sh
decStr2Val() {
        case $1 in
        ''|*[!0-9]*)
                ;;
        *)
                echo $1
        esac
}

hexStr2Val() {
        local val
        val=$(echo $1|sed 's/^0x//g')
        case $val in
        ''|*[!0-9A-Fa-f]*)
                ;;
        *)
                echo $((0x$val))
        esac
}

str2val() {
        local val
        val=$1
        if [ "${val:0:2}" == "0x" ]; then
                val=$(hexStr2Val $val)
        else
                val=$(decStr2Val $val)
        fi
        echo $val
}

ascii2str() {
        local val
        local tmp
        while [ $# -ne 0 ]; do
                tmp=$(str2val $1)
                [ -z "$tmp" ] && val='' && break
                tmp=$(printf "%X" $tmp)
                val=$val$(printf "\x$tmp")
                shift 1
        done
        echo $val
}

#ascii2str $@
