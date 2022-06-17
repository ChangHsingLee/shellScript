#/bin/sh

# the device name of Quantenna ethernet interface which connect to RTL8221B (external PHY)
# default is "eth1_1" if on i488x/i486x/i690x board (2.5G LAN)
qtnEthDev="eth1_1"

# the port number of Realtek ethernet interface which connect to RTL8221B (external PHY)
# default is 6 if on i488x/i486x/i690x board (2.5G WAN) 
rtkEthPort=6

# if syncOP is non-zero, do same operation(clear/read MIB counter) on MAC side (Realtek/Quantenna)
syncOP=1

# use to backup printk level
#qtnPrinkLevel=

#---------------------------------------------
# get filename of program/script
progName=$(basename $0)

# Error Number/Message
ERRNO_UNSUPPORT=1
errMsg1="Only works for Realtek/Quantenna SDK on i488x/i486x/i690x board!"
ERRNO_TOOL_DIAG_NOT_FOUND=2
errMsg2="Tool 'diag' is not found in search path!"
ERRNO_TOOL_PHY_REG_NOT_FOUND=3
errMsg3="Tool 'phy_reg' is not found in search path!"
ERRNO_TOOL_DMESG_NOT_FOUND=4
errMsg4="Tool 'dmesg' is not found in search path!"
ERRNO_TOOL_GREP_NOT_FOUND=5
errMsg5="Tool 'grep' is not found in search path!"
ERRNO_TOOL_SED_NOT_FOUND=6
errMsg6="Tool 'sed' is not found in search path!"
ERRNO_TOOL_TAIL_NOT_FOUND=7
errMsg7="Tool 'tail' is not found in search path!"
ERRNO_TOOL_CUT_NOT_FOUND=8
errMsg8="Tool 'cut' is not found in search path!"
ERRNO_INVALID_PARAMETER=9
errMsg9="Invalid parameter!"
ERRNO_MISSING_PARAMETER=10
errMsg10="Missing parameter!"
ERRNO_MIB_NOT_INIT=11
errMsg11="Not initialize yet!"
ERRNO_VENDER_STR_FMT_CHANGED=12
errMsg12="the format of /proc/device-tree/compatible be changed!"
ERRNO_TOOL_USLEEP_NOT_FOUND=13
errMsg8="Tool 'usleep' is not found in search path!"

# output error message
# $1: error code
# $2: string, it will be output if error code is 0 and string is not null
# BusyBox provides 'ash' which does not support array variable, use 'eval' to indirect access value of array
showErrMsg() {
	if [ $1 -eq 0 ]; then
		[ -n "$2" ] && echo $2
	else
		#eval echo "\$errMsg$1"
		eval errMsg="\$errMsg$1"
		[ -z "$errMsg" ] && errMsg="Unknown error, error code is $1!"
		echo $errMsg
	fi
}

exitProgram() {
	showErrMsg $1 $2
	# restore current printk level
	#echo $qtnPrinkLevel >/proc/sys/kernel/printk
	exit $1
}

usage() {
	echo "To enable RTL8221B MIB counter on UTP or SERDES interface"
	echo "   Usage: $progName init {utp|serdes}"
	echo "To reset RTL8221B MIB counters"
	echo "   Usage: $progName reset [-n]"
	echo "To dump RTL8221B MIB counters"
	echo "   Usage: $progName dump [-n]"
	exitProgram $1 $2
}

# read MMD register, using clause 45 frame format
# $1: device address 
# $2: register address
# return hex value (with prefix '0x'), or empty if command failed.
rtkReadMMDreg() {
	local devAddr
	local regAddr
	# diag debug ext-mdio c45 get <dev addr> <reg addr>
	devAddr=$(printf "0x%x" $(($1)))
	regAddr=$(printf "0x%x" $(($2)))
	$cmd debug ext-mdio c45 get $devAddr $regAddr 2>/dev/null | grep data | cut -d'=' -f4
}
qtnReadMMDreg() {
	local addr
	# phy_reg <eth dev> {r|w} <addr>; addr format=0x${devAddr}.${regAddr}
	addr=$(printf "0x%x.%x" $(($1)) $(($2)))
	# clear buffer
	dmesg -c >/dev/null
	$cmd $qtnEthDev r $addr >/dev/null
	addr=$(printf "%x%04x" $(($1)) $(($2)))
	dmesg | grep "${addr}: " | tail -1 | cut -d':' -f2 | sed -e 's/^[ \t]*//'
}

