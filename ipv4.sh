#!/bin/sh

# global variables
ipaddr=
netmask=
network=
broadcast=

PROG=$(basename $0)
[ -z "$ETH_DEV" ] && ETH_DEV=eth0

usage() {
    echo "Usage: $PROG [--help|<ipv4 addr> <netmask>|<ipv4 CIDR>]"
    echo "To get/set IPv4 address from/to ethernet device(default is eth0)"
    echo "      --help: display this help and exit"
    echo "   ipv4 addr: new IPv4 address for ethernet device"
    echo "     netmask: new network mask for ethernet device"
    echo "   ipv4 CIDR: CIDR notation compactly indicates the network mask for an IPv4 address"
    echo "     ETH_DEV: The environment variable to specify ethernet device, default is eth0"
    echo "   example: to get IPv4 address information of eth1"
    echo "      ETH_DEV=eth1 $PROG"
    echo "   example: to set IPv4 address on eth0"
    echo "      $PROG 192.168.1.1 255.255.255.0"
    echo "   example: to set IPv4 address on eth1"
    echo "      ETH_DEV=eth1 $PROG 192.168.1.1/24"

}

valid_ipv4() {
    local a b c d
    [ -z $(echo $1|grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$') ] && \
	    return 1
    IFS=. read -r a b c d <<__END__
$1
__END__
    [ $a -gt 255 ] && return 2
    [ $b -gt 255 ] && return 3
    [ $c -gt 255 ] && return 4
    [ $d -gt 255 ] && return 5
    return 0
}

ipv4_to_num() {
    local a b c d
    IFS=. read a b c d <<__END__
$1
__END__
    echo $((a<<24|b<<16|c<<8|d))
}

num_to_ipv4() {
    local val=$1
    local ip n
    for n in 1 2 3 4; do
        ip=$((val & 0xff))${ip:+.}$ip
        val=$((val >> 8))
    done
    echo $ip
}

valid_netmask() {
    [ -z $(echo $1 | grep -E '^(254|252|248|240|224|192|128|0)\.0\.0\.0|255\.(254|252|248|240|224|192|128|0)\.0\.0|255\.255\.(254|252|248|240|224|192|128|0)\.0|255\.255\.255\.(255|254|252|248|240|224|192|128|0)$') ] && \
         return 1
    return 0
}

cidr_to_netmask() {
    local val=$1
    [ -z "$(echo $val | grep -E '^[0-9]{1,2}$')" ] && return 1
    [ $val -gt 32 ] && return 2
    echo $(num_to_ipv4 $(((0xffffffff<<(32-val))&0xffffffff)))
}

netmask_to_cidr() {
    local mask=$1
    local cidr=32
    local val
    if ! valid_netmask $mask; then return 1; fi
    val=$(ipv4_to_num $mask)
    while [ $val -ne 0 ]; do
        [ $((val & 1)) -ne 0 ] && break;
	val=$((val>>1))
	cidr=$((cidr-1))
    done
    echo $cidr
}

# arg1: CIDR notation; ex: 192.168.0.1/24
# arg2: variable name which is used to stores IP address
# arg3: variable name which is used to stores netmask
# usage: parseCIDR 192.168.0.1/24 ipaddr netmask
#        example: 192.168.0.1/24
parseCIDR() {
    local ip mask cidr
    IFS=/ read ip cidr <<__END__
$1
__END__
    mask=$(cidr_to_netmask $cidr)
    [ -z "$mask" ] && return 1
    if ! valid_ipv4 $ip; then return 2; fi
    if [ -n "$2" ]; then
        eval $2=$ip
    else
        ipaddr=$ip
    fi
    if [ -n "$3" ]; then
        eval $3=$mask
    else
        netmask=$mask
    fi
    return 0
}

# arg1: IP address
# arg2: netmask
networkID() {
    local ip_num mask_num
    ip_num=$(ipv4_to_num $1)
    [ -z "$ip_num" ] && return 1
    mask_num=$(ipv4_to_num $2)
    [ -z "$mask_num" ] && return 2
    echo $(num_to_ipv4 $((ip_num & mask_num)))
}

# arg1: IP address
# arg2: netmask
broadcastIP() {
    local ip_num mask_num
    ip_num=$(ipv4_to_num $1)
    [ -z "$ip_num" ] && return 1
    mask_num=$(ipv4_to_num $2)
    [ -z "$mask_num" ] && return 2
    echo $(num_to_ipv4 $((ip_num | (~mask_num))))
}

updateNetworkCfgFile() {
    [ ! -f /etc/network/interfaces ] && return 0
    sed -i "/^iface $ETH_DEV inet/{n;s/address.*/address $ipaddr/;n;s/netmask.*/netmask $netmask/;n;s/broadcast.*/broadcast $broadcast/}" /etc/network/interfaces
}

showInfo() {
    echo "IP address: $ipaddr"
    echo "Netmask   : $netmask"
#    echo "Network ID: $network"
#    echo "Broadcast : $broadcast"
}

[ "$1" == "--help" ] && usage && exit 0

#printk_level=$(cat /proc/sys/kernel/printk | awk '{print $1}')

case $# in
    0) # show IPv4 address
        info=$(ip -4 addr show $ETH_DEV | awk '$1 == "inet" {print $2}')
	[ -z "$info" ] && exit 1
        for i in $info; do
            if ! parseCIDR $i; then
                echo "Internal error!"
                exit 2
            fi
            broadcast=$(broadcastIP $ipaddr $netmask)
            network=$(networkID $ipaddr $netmask)
	    showInfo
        done
	exit 0
        ;;
    1) # to set IPv4 address (CIDR notation)
        if ! parseCIDR $1; then
            echo -e "Invalid argument '$1'!\n"
            #usage
	    exit 2
        fi
        ;;
    *) # to set IPv4 address
        if ! valid_ipv4 $1; then echo -e "Invalid IPv4 address '$1'!\n" && exit 3; fi
        if ! valid_netmask $2; then echo -e "Invalid netmask '$2'!\n" && exit 4; fi
        ipaddr=$1
        netmask=$2
        ;;
esac

broadcast=$(broadcastIP $ipaddr $netmask)
network=$(networkID $ipaddr $netmask)
updateNetworkCfgFile
showInfo
#echo 0 > /proc/sys/kernel/printk
#echo -n "Restart network interface... "
ifdown $ETH_DEV
ifup $ETH_DEV
#echo "done"
#echo $printk_level > /proc/sys/kernel/printk
