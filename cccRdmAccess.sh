[ -f /etc/MLD_Config.sh ] && \
    . /etc/MLD_Config.sh

CCC_BACKUP_TMP_CMD_FILE=0

cccBackupTmpCmdFile() {
    CCC_BACKUP_TMP_CMD_FILE=0
    [ "$1" == "1" ] && CCC_BACKUP_TMP_CMD_FILE=1
}

#--- generate temp file in folder /tmp
# arg1: prefix of filename
# arg2: return value
genTmpFile() {
    local retry=0
    local prefixName=$1
    local tmpFileName
    [ -z "$prefixName" ] && prefixName="genTmpFile"
    while true; do
        if [ -n "$(which mktemp)" ]; then
            tmpFileName=$(mktemp -u /tmp/$prefixName-XXXXXXXX)
        elif [ -n "$(which shuf)" ]; then
            tmpFileName=/tmp/$prefixName-$(printf "%05d" $(shuf -i 1-99999 -n1))
        else
            tmpFileName=/tmp/$prefixName-$(head -c4 /dev/urandom|xxd -p)
        fi
        [ ! -e $tmpFileName ] && touch $tmpFileName && break
        retry=$((retry+1))
        [ $retry -ge 10 ] && \
            echo "Fail to create temporary file $tmpFileName" && exit 1
    done
    echo $tmpFileName
}

genTmpCmdFile() {
    echo $(genTmpFile cccTestCmd)
}

genTmpResultFile() {
    echo $(genTmpFile cccTestResult)
}

cccRemoveTmpFile() {
    local backupFile
    [ $CCC_BACKUP_TMP_CMD_FILE -ne 0 ] && \
        backupFile=$(genTmpFile cccBackupCMDfile) && \
        echo "Save ccc command file to $backupFile!" && \
        mv $1 $backupFile
    rm -f $1 $2
}

cccDumpProcNetDevPktCounter() {
    local counterTypes="\
        rx_bytes rx_packets rx_errs rx_drop rx_fifo rx_frame rx_compressed rx_multicast \
        tx_bytes tx_packets tx_errs tx_drop tx_fifo tx_colls tx_carrier tx_compressed \
    "
    local interface i ifList
    local $counterTypes
    while [ -n "$1" ]; do
        if [ -z "$ifList" ]; then
            ifList="$1:"
        else
            ifList="$ifList\|$1:"
        fi
        shift
    done
    while read -r interface $counterTypes; do
#        [ -n "$1" ] && [ "${interface}" != "$1:" ] && \
#            continue
        [ -n "$ifList" ] && if ! echo $interface|grep -q $ifList; then continue; fi
        echo "$interface"
        for i in $counterTypes; do
            eval "printf \"%18s: %d\\n\" $i \$$i"
        done
        echo
    done<<__END__
$(sed -n '3,$p' /proc/net/dev)
__END__
    echo
}