# write MMD register, using clause 45 frame format
# $1: device address
# $2: register address
# $3: value to be written
rtkWriteMMDreg() {
	local devAddr
	local regAddr
	local value
	# diag debug ext-mdio c45 set <dev addr> <reg addr> <value>
	devAddr=$(printf "0x%x" $(($1)))
	regAddr=$(printf "0x%x" $(($2)))
	value=$(printf "0x%x" $(($3)))
	$cmd debug ext-mdio c45 set $devAddr $regAddr $value >/dev/null
}
qtnWriteMMDreg() {
	local addr
	local value
	# phy_reg <eth dev> {r|w} <addr> [value]; addr format=0x${devAddr}.${regAddr}
	addr=$(printf "0x%x.%x" $(($1)) $(($2)))
	value=$(printf "0x%x" $(($3)))
	$cmd $qtnEthDev w $addr $value >/dev/null
	# sleep 50ms, wait for kernel message output
	usleep 50000
}

# dump MIB counter of MAC side
rtkDumpMacMibCounter() {
	echo "RTL8197CP port$rtkEthPort MIB counter:"
	diag mib dump counter port $rtkEthPort nonZero | sed '1d;2d;$d'
	echo
}

qtnDumpMacMibCounter() {
	# not support yet
	:
}

# reset MIB counter of MAC side
rtkResetMacMibCounter() {
	diag mib reset counter port $rtkEthPort >/dev/null
	echo "RTL8197CP port$rtkEthPort MIB counter be reseted"
}

qtnResetMacMibCounter() {
	# not support yet
	:
}

sanityCheck() {
	local value1
	local value2
	case $1 in
	rtk|qtn)
		# to check tool 'grep' exist or not
		[ -z "$(which grep)" ] && exitProgram $ERRNO_TOOL_GREP_NOT_FOUND
		# to check tool 'cut' exist or not
		[ -z "$(which cut)" ] && exitProgram $ERRNO_TOOL_CUT_NOT_FOUND
		# to check tool 'sed' exist or not
		[ -z "$(which sed)" ] && exitProgram $ERRNO_TOOL_SED_NOT_FOUND
		if [ "$1" = "rtk" ]; then
			# to check tool 'diag' exist or not
			cmd=`which diag`
			[ -z "$cmd" ] && exitProgram $ERRNO_TOOL_DIAG_NOT_FOUND
		else
			# to check script 'phy_reg' exist or not
			cmd=`which phy_reg`
			[ -z "$cmd" ] && exitProgram $ERRNO_TOOL_PHY_REG_NOT_FOUND
			# to check tool 'dmesg' exist or not
			[ -z "$(which dmesg)" ] && exitProgram $ERRNO_TOOL_DMESG_NOT_FOUND
			# to check tool 'tail' exist or not
			[ -z "$(which tail)" ] && exitProgram $ERRNO_TOOL_TAIL_NOT_FOUND
			# to check tool 'usleep' exist or not
			[ -z "$(which usleep)" ] && exitProgram $ERRNO_TOOL_USLEEP_NOT_FOUND
		fi
		;;
	rtl8221bMIBreg)
		# check current MIB counter setting
		# read register 31.0xc800
		eval value1=\$\(${chipVendor}ReadMMDreg 31 0xc466\)
		eval value2=\$\(${chipVendor}ReadMMDreg 31 0xc800\)
		if [ $((value1)) -eq 0 -a $((value2)) -eq $((0x5a02)) ]; then
			opIF="UTP"
			return 0
		fi
		if [ $((value1)) -eq 2 -a $((value2)) -eq $((0x5a06)) ]; then
			opIF="SERDES"
			return 0
		fi
		exitProgram $ERRNO_MIB_NOT_INIT
		;;
	*)
		exitProgram $ERRNO_UNSUPPORT
		;;
	esac
}


