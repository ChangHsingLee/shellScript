#!/bin/bash

progm=$(basename $0)
DEFAULT_BIT_LEN=2048
OPT_LEN=22
errMsg=(\
    "Invalid argument" \
    "Invalid file format" \
    "Can not found file" \
    "Operation faild" \
    "Invalid file type" \
)

# arg1: error code
# arg2: append error message (optional)
errExit() {
    [ $1 -eq 0 ] && exit 0
    echo -e "\nERROR: ${errMsg[$(($1-1))]} $2\n"
    usage
    exit $1
}

confirmYesNo() {
        local confirmYesNo_ans
        while [ -z $(echo $confirmYesNo_ans|grep '[YyNn]') ]; do
                read -n 1 -rp "$1 (y/N): " confirmYesNo_ans
                [ -n "$confirmYesNo_ans" ] && echo
                if [ "$confirmYesNo_ans" == "Y" ] || [ "$confirmYesNo_ans" == "y" ]; then
                        return 0
                fi
        done
	[ "$confirmYesNo_ans" == "q" ] && return 2
	return 1
}

# convert the key file format between PEM and DER
# arg1: file type; {priv|pub|cert}
# arg2: input file
# arg3: input file format; {pem|der}
# arg4: output file format; {pem|der}
_fmt_convert() {
    local outFile
    [ ! -f "$2" ] && {
        errExit 3 "'$2'"
    }
    outFile=$(basename ${2%.*}).$4
    [ -e $outFile ] && {
        if ! confirmYesNo "$outFile exists, overwrite it"; then
            return
        fi
    }
    case $1 in
    priv)
        openssl rsa -in $2 -inform $3 -outform $4 -out $outFile
	;;
    pub)
        openssl rsa -in $2 -pubin -inform $3 -outform $4 -out $outFile
        ;;
    cert)
        openssl x509 -in $2 -inform $3 -outform $4 -out $outFile
        ;;
    *)
        errExit 5 "'$1'"
    esac
    echo "$1 --> $outFile"
}

# Generate an RSA private key in PEM or DER format
# arg1: output file name
# arg2: file format; der or pem
# arg3: bit length of RSA key 
_genPrivKey() {
    local fileName=${1%.*}.$2
    local bitLen=$DEFAULT_BIT_LEN
    [ -e $fileName ] && {
        if ! confirmYesNo "$fileName exists, overwrite it"; then
            return
        fi
    }
    [ -n "$3" ] && bitLen=$3

    # key format is PKCS#1, only output file format is PEM
    # for OpenSSL 3.0.0+, may need to add argument '-traditional'
     openssl genrsa -out $fileName $bitLen

    # key format is PKCS#8, output file format is PEM or DER
    #openssl genpkey -algorithm rsa -out $fileName -outform $2 -pkeyopt rsa_keygen_bits:$bitLen
}

_genFileName() {
    local n outFile found
    found=0
    for n in private priv; do
        if echo $1 | grep -qi "\-$n"; then
            outFile=$(echo $1|sed "s/-$n/-$2/ig")
	    found=1
            break
        fi
    done
    [ $found -eq 0 ] && {
        outFile=${1%.*}-$2.${1##*.}
    }
    echo $outFile
}

# Generate an RSA public key in PEM or DER format from an RSA private key in PEM format.
# arg1: private key (PEM)
# arg2: file format; der or pem
_genPubKey() {
    local outFile
    [ ! -f "$1" ] && {
        errExit 3 "'$1'"
    }
    outFile=$(_genFileName $(basename ${1%.*}).$2 public)
    [ -e $outFile ] && {
        if ! confirmYesNo "$outFile exists, overwrite it"; then
            return
        fi
    }
    openssl rsa -in $1 -inform pem -pubout -outform $2 -out $outFile
    echo "$1 --> $outFile"
}

# generate self-signed X.509 certificate in PEM or DER format from RSA private key in PEM format 
# arg1: private key (PEM)
# arg2: file format; der or pem
_genCert() {
    local outFile
    [ ! -f "$1" ] && {
        errExit 3 "'$1'"
    }
    outFile=$(_genFileName $(basename ${1%.*}).$2 cert)
    [ -e $outFile ] && {
        if ! confirmYesNo "$outFile exists, overwrite it"; then
            return
        fi
    }
    openssl req -batch -new -x509 -key $1 -keyform pem -out $outFile -outform $2
    echo "$1 --> $outFile"
}

# dump X.509 certificate file, file format is PEM or DER
# arg1: input file
# arg2: file format(PEM or DER)
# arg3: file type(priv or pub or cert)
_dump() {
    local fmt
    [ ! -f "$1" ] && {
        errExit 3 "'$1'"
    }
    case $2 in
    pem|PEM)
        fmt="pem"
        ;;
    der|DER)
	fmt="der"
        ;;
    *)
        errExit 2 "'$2'"
    esac
    case $3 in
    priv)
        openssl rsa -in $1 -inform $fmt -noout -text
	;;
    pub)
        openssl rsa -in $1 -pubin -inform $fmt -noout -text
        ;;
    cert)
        openssl x509 -in $1 -inform $fmt -noout -text
        ;;
    *)
        errExit 5 "'$3'"
    esac
}

