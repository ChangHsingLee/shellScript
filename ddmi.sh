#!/bin/sh

# Error Code
# No such file or directory
ENOENT=1
# Invalid argument
EINVAL=2
# too few argument
EFEWARG=3
# Fail to access I2C bus
EIO=4

PROG=$(basename $0)
A0H_ADDR=0x50
A2H_ADDR=0x51
PAGE_SELECT_ADDR=0x7F
# 32bit password, A2h Table0 byte 0x7B`0x7E
PASSWD_ADDR=0x7B

# 
PAGE_SELECT_VALUE=''
tableNo=''

# setup default Level 2 passsword
[ -z "$L2_PASSWD" ] && L2_PASSWD=FFFFFFFF
# default I2C bus number
[ -z "$I2C_BUS_NO" ] && I2C_BUS_NO=0

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

checkArgVal() {
	local args
	args=$1
	shift 1
	# including empty string (ex. "" or '')
	[ $args -ne $# ] && echo "empty" && return 1
	while [ $# -gt 0 ]; do
		[ -z $(str2val $1) ] && echo "invalid" && return 1
		shift 1
	done
	echo "ok"
	return 0
}

exitProgram() {
	[ -n "$2" ] && echo && echo $2
	echo
	[ $1 -ne 0 ] && echo "FAIL" || echo "OK"
	[ -n "$PAGE_SELECT_VALUE" ] && \
		i2cset -y $I2C_BUS_NO $A2H_ADDR $PAGE_SELECT_ADDR $PAGE_SELECT_VALUE
	exit $1
}

usage() {
	echo "Usage: $PROG A0 {read <addr> [len]|write <addr> <data> [data ...]|Dump [addr [len]]}"
	echo "       $PROG A2 <table> {read <addr> [len]|write <addr> <data> [data...]|Dump [addr [len]]}"
	echo "The script to access DDM(Digital Diagnostic Monitoring) data via I2C bus";echo
	printf "  %-10s    %s\n" "A0" "To specify A0h memory space for access"
	printf "  %-10s    %s\n" "A2" "To specify A2h memory space for access"
	printf "  %-10s    %s\n" "table" "To specify table number of A2h memory space for access"
	printf "  %-10s    %s\n" "read" "read operation, read data from DDM"
	printf "  %-10s    %s\n" "write" "write operation, write data to DDM"
	printf "  %-10s    %s\n" "dump" "to dump DDM"
}

[ $# -eq 0 ] && usage && exit 0

if false; then
for tool in i2cset i2cget i2cdump tr awk; do
	[ -z "$(which $tool)" ] && exitProgram $ENOENT "Tool '$tool' not found!"
done

# to disable protection
i2cset -y $I2C_BUS_NO $A2H_ADDR $PASSWD_ADDR 0x${L2_PASSWD:0:2} 0x${L2_PASSWD:2:2} 0x${L2_PASSWD:4:2} 0x${L2_PASSWD:6:2} i
[ $? -ne 0 ] && exitProgram $EIO "i2cget: fail to access I2C bus$I2C_BUS_NO"
fi

# check I2C address, A0h or A2h
case $(echo $1 | tr 'a-z' 'A-Z') in
A0)
	i2cAddr=$A0H_ADDR
	i2cAddrStr="A0h"
	[ $# -lt 2 ] && exitProgram $EFEWARG "Too few arguments for access A0!"
	;;
A2)
	i2cAddr=$A2H_ADDR
	i2cAddrStr="A2h"
	[ $# -lt 3 ] && exitProgram $EFEWARG "Too few arguments for access A2!"
	tableNo=$(str2val $2)
	[ -z "$tableNo" ] && exitProgram $EINVAL "Invalid value '$2' for parameter 'table'!"
	shift 1
	PAGE_SELECT_VALUE=$(i2cget -y $I2C_BUS_NO $A2H_ADDR $PAGE_SELECT_ADDR)
	[ -z "$PAGE_SELECT_VALUE" ] && exitProgram $EIO "Fail to read i2c bus#$I2C_BUS_NO A2h $PAGE_SELECT_ADDR!"
	if ! i2cset -y $I2C_BUS_NO $A2H_ADDR $PAGE_SELECT_ADDR $tableNo; then
		exitProgram $EIO "Fail to select A2h Table $tableNo! (i2c bus#$I2C_BUS_NO A2h $PAGE_SELECT_ADDR)!"
	fi
	;;
*)
	exitProgram $EINVAL "Unknown memory space, must be A0 or A2"
esac
shift 1

# check operation type and related arguments; operation should be 'Read', 'Write' or 'Dump'
op=$(echo $1 | tr 'a-z' 'A-Z')
case $op in
R*)
	# read
	[ $# -lt 2 ] && exitProgram $EFEWARG "Too few arguments for read operation!"
	addr=$(str2val $2)
	[ -z "$addr" ] && exitProgram $EINVAL "Invalid value '$2' for parameter 'addr'!"
	[ -n "$3" ] && len=$(str2val $3) || len=1
	[ -z "$len" ] && exitProgram $EINVAL "Invalid value '$3' for parameter 'len'!"
	while [ $len -ge 1 ]; do
		value=$(i2cget -y $I2C_BUS_NO $i2cAddr $addr b)
		[ -z "$value" ] && exitProgram $EIO "Fail to read i2c bus#$I2C_BUS_NO $i2cAddrStr Byte $addr!"
		len=$((len-1))
		addr=$((addr+1))
		printf "%s " $value
	done
	echo
	;;
W*)
	# write
	[ $# -lt 3 ] && exitProgram $EFEWARG "Too few arguments for write operation!"
	addr=$(str2val $2)
	[ -z "$addr" ] && exitProgram $EINVAL "Invalid value '$2' for parameter 'addr'!"
	shift 2
	[ "$(checkArgVal $# $@)" != "ok" ] && exitProgram $EINVAL "Invalid value for parameter 'data'!"
	if ! i2cset -y $I2C_BUS_NO $i2cAddr $addr $@ i; then
		exitProgram $EIO "Fail to write to i2c bus#$I2C_BUS_NO $i2cAddrStr!"
	fi
	;;
D*)
	# dump
	dumpEndAddr=255
	if [ -z "$2" ]; then
		dumpStartAddr=0
	else
		dumpStartAddr=$(str2val $2)
		[ -z "$dumpStartAddr" ] && exitProgram $EINVAL "Invalid value '$2' for parameter 'addr'!"
		if [ -n "$3" ]; then
			dumpEndAddr=$(str2val $3)
			[ -z "$dumpEndAddr" ] && exitProgram $EINVAL "Invalid value '$3' for parameter len!"
			dumpEndAddr=$((dumpStartAddr+dumpEndAddr-1))
			[ $dumpEndAddr -gt 255 ] && dumpEndAddr=255
		fi
	fi
	echo;printf "%s %s\n" $i2cAddrStr "$([ -n "$tableNo" ] && printf "Table %02Xh" $tableNo)"  
	if ! i2cdump -y -r $dumpStartAddr-$dumpEndAddr $I2C_BUS_NO $i2cAddr b; then
		exitProgram $EIO "Fail to dump i2c bus#$I2C_BUS_NO $i2cAddrStr!"
	fi
	;;
*)
	exitProgram $EINVAL "Unknown operation '$1'! Must be 'read', 'write' or 'dump'!"
esac
exitProgram 0