# initial setting for RTL8221B MIB counter access
# register 31.0xc466=0x0000 after system finish booting on i488x/i486x/i690x board
# register 31.0xc800=0x5a00 after system finish booting on i488x/i486x/i690x board
initCMD() {
	if [ "$opIF" = "UTP" ]; then
		# initial setting, for get MIB counter from UTP interface
		# write valu(0x5a02) to registe(31.0xc800)
		eval ${chipVendor}WriteMMDreg 31 0xc466 0
		eval ${chipVendor}WriteMMDreg 31 0xc800 0x5a02
		echo "Enable RTL8221B MIB counter on UTP interface"
	else
		# initial setting, for get MIB counter from SERDES interface
		# write valu(0x0002) to registe(31.0xc466)
		eval ${chipVendor}WriteMMDreg 31 0xc466 0x0002
		# write valu(0x5a06) to registe(31.0xc800)
		eval ${chipVendor}WriteMMDreg 31 0xc800 0x5a06
		echo "Enable RTL8221B MIB counter on SERDES interface"
	fi
	echo
}

# reset MIB counter
resetCMD() {
	# write value(0x0073) to register(31.0xc802)
	eval ${chipVendor}WriteMMDreg 31 0xc802 0x0073
	echo "RTL8221B MIB counter be reseted" 
	[ $syncOP -ne 0 ] && \
		eval ${chipVendor}ResetMacMibCounter
	echo
}

# dump MIB counter
dumpCMD() {
	local lower16
	local upper16
	local rxPkt
	local rxBadPkt
	# check current setting of MIB counter
	sanityCheck rtl8221bMIBreg
	# read Rx packet counter (lower 16bit); read register 31.0xc810
	eval lower16=\$\(${chipVendor}ReadMMDreg 31 0xc810\)
	# read Rx packet counter (upper 16bit); read register 31.0xc812
	eval upper16=\$\(${chipVendor}ReadMMDreg 31 0xc812\)
	rxPkt=$(((upper16<<16)+lower16))
	# read Rx bad packet counter (lower 16bit); read register 31.0xc814
	eval lower16=\$\(${chipVendor}ReadMMDreg 31 0xc814\)
	# read Rx bad packet counter (upper 16bit); read register 31.0xc816
	eval upper16=\$\(${chipVendor}ReadMMDreg 31 0xc816\)
	rxBadPkt=$(((upper16<<16)+lower16))
	echo;echo "RTL8221B $opIF MIB counter:"
	printf "%-35s:%26d\n" "Rx Packets" $rxPkt
	printf "%-35s:%26d\n\n" "Rx Bad Packets" $rxBadPkt
	[ $syncOP -ne 0 ] && \
		eval ${chipVendor}DumpMacMibCounter
}

# main()
# show message if not give any parameter
[ $# -lt 1 ] && usage 0

opCMD=
opIF=

# check/get parameter
while [ $# -gt 0 ]; do
	case $1 in
	i|init)
		opCMD="init"
		shift
		case $1 in
		u|utp)
			opIF="UTP"
			;;
		s|serdes)
			opIF="SERDES"
			;;
		*)
			if [ -z "$1" ]; then
				exitProgram $ERRNO_MISSING_PARAMETER
			else
				eval errMsg$ERRNO_INVALID_PARAMETER=\"Invalid parameter \'$1\'\"
				exitProgram $ERRNO_INVALID_PARAMETER
			fi
			;;
		esac
		;;
	r|reset)
		opCMD="reset"
		;;
	d|dump)
		opCMD="dump"
		;;
	"-n")
		syncOP=0
		;;
	"--help")
		usage 0
		;;
	*)
		eval errMsg$ERRNO_INVALID_PARAMETER=\"Invalid parameter \'$1\'\"
		exitProgram $ERRNO_INVALID_PARAMETER
		;;
	esac
	shift
done

# check platform(chip vendor), (realtek is 'rtk', quantenna is 'qtn')
chipVendor=$(cat /proc/device-tree/compatible 2>/dev/null | grep -E "rtk|qtn" | cut -d',' -f1)
[ -z "$chipVendor" ] && exitProgram $ERRNO_UNSUPPORT 
[ "$chipVendor" != "rtk" -a "$chipVendor" != "qtn" ] && \
	exitProgram $ERRNO_VENDER_STR_FMT_CHANGED

# backup current printk level and change it to 4
#qtnPrinkLevel=$(cat /proc/sys/kernel/printk|cut -d$'\t' -f1)
#echo 4 >/proc/sys/kernel/printk

# sanity check
sanityCheck $chipVendor

# Command execution
eval ${opCMD}CMD
exitProgram 0
