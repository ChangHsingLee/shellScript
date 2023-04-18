#!/bin/sh
str2ascii() {
        local strLen
        local i
        strLen=${#1}
        i=0
        while [ $strLen -ge 1 ]; do
                printf "0x%02X " \'${1:$i:1}
                i=$((i+1))
                strLen=$((strLen-1))
        done
}

#str2ascii $1