# arg1: command file
# arg2: result file
cccSendCmd() {
    local keyPath
    keyPath=$(awk -F'[ ;]' '/^SEL /{print $2}' $1)
    ccctest -f  $1 > $2
    # get array value, bypass checking because it may empty!
    if echo ${keyPath##*.}|grep -qE '^[0-9]+$'; then return 0; fi
    # Successfully
    if cat $2|grep -q "^transaction successful"; then return 0; fi
    # Failed
#    if cat $2|grep "^.ET\|SEL"|grep -q "fail"; then
#        return 1
#    fi
    echo;echo "Command:"
    cat $1
    echo;echo "Result:"
    cat $2
    echo;echo "[ccctest] Execution failed, please check commands!"
    echo
    cccRemoveTmpFile $1 $2
    return 1
}

_cccDumpLogFileUsage() {
    echo "Usage: _cccDumpLogFile <file> <category> <level>"
    echo "       file: log file name (with path), Ex: /var/log/sysAll.log.0"
    # see web-3.0.0/Brick/cgi-bin/pages/systemMonitoring/log/viewlog.html
    echo "   category: specify one of below categories to showing"
    echo "             all, PPP, SystemMainten, RemoteMGNT, TR069, NTP, DDNS,"
    echo "             NAT, Firewall, DHCP-Srv, WLAN, INTERNET, UPNP, DoS, VoIP"
    echo "      level: specify one of below level to showing"
    echo "             all, emerg, alert, crit, err, warn, notice, info, debug"
}
#-------- Dump Log File
# arg1: log file
# arg2: log category (get from InternetGatewayDevice.X_5067F0_Syslog.WebOption.syslogCate_id)
# arg3: log level    (get from InternetGatewayDevice.X_5067F0_Syslog.WebOption.syslogLevel_id)
    # log format
    #      Oct 25 05:34:47 OpenWrt local1.info RemoteMGNT[8927]: Web Login Successfully from IP 192.168.1.2
    #      Oct 25 05:34:46 OpenWrt kern.debug  kernel:           [74011.856255] RemoteMGNT: Action=DROP UnsecIN=br0 OUT= PHYSIN=eth0.3 MAC=00:aa:bb:01:23:40:00:e0:4c:68:01:da:86:dd SRC=fe80:0000:0000:0000:82dc:6fda:e6b
    #      Oct 25 05:02:43 OpenWrt kern.info   TR069[5785]:      [ERROR ] initTree(): SKIP to add this object to CWMP tree:Device.IPv6rd
    #      Oct 25 05:33:10 OpenWrt local1.info PPPOE:PPP[26364]: Using interface ppp0
    # log level: all, emerg, alert, crit, err, warn, notice, info, debug
    #      cat /var/log/sysAll.log | grep "\.info"
    # refer to web-3.0.0/Brick/CGI/ViewSyslog.c
_cccDumpLogFile() {
    local logFile=$1
    local logShowCategory=$2
    local logShowLevel=$3
    local idx=1
    local line
    local dateTime msgSpace logLevel procObj procID logMsg
    if [ -z "$logFile" ] || [ -z "$logShowCategory" ] || [ -z "logShowLevel" ]; then
        _cccDumpLogFileUsage
        return 1
    fi
    while IFS= read -r line; do
        IFS=. read -r msgSpace logLevel <<__END__
$(echo $line|cut -d' ' -f5)
__END__
        #echo -e "msgSpace=$msgSpace logLevel=$logLevel logShowLevel=$logShowLevel"
        [ "$logShowLevel" != "all" ] && [ "$logLevel" != "$logShowLevel" ] && \
            continue
        dateTime=$(echo $line|cut -d' ' -f1-3)
        IFS=: read -r procObj procID <<__END__
$(echo $line|cut -d' ' -f 6)
__END__
        if [ -z "$procID" ]; then
            procID=$procObj
            logMsg=$(echo $line|cut -d' ' -f7-)
        else
            logMsg="$procID: $(echo $line|cut -d' ' -f 7-)"
        fi
        procID=$(echo $procID|cut -d'[' -f1)
        if [ "$logShowCategory" == "all" ]; then
            printf "%4d%-15s  %-15s  %-6s  %s\n" $idx "($procID)" "$dateTime" $logLevel "$logMsg"
        else
            printf "%4d  %-15s  %-6s  %s\n" $idx "$dateTime" $logLevel "$logMsg"
        fi
        idx=$((idx+1))
    done <<__END__
$(if [ "$logShowCategory" == "all" ]; then
    cat $logFile
  else
    cat $logFile|grep "\<$logShowCategory\>"
  fi
)
__END__
}

cccGetKeyValueUsage() {
    echo "Usage: cccGetKeyValue <key> [var]"
    echo "   key: full key path (Example: TopNode.SubNode.2.Key)"
    echo "   var: to store return value"
}
#--- get single key value from CCC
# arg1: key (path with key name; ex: InternetGatewayDevice.X_5067F0_MacFilter.MACAddressControlType)
# arg2: return value (OPTIONAL), dump value to stdout if empty
cccGetKeyValue() {
    local cmdFile resultFile value
    #local keyPath=$(echo "$1"|sed 's/\.[^.]*$//')
    local keyPath=${1%.*}
    local key=${1##*.}
    [ -z "$1" ] && cccGetKeyValueUsage && return 1
    cmdFile=$(genTmpCmdFile)
    resultFile=$(genTmpResultFile)
    cat <<__END__ > $cmdFile
RDMNAME config;
REQUEST;
SEL $keyPath;
GET $key;
SEND;
__END__
    if ! cccSendCmd $cmdFile $resultFile; then return 1; fi
    #value=$(awk -F= '/\<Value\>/{print $2}' $resultFile)
    value=$(sed -n "s/^.*\<Value\>=\(.*\)/\1/p" $resultFile)
    if [ -z "$2" ]; then
        echo "$keyPath.$key = $value"
    else
        eval $2=$value
    fi
    #echo "cmdFile=$cmdFile"
    cccRemoveTmpFile $cmdFile $resultFile
    return 0
}

cccSetKeyValueUsage() {
    echo "Usage: cccSetKeyValue <key> <value> [type]"
    echo "     key: full key path (Example: TopNode.SubNode.2.Key)"
    echo "   value: the value which will be written to CCC"
    echo "    type: data type of value; default is 'string'"
}
#--- set single key value to CCC
# arg1: key (path with key name; ex: InternetGatewayDevice.X_5067F0_MacFilter.MACAddressControlType)
# arg2: the value will be written to CCC
cccSetKeyValue() {
    local cmdFile resultFile
    #local keyPath=$(echo "$1"|sed 's/\.[^.]*$//')
    local keyPath=${1%.*}
    local key=${1##*.}
    local value=$2
    local dataType=$3
    if [ -z "$1" -o -z "$2" ]; then
        cccSetKeyValueUsage
        return 1
    fi
    [ -z "$dataType" ] && dataType=string
    cmdFile=$(genTmpCmdFile)
    resultFile=$(genTmpResultFile)
    cat <<__END__ > $cmdFile
RDMNAME config;
REQUEST;
SEL $keyPath;
SET $key $dataType $value;
SAVE;
SEND;
__END__
    if ! cccSendCmd $cmdFile $resultFile; then return 1; fi
    grep '^SEL\|^SET\|^SAVE' $resultFile
    #echo "cmdFile=$cmdFile"
    cccRemoveTmpFile $cmdFile $resultFile
    return 0
}

cccGetMultiKeyValueUsage() {
    echo "Usage: cccGetMultiKeyValue <keyPath> <keyList> [var]"
    echo "   keyPath: key path without key name (Example: TopNode.SubNode.2)"
    echo "   keyList: key name list (Example: "key1 key2 key3...")"
    echo "   var: to store return value"
}
#--- get multiple key values from CCC
# arg1: key path (path without key name; ex: InternetGatewayDevice.X_5067F0_MacFilter)
# arg2: key list (key name list; ex: "MACAddressControlType MacFilterNumberOfEntries")
# arg3: return value (OPTIONAL), dump value to stdout if empty; delimiter is '\xff'
cccGetMultiKeyValue() {
    local cmdFile resultFile
    local keyPath=$1
    local keyList=$2
    local value
    local maxLen=0
    local $keyList i
    if [ -z "$1" -o -z "$2" ]; then
        cccGetMultiKeyValueUsage
        return 1
    fi
    [ "${keyPath: -1}" == "." ] && \
        echo -e "Wrong key path \"$keyPath\"!\n" && \
        cccGetMultiKeyValueUsage && return 1
    cmdFile=$(genTmpCmdFile)
    resultFile=$(genTmpResultFile)
    cat <<__END__ > $cmdFile
RDMNAME config;
REQUEST;
SEL $keyPath;
$(
for i in $keyList; do
    echo "GET $i;"
done
)
SEND;
__END__
    if ! cccSendCmd $cmdFile $resultFile; then return 1; fi
    #value=$(awk -F= '/\<Value\>/{printf $2"\xff"}' $resultFile)
    value=$(sed -n "s/^.*\<Value\>=\(.*\)/\1/p" $resultFile|tr '\n' '\xff')
    if [ -z "$3" ]; then
        IFS=$'\xff' read -r $keyList <<__END__
$value
__END__
        echo "$keyPath"
        for i in $keyList; do
            [ ${#i} -gt $maxLen ] && maxLen=${#i}
        done
        for i in $keyList; do
            #eval "echo \"    $i = \$$i\""
            eval "printf \"    %${maxLen}s = %s\\n\" $i \"\$$i\""
        done
    else
        eval $3=\"$value\"
    fi
    cccRemoveTmpFile $cmdFile $resultFile
    return 0
}

cccSetMultiKeyValueUsage() {
    echo "Usage: cccSetMultiKeyValue <keyPath> <keyValueList>"
    echo "        keyPath: full key path (Example: TopNode.SubNode.2)"
    echo "   keyValueList: list key and value pairs; format \"<key>=<value>[^type]...\""
    echo "                     key: key name"
    echo "                   value: the value which will be written to CCC"
    echo "                    type: data type of value; default is 'string'"
    echo "                 Example: \"key1=0^boolean key2=abcd key3=123^uint32\""
}
#--- set multiple key values to CCC
# arg1: key path (path without key name; ex: InternetGatewayDevice.X_5067F0_Syslog)
# arg2: key & value list (key name list; ex: "Active=1^boolean ServerIP=192.168.1.1 ServerPort=888^uint32")
cccSetMultiKeyValue() {
    local cmdFile resultFile key value dataType
    local keyPath=$1
    local keyList=$2
    local $keyList i
    if [ -z "$1" -o -z "$2" ]; then
        cccSetMultiKeyValueUsage
        return 1
    fi
    cmdFile=$(genTmpCmdFile)
    resultFile=$(genTmpResultFile)
    cat <<__END__ > $cmdFile
RDMNAME config;
REQUEST;
SEL $keyPath;
__END__
    for i in $keyList; do
        read -r key value dataType <<__END__
$(echo $i|awk -F[=^] '{printf "%s %s %s", $1, $2, $3}')
__END__
        [ -z "$dataType" ] && dataType=string
        echo "SET $key $dataType $value;" >> $cmdFile
    done
    echo -e "SAVE;\nSEND;" >> $cmdFile

    if ! cccSendCmd $cmdFile $resultFile; then return 1; fi
    grep '^SEL\|^SET\|^SAVE' $resultFile
    cccRemoveTmpFile $cmdFile $resultFile
    return 0
}

#--- get array key values from CCC
# arg1: key path (path without array index; ex: InternetGatewayDevice.X_5067F0_MacFilter.Rules)
# arg2: key list (key name list; ex: "Enable Interface Direction MACAddress HostName")
# arg3: return value (OPTIONAL), dump value to stdout if empty; 
#       field delimiter is '\xff', record delimter is "\n"
# arg4: Maximum number of array elements (OPTIONAL)
cccGetArrayKeyValue() {
    local cmdFile resultFile value
    local keyPath=$1
    local keyList=$2
    local maxLen=0
    local idx=1
    local $keyList i
    [ -z "$1" -o -z "$2" ] && return 1
    [ "${keyPath: -1}" == "." ] && \
        echo -e "Wrong key path \"$keyPath\"!\n" && return 1
    if echo ${keyPath##*.}| grep -qE '^[0-9]+$'; then
        echo -e "Wrong key path \"$keyPath\"!\n" && return 1
    fi
    cmdFile=$(genTmpCmdFile)
    resultFile=$(genTmpResultFile)
    while true; do
        # generate ccctest command file/script
        cat <<__END__ > $cmdFile
RDMNAME config;
REQUEST;
SEL ${keyPath}.$idx;
$(
for i in $keyList; do
    echo "GET $i;"
done
)
SEND;
__END__
        # save result
        ccctest -f $cmdFile > $resultFile
        # last array element, empty array or wrong key path
        if grep -q "^SEL .*: fail" $resultFile; then break; fi
        if [ -n "$value" ]; then
            #value=$value"\n$(awk -F= '/\<Value\>/{printf $2"\xff"}' $resultFile)"
            value="$value\n"$(sed -n "s/^.*\<Value\>=\(.*\)/\1/p" $resultFile|tr '\n' '\xff')
        else
            #value="$(awk -F= '/\<Value\>/{printf $2"\xff"}' $resultFile)"
            value=$(sed -n "s/^.*\<Value\>=\(.*\)/\1/p" $resultFile|tr '\n' '\xff')
        fi
        # 
        [ -n "$4" ] && [ $idx -eq $4 ] && break
        idx=$((idx+1))
    done # end of while true;
    cccRemoveTmpFile $cmdFile $resultFile
    [ -z "$(echo -e $value|tr -d "\xff\n")" ] && return 0
    if [ -z "$3" ]; then
        for i in $keyList; do
            [ ${#i} -gt $maxLen ] && maxLen=${#i}
        done
        idx=1
        while IFS=$'\xff' read -r $keyList; do
            echo "$keyPath.$idx"
            for i in $keyList; do
                #eval "echo \"    $i = \$$i\""
                eval "printf \"    %${maxLen}s = %s\\n\" $i \"\$$i\""
            done
            idx=$((idx+1))
        done <<__END__
$(echo -e $value)
__END__
    else
        eval $3=\"$(echo -e $value)\"
    fi
    return 0
}

cccListWANConnection() {
    local resultFile idx1 idx2 idx3 result
    local value1 value2
    resultFile=$(genTmpResultFile)
    idx1=1
    while true; do
        idx2=1
        cccGetKeyValue InternetGatewayDevice.WANDevice.$idx1.WANConnectionNumberOfEntries result
        [ -z "$result" ] && break
        echo "cccGetKeyValue InternetGatewayDevice.WANDevice.$idx1.WANConnectionNumberOfEntries = $result"
        while true; do
            cccGetMultiKeyValue InternetGatewayDevice.WANDevice.$idx1.WANConnectionDevice.$idx2 "\
                WANIPConnectionNumberOfEntries WANPPPConnectionNumberOfEntries" result
    IFS=$'\xff' read -r value1 value2 <<__END__
$(echo -e $result)
__END__
            [ -z "$value1" ] && break
            echo "    InternetGatewayDevice.WANDevice.$idx1.WANConnectionDevice.$idx2.WANIPConnectionNumberOfEntries  = $value1"
            echo "    InternetGatewayDevice.WANDevice.$idx1.WANConnectionDevice.$idx2.WANPPPConnectionNumberOfEntries = $value2"
            cccGetArrayKeyValue InternetGatewayDevice.WANDevice.$idx1.WANConnectionDevice.$idx2.WANIPConnection "\
                Enable ConnectionStatus X_5067F0_IPv6ConnStatus Name X_5067F0_IfName X_5067F0_InterfaceName MACAddress \
                ConnectionType NATEnabled X_5067F0_NATType X_5067F0_Enable_VLANID X_5067F0_VLANID \
                AddressingType ExternalIPAddress SubnetMask DefaultGateway DNSEnabled DNSServers \
                X_5067F0_IPv6Enabled X_5067F0_IPv6AddressingType X_5067F0_ExternalIPv6Address X_5067F0_IPv6LinklocalAddress \
                X_5067F0_IPv6DefaultGateway X_5067F0_DHCP6cForDNS X_5067F0_IPv6DNSServers"|awk '{ print "        " $0}'
            cccGetArrayKeyValue InternetGatewayDevice.WANDevice.$idx1.WANConnectionDevice.$idx2.WANPPPConnection "\
                Enable ConnectionStatus X_5067F0_IPv6ConnStatus Name X_5067F0_IfName X_5067F0_InterfaceName MACAddress \
                ConnectionType NATEnabled X_5067F0_NATType X_5067F0_Enable_VLANID X_5067F0_VLANID \
                ExternalIPAddress X_5067F0_SubnetMask DefaultGateway DNSEnabled DNSServers \
                X_5067F0_IPv6Enabled X_5067F0_IPv6AddressingType X_5067F0_ExternalIPv6Address X_5067F0_IPv6LinklocalAddress \
                X_5067F0_IPv6DefaultGateway X_5067F0_DHCP6cForDNS X_5067F0_IPv6DNSServers"|awk '{ print "        " $0}'
            idx2=$((idx2+1))
        done
        idx1=$((idx1+1))
    done
    rm -f $resultFile
}

#-------- Dump GUI>Security>URL Filter
CCC_DNSMASQ_KEYWORD_FILTER_FILE=/var/fyi/sys/dnsmasq_keyword_filter
CCC_DNSMASQ_CONFIG_FILE=/var/fyi/sys/dnsmasq.conf
cccDumpUrlFilterCfg() {
    local result
    cccGetKeyValue InternetGatewayDevice.X_5067F0_UrlFilter.Enable result
    echo -n "URL Filter: "
    if [ $result -eq 0 ]; then
        echo "Disable($result)"
    else
        echo "Enable($result)"
    fi
    echo "URL Table:"
    cccGetArrayKeyValue InternetGatewayDevice.X_5067F0_UrlFilter.Url "Url"
    echo "Keyword Table:"
    cccGetArrayKeyValue InternetGatewayDevice.X_5067F0_UrlFilter.keyword "Keyword"
    # It should force resolve the domain to IP address 0.0.0.0 and/or :: in config file
    if [ -e $CCC_DNSMASQ_CONFIG_FILE ]; then
        echo;echo "Dump $CCC_DNSMASQ_CONFIG_FILE"
        #cat $CCC_DNSMASQ_CONFIG_FILE
        awk '/address=/{print "    "$0}' $CCC_DNSMASQ_CONFIG_FILE
    else
        echo "$CCC_DNSMASQ_CONFIG_FILE not exists!"
    fi
    if [ -e $CCC_DNSMASQ_KEYWORD_FILTER_FILE ]; then
        echo;echo "Dump $CCC_DNSMASQ_KEYWORD_FILTER_FILE"
        #cat $CCC_DNSMASQ_KEYWORD_FILTER_FILE
        awk '{print "    "$0}' $CCC_DNSMASQ_KEYWORD_FILTER_FILE
    else
        echo "$CCC_DNSMASQ_KEYWORD_FILTER_FILE not exists!"
    fi
}

#-------- Dump GUI>Security>Filter
cccDumpMacFilterCfg() {
    local result
    cccGetKeyValue InternetGatewayDevice.X_5067F0_MacFilter.MACAddressControlType result
    echo -n "Rule Type Selection: "
    case $result in
    0)
        echo "Disable($result)"
        ;;
    1)
        echo "Black List($result)"
        ;;
    2)
        echo "White List($result)"
        ;;
    *)
        echo "Unknown($result)"
    esac
    echo "MAC Filter Listing:"
    cccGetArrayKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules "Enable Interface Direction MACAddress HostName"
    echo;echo "iptables -t filter -vnL macfilter_chain --line-numbers"
    iptables -t filter -vnL macfilter_chain --line-numbers
}

#-------- Dump GUI>Security>Parental Control
cccDumpPCPcfg() {
    local result idx1
    local tmpResultFile=$(genTmpFile)
    cccGetKeyValue InternetGatewayDevice.X_5067F0_PCP.Active result
    echo -n "Parental Control: "
    if [ $result -eq 0 ]; then
        echo "Disable"
    else
        echo "Enable"
    fi
    echo "Parental Control Profile List:"
    idx1=1
    while true; do
        cccGetMultiKeyValue InternetGatewayDevice.X_5067F0_PCP.PCPEntry.$idx1 "Active PtCtrl_PeerPtName PCPName User_MAC User_coustom_MAC \
            PtCtrl_Schedule_Everyday PtCtrl_Schedule_Sun PtCtrl_Schedule_Mon PtCtrl_Schedule_Tue PtCtrl_Schedule_Wed PtCtrl_Schedule_Thu \
            PtCtrl_Schedule_Fri PtCtrl_Schedule_Sat PtCtrl_Schedule_Start_hour PtCtrl_Schedule_Start_minute PtCtrl_Schedule_End_hour \
            PtCtrl_Schedule_End_minute PtCtrl_Server_Active" > $tmpResultFile
        [ -z "$(cat $tmpResultFile|awk -F"= " '/\<Active\>/{print $NF}')" ] && break
        cat $tmpResultFile|awk '{print "    "$0}'
        cccGetArrayKeyValue InternetGatewayDevice.X_5067F0_PCP.PCPEntry.$idx1.PtCtrl_Server \
                            "Active Serveice Protocol Port GUI_Show_Entry"|\
                            awk '{ print "        " $0}'
        cccGetArrayKeyValue InternetGatewayDevice.X_5067F0_PCP.PCPEntry.$idx1.PtCtrl_URLEntry \
                            "URL"|\
                            awk '{ print "        " $0}'
        idx1=$((idx1+1))
    done
    rm -f $tmpResultFile
}

#-------- Dump GUI>Security>Firewell
cccDumpFirewallCfg() {
    local result idx1 idx2
    local tmpResultFile=$(genTmpFile)
    cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall "\
        X_5067F0_Enable X_5067F0_ActionFlag X_5067F0_RuleActionFlag X_5067F0_EditFirewallID\
        X_5067F0_EditFirewallDir FirewallNumberOfEntries"
    idx1=1
    while true; do
        cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall.Firewall.$idx1 "\
            Name X_5067F0_Enable Interface X_5067F0_IfName Type IPVersion\
            DefaultAction X_5067F0_AppUsed RuleNumberOfEntries" > $tmpResultFile
        [ -z "$(cat $tmpResultFile|awk -F"= " '/\<Name\>/{print $NF}')" ] && break
        cat $tmpResultFile|awk '{print "    "$0}'
        cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall.Firewall.$idx1.stats "\
            Packets Bytes"|awk '{ print "        " $0}'
        idx2=1
        while true; do
            cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall.Firewall.$idx1.Rule.$idx2 "\
                Enabled X_5067F0_RuleName IPType Protocol Action RejectType Reject6Type IcmpType\
                Icmpv6Type X_5067F0_IPv6Header X_5067F0_Service"  > $tmpResultFile
            [ -z "$(cat $tmpResultFile|awk -F"= " '/\<Enabled\>/{print $NF}')" ] && break
            cat $tmpResultFile|awk '{ print "        " $0}'
            cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall.Firewall.$idx1.Rule.$idx2.Origin "\
                IPAddress Mask StartPort EndPort IPv6Address IPv6PrefixLen X_5067F0_MACAddress"|awk '{ print "            " $0}'
            cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall.Firewall.$idx1.Rule.$idx2.Destination "\
                IPAddress Mask StartPort EndPort IPv6Address IPv6PrefixLen X_5067F0_MACAddress"|awk '{ print "            " $0}'
            cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall.Firewall.$idx1.Rule.$idx2.RuleStats "\
                Packets Bytes"|awk '{ print "            " $0}'
            idx2=$((idx2+1))
        done
        idx1=$((idx1+1))
    done
    cccGetMultiKeyValue InternetGatewayDevice.X_TELEFONICA_Firewall.X_5067F0_DOS "\
        Enable TCPThreshold UDPThreshold ICMPThreshold ICMPRedirect DoSLog"
}

#-------- Dump GUI>Security>Certificates
cccDumpCertCfg() {
    local result
    
    echo "Local Certificates:"
    echo "  WebServer"
    echo "    MD5                               File"
    echo "    --------------------------------  --------------------"
    md5sum /etc/mycert/web.pem /etc/mycert/httpsCert.pem 2>&1|sed 's/^md5sum: //g'|awk '{print "    "$0}'
    echo "  SSH"
    echo "    MD5                               File"
    echo "    --------------------------------  --------------------"
    md5sum /var/app/ssh.rsa /etc/mycert/ssh.rsa 2>&1|sed 's/^md5sum: //g'|awk '{print "    "$0}'
#    ls /etc/mycert/ssh.rsa 2>&1|sed 's/^ls: //g'|awk '{printf "    "$0}' 
#    ls /var/app/ssh.rsa 2>&1|sed 's/^ls: //g'|awk '{printf "    "$0}' 
    echo "Trusted CA:"
    cccGetKeyValue InternetGatewayDevice.ManagementServer.X_5067F0_CAPath result
#    ls ${result}CA*.pem|awk '{print "    "$0}'
    echo "    MD5                               File"
    echo "    --------------------------------  --------------------"
    md5sum ${result}CA*.pem 2>&1|sed 's/^md5sum: //g'|awk '{print "    "$0}'
    cccGetKeyValue InternetGatewayDevice.ManagementServer.X_5067F0_CABackupRestoreFlag
    cccGetArrayKeyValue InternetGatewayDevice.ManagementServer.X_5067F0_CAContent CAEntry
}

#-------- Dump GUI>Maintenance>Log Setting
cccDumpSystemLogCfg() {
    # TODO:
    echo "Not supported!"
}

#-------- Dump GUI>System Monitor>Log
cccDumpSystemLog() {
    local result
    local logCategory logLevel ignore
    cccGetMultiKeyValue InternetGatewayDevice.X_5067F0_Syslog.WebOption \
                        "syslogCate_id syslogLevel_id syslogClear_id" \
                        result
    IFS=$'\xff' read -r logCategory logLevel ignore <<__END__
$(echo -e $result)
__END__
    # display
    _cccDumpLogFile "/var/log/sysAll.log" "$logCategory" "$logLevel"
    echo;echo
    echo $result|awk -F"\xff" '{print "Category: "$1"   Level: "$2"   Clear Logs: "$3}'
    echo
    ls -l /var/log/sysAll.log*
}

#------------- Examples -----------------
cccRdmAccessScriptExample1() {
    local test
    cccGetMultiKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules.2 "Enable Interface Direction MACAddress HostName" test
    IFS=$'\xff' read -r Enable Interface Direction MACAddress HostName <<__END__
$(echo -e $test)
__END__
    echo "Enable=$Enable"
    echo "Interface=$Interface"
    echo "Direction=$MACAddress"
    echo "HostName=$HostName"

    cccGetArrayKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules "Enable Interface Direction MACAddress HostName" test
    while IFS=$'\xff' read -r Enable Interface Direction MACAddress HostName; do
        echo "Enable=$Enable"
        echo "Interface=$Interface"
        echo "Direction=$MACAddress"
        echo "HostName=$HostName"
    done <<__END__
$(echo -e $test)
__END__
    cccGetMultiKeyValue InternetGatewayDevice.DeviceInfo "ProductClass Description SerialNumber"

}

cccRdmAccessScriptExample2() {
    # Check privilege
    cccGetKeyValue InternetGatewayDevice.X_5067F0_Ext.LoginPrivilegeMgmt.2.Privilege
    # Turn on all GUI menu items
    cccSetKeyValue InternetGatewayDevice.X_5067F0_Ext.LoginPrivilegeMgmt.2.Privilege "FFF FFF FFF FFF FFF FFF FFF FFF FFF"
    # Check rule type of MAC filter (disable:0, blacklist:1, whitelist:2)
    cccGetKeyValue InternetGatewayDevice.X_5067F0_MacFilter.MACAddressControlType
    # Disable MAC filter rules
    cccSetKeyValue InternetGatewayDevice.X_5067F0_MacFilter.MACAddressControlType 0 uint8

    cccGetKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules.1.Enable
    cccGetMultiKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules.2 "Enable Interface Direction MACAddress HostName"
    cccGetArrayKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules "Enable Interface Direction MACAddress HostName"
    cccSetMultiKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules.1 "Enable=0^boolean"
    cccSetMultiKeyValue InternetGatewayDevice.X_5067F0_MacFilter.Rules.1 "Enable=1^boolean Direction=Outgoing"
}

cccRdmAccessScriptExample3() {
    local keyList
    cccGetMultiKeyValue InternetGatewayDevice.DeviceInfo "ProductClass Description SerialNumber"
    keyList="EnabledForInternet WANAccessType Layer1UpstreamMaxBitRate \
             Layer1DownstreamMaxBitRate PhysicalLinkStatus TotalBytesSent \
             TotalBytesReceived TotalPacketsSent TotalPacketsReceived \
             WANAccessProvider MaximumActiveConnections NumberOfActiveConnections \
            "
    [ -n "$MLD_WAN_GPON" ] && \
        keyList="$keyList X_5067F0_PonLinkUpTime"
    #CCC_BACKUP_TMP_CMD_FILE=1
    cccGetMultiKeyValue InternetGatewayDevice.WANDevice.1 "$keyList"
}