# Convert RSA key format from PEM to DER
# arg1: file type; {priv|pub|cert}
# arg2: the file in PEM format
pem2der() {
    _fmt_convert $1 $2 pem der
}

# Convert RSA key format from DER to PEM
# arg1: file type; {priv|pub|cert}
# arg2: the file in DER format
der2pem() {
    _fmt_convert $1 $2 der pem
}

# Generate an RSA public key in DER format from an RSA private key in PEM format.
genPubDER() {
    _genPubKey $1 der
}

# Generate an RSA public key in PEM format from an RSA private key in PEM format.
genPubPEM() {
    _genPubKey $1 pem
}

# Generate an RSA private key in PEM format
genPrivPEM() {
    _genPrivKey $1 pem $2
}

# Generate an RSA private key in DER format
#genPrivDER() {
#    _genPrivKey $1 der $2
#}

# Generate self-signed X.509 certificate in PEM format
genCertPEM() {
    _genCert $1 pem
}

# Generate self-signed X.509 certificate in DER format
genCertDER() {
    _genCert $1 der
}

dumppem() {
    _dump $2 pem $1
}

dumpder() {
    _dump $2 der $1
}

RSA2048_PRIV_KEY_FILENAME="rotk-priv"
RSA2048_PUB_KEY_FILENAME="rotk-public"
RSA2048_CERT_FILENAME="rotk-cert"
selftest() {
    local folder=$(mktemp -d /tmp/self-test.XXXXXX)
    local i result fileList typeList
    cd $folder
    echo -n "case1: generate RSA-2048 private key in PEM format ($RSA2048_PRIV_KEY_FILENAME.pem)" 
    genPrivPEM $RSA2048_PRIV_KEY_FILENAME 2048 >/dev/null 2>&1
    result=$(file --mime-encoding $RSA2048_PRIV_KEY_FILENAME.pem|awk -F': ' '{print $2}')
    [ -f $RSA2048_PRIV_KEY_FILENAME.pem ] && [ "$result" == "us-ascii" ] && \
        echo " [PASS]" || echo " [FAIL]"

    echo -n "case2: generate RSA public key in PEM format ($RSA2048_PUB_KEY_FILENAME.pem)" 
    genPubPEM $RSA2048_PRIV_KEY_FILENAME.pem >/dev/null 2>&1
    result=$(file --mime-encoding $RSA2048_PUB_KEY_FILENAME.pem|awk -F': ' '{print $2}')
    [ -f $RSA2048_PUB_KEY_FILENAME.pem ] && [ "$result" == "us-ascii" ] && \
        echo " [PASS]" || echo " [FAIL]"

    echo -n "case3: generate RSA public key in DER format ($RSA2048_PUB_KEY_FILENAME.der)" 
    genPubDER $RSA2048_PRIV_KEY_FILENAME.pem >/dev/null 2>&1
    result=$(file --mime-encoding $RSA2048_PUB_KEY_FILENAME.der|awk -F': ' '{print $2}')
    [ -f $RSA2048_PUB_KEY_FILENAME.der ] && [ "$result" == "binary" ] && \
        echo " [PASS]" || echo " [FAIL]"

    echo -n "case4: generate self-signed X.509 certificate in PEM format ($RSA2048_CERT_FILENAME.pem)" 
    genCertPEM $RSA2048_PRIV_KEY_FILENAME.pem >/dev/null 2>&1
    result=$(file --mime-encoding $RSA2048_CERT_FILENAME.pem|awk -F': ' '{print $2}')
    [ -f $RSA2048_CERT_FILENAME.pem ] && [ "$result" == "us-ascii" ] && \
        echo " [PASS]" || echo " [FAIL]"

    echo -n "case5: generate self-signed X.509 certificate in DER format ($RSA2048_CERT_FILENAME.der)" 
    genCertDER $RSA2048_PRIV_KEY_FILENAME.pem >/dev/null 2>&1
    result=$(file --mime-encoding $RSA2048_CERT_FILENAME.der|awk -F': ' '{print $2}')
    [ -f $RSA2048_CERT_FILENAME.der ] && [ "$result" == "binary" ] && \
        echo " [PASS]" || echo " [FAIL]"

    fileList=(\
        $RSA2048_PRIV_KEY_FILENAME \
        $RSA2048_PUB_KEY_FILENAME \
        $RSA2048_CERT_FILENAME \
    )
    typeList=(\
        priv \
        pub \
        cert \
    )
    # need to re-generate DER file from PEM by function "pem2der"
    echo "case6: PEM to DER convert testing" 
    for ((i=0; i<${#fileList[@]}; i++)); do
        echo -n "case6-$((i+1)): convert file type '${typeList[$i]}' from PEM to DER" 
        rm -f ${fileList[$i]}.der
        pem2der ${typeList[$i]} ${fileList[$i]}.pem >/dev/null 2>&1
        result=$(file --mime-encoding ${fileList[$i]}.der|awk -F': ' '{print $2}')
        [ -f ${fileList[$i]}.der ] && [ "$result" == "binary" ] && \
        echo " [PASS]" || echo " [FAIL]"
    done

    echo "case7: DER to PEM convert testing" 
    for ((i=0; i<${#fileList[@]}; i++)); do
        echo -n "case7-$((i+1)): convert file type '${typeList[$i]}' from DER to PEM" 
        mv ${fileList[$i]}.pem ${fileList[$i]}.pem.bak
        der2pem ${typeList[$i]} ${fileList[$i]}.der >/dev/null 2>&1
        if diff ${fileList[$i]}.pem ${fileList[$i]}.pem.bak >/dev/null; then
           echo " [PASS]"
	else
           echo " [FAIL]"
        fi
    done

    echo "case8: dump file testing" 
    for ((i=0; i<${#fileList[@]}; i++)); do
        echo -n "case8-$((i+1)): dump file type '${typeList[$i]}'" 
	dumppem ${typeList[$i]} ${fileList[$i]}.pem > ${fileList[$i]}-dumppem.txt
	dumpder ${typeList[$i]} ${fileList[$i]}.der > ${fileList[$i]}-dumpder.txt
        if diff ${fileList[$i]}-dumppem.txt ${fileList[$i]}-dumpder.txt >/dev/null; then
           echo " [PASS]"
	else
           echo " [FAIL]"
        fi
    done

    cd - >/dev/null
    [ "$1" == "keep" ] && echo "self-test folder: $folder" || rm -fr $folder
}

usage() {
    echo "Usage: $progm [OPTION]"
    echo "OPTION is one of below options:"
    printf "  %-${OPT_LEN}s %s\n" "priv <file> [bits]" "generate RSA private key(PKCS#1) in PEM format to {file}.pem"
    printf "  %-${OPT_LEN}s %s\n" ""                   "default bit length is $DEFAULT_BIT_LEN if not specify 'bits'"
    printf "  %-${OPT_LEN}s %s\n" "pair <file> [bits]" "same as option 'priv' and generate public key to {file}-public.pem"
    printf "  %-${OPT_LEN}s %s\n" "pub <priv> {pem|der}" "generate RSA public key in PEM or DER format from private"
    printf "  %-${OPT_LEN}s %s\n" ""                     "key 'priv' in PEM format; output file {priv}-public.{pem|der}"
    printf "  %-${OPT_LEN}s %s\n" "pem2der <type> <file>" "convert file format from 'PEM' to 'DER', 'type' is {priv|pub|cert}"
    printf "  %-${OPT_LEN}s %s\n" "der2pem <type> <file>" "convert file format from 'DER' to 'PEM', 'type' is {priv|pub|cert}"
    printf "  %-${OPT_LEN}s %s\n" "cert <priv> {pem|der}" "generate self-signed X.509 certificate from private key 'priv' in"
    printf "  %-${OPT_LEN}s %s\n" ""                      "PEM format; output file {priv}-cert.{pem|der}"
    printf "  %-${OPT_LEN}s %s\n" "dumppem <type> <file>" "dump PEM file, 'type' is {priv|pub|cert}"
    printf "  %-${OPT_LEN}s %s\n" "dumpder <type> <file>" "dump DER file, 'type' is {priv|pub|cert}"
    printf "\nNOTE:\n"
    printf "  1. if you see the following error message after using 'cert' option, remove RANDFILE=...\n"
    printf "     configuration lines in your openssl.cnf, it might resolve the issue:\n"
    printf "       ... :random number generator:RAND_load_file:Cannot open file: ...\n"
    printf "  2. the output filename may strip the input filename's extension and append the file type\n"
    printf "     as its own extension (ex. file.pem -> file.der)\n"
}

# main
[ $# -lt 2 ] && usage && exit 0

case $1 in
priv)
    genPrivPEM $2 $3
    ;;
pair)
    genPrivPEM $2 $3
    genPubPEM ${2%.*}.pem
    ;;
pub)
    case $3 in
    pem|PEM)
        genPubPEM $2
        ;;
    der|DER)
        genPubDER $2
        ;;
    *)
        errExit 2 "'$3'"
    esac
    ;;
pem2der|der2pem|dumppem|dumpder|selftest)
    eval $1 \"\$2\" \"\$3\"
    ;;
cert)
    case $3 in
    pem|PEM)
        genCertPEM $2
        ;;
    der|DER)
        genCertDER $2
        ;;
    *)
        errExit 2 "'$3'"
    esac
    ;;
*)
    errExit 1 "'$1'"
esac
exit 0
