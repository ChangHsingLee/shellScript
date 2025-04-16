#!/bin/sh
FILE_LIST="\
    trunk-utils/MLD_Scripts/menu/feature.kconfig                                                    \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/Makefile.MSTC                              \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/dump_zlfw_header.c                     \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/Makefile                               \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/extract_image.c                        \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/compute_checksum.c                     \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/check_checksum.c                       \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/zlFwHeader.h                           \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/Makefile.MSTC                          \
    makecode/sysapps/private/mitrastar/fwupgrade/REALTEK/src/append_zlfw_header.c                   \
    makecode/sysapps/private/mitrastar/fwupgrade/Makefile                                           \
    makecode/sysapps/private/mitrastar/libboardaccess/Makefile                                      \
    makecode/sysapps/private/mitrastar/libboardaccess/REALTEK/boardaccess_wrapper.c                 \
    platform/bootloader/u-boot-2022.10/include/mstc/zlFwHeader.h                                    \
    platform/bootloader/u-boot-2022.10/common/mstc/fw_upgrade.c                                     \
    platform/bootloader/u-boot-2022.10/common/mstc/zboot_sub.c                                      \
    platform/bootloader/u-boot-2022.10/Kconfig                                                      \
    platform/bootloader/Makefile.MSTC                                                               \
    makecode/sysapps/public/others/dropbear-2020.81/Makefile.MSTC                                   \
    makecode/sysapps/public/gpl/openssh-9.9p1/Makefile.MSTC                                         \
    makecode/sysapps/public/gpl/busybox/Makefile                                                    \
    makecode/sysapps/public/gpl/mini_httpd-1.30/Makefile                                            \
    makecode/sysapps/private/third-party/Aricent/iptk_8_2/ICF/source/ifx_al/make/linux/makefile     \
    makecode/sysapps/private/mitrastar/tefcliapp/Makefile                                           \
    makecode/sysapps/private/mitrastar/libCmd/Makefile                                              \
    makecode/sysapps/private/mitrastar/ztr69-1.0/Makefile                                           \
    makecode/sysapps/private/mitrastar/mos/Makefile.cortina.ca8279                                  \
    makecode/sysapps/private/mitrastar/mos/Makefile.brcm.502L06                                     \
    makecode/sysapps/private/mitrastar/mos/Makefile.econet.7551                                     \
    makecode/sysapps/private/mitrastar/mos/Makefile.econet.7528                                     \
    makecode/sysapps/private/mitrastar/mos/Makefile.rtk.USDKV2                                      \
    makecode/sysapps/private/mitrastar/mos/Makefile.rtk.lunaV4                                      \
    makecode/sysapps/private/mitrastar/mos/Makefile.econet.7529                                     \
    makecode/sysapps/private/mitrastar/mos/Makefile.cortina.ca8289                                  \
    makecode/sysapps/private/mitrastar/mos/Makefile.brcm.504L04p1                                   \
    makecode/sysapps/private/mitrastar/diagnosticsProcess/Makefile                                  \
    makecode/sysapps/private/mitrastar/tefdog/Makefile.MSTC                                         \
    makecode/sysapps/private/mitrastar/zywifid-3.0/libzywlan/QTN/Makefile                           \
    makecode/sysapps/private/mitrastar/zywifid-3.0/Makefile                                         \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_Airtel_FWA/Makefile                  \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_TO2/Makefile                         \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_RestAPI/Toolkit/Makefile             \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_RestAPI/Makefile                     \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_RestAPI/APIs/Makefile                \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_RestAPI/FWA_APIs/Makefile            \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_sophia/Makefile                      \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_mhs/Makefile                         \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/Makefile                                 \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_mhs_Chile/Makefile                   \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_TEF_SFU_mhs/Makefile                 \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_Instalacion_Chile/Makefile           \
    makecode/sysapps/private/mitrastar/web-3.0.0/Brick/CGI/cgi_TO2_FWA/Makefile                     \
    makecode/sysapps/private/mitrastar/ccc/be_modules/Makefile                                      \
    makecode/sysapps/private/mitrastar/ccc/libccc_be/libccc_be_wlan/Makefile                        \
    makecode/sysapps/private/mitrastar/ccc/core/be/Makefile                                         \
    makecode/sysapps/private/mitrastar/syscmd/Makefile                                              \
    makecode/sysapps/private/mitrastar/voicecmd/Makefile                                            \
    makecode/sysapps/private/mitrastar/CMDSH/Makefile                                               \
    makecode/sysapps/private/mitrastar/button_monitor/Makefile                                      \
    makecode/sysapps/private/mitrastar/ZyIMS/config_sys/make/makefile.mk                            \
    makecode/sysapps/private/mitrastar/hachi/Makefile                                               \
    makecode/sysapps/private/mitrastar/libledctl/Makefile                                           \
"
PRODUCT_LIST="\
    GPT-2742GX4X5v6 \
    GPT-2841GX2X2v10 \
    GPT-6841JL4L4v11 \
"

confirm=1

checkDir() {
    if [ ! -d $1 ]; then
        echo "ERROR: Directory '$1' not exists!"; echo
	exit -2
    fi
}

checkProduct() {
    local i
    [ -z "$1" ] && {
        echo -e "ERRROR: Invalid arguments!\n"
        usage
        exit -1
    }
    for i in $PRODUCT_LIST; do
        [ "$1" == "$i" ] && return
    done
    echo "ERROR: product '$1' unsupported!"; echo
    exit -3
}

checkFileList() {
    local f
    if [ -z "$FILE_LIST" ]; then
        echo "ERROR: FILE_LIST is empty!"
        exit -4
    fi
    checkDir $1
    for f in $FILE_LIST; do
        if [ ! -f $1/$f ]; then
            echo "ERROR: file $1/$f not exists! please update FILE_LIST!"
            exit -5
	fi
    done
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

rollback() {
    local d folders externals
    checkDir $1
    [ $confirm -ne 0 ] && \
    if ! confirmYesNo "rollback all codes in $1"; then
	return
    fi
    cd $1
    folders=""
    externals=$(svn propget svn:externals -R| grep -v "^https" | cut -d' ' -f1)
    for d in $externals; do
	#echo "externals: $d"
	folders="$folders $d $(svn propget svn:externals $d|awk -v var=$d 'NF {print var"/"$2}')"
    done
    # remove untracking files
    for d in $(svn st | awk '/^?/{print $2}'); do
        if [ -d $d ]; then
            [ -n "$(svn st $d|grep '^?')" ] && rm -fr $d
#	    [ -n "$(find $d -maxdepth 0 -empty)" ] && \
#                rm -fr $d
	else
            rm -f $d
	fi
    done
    # revert tracking files
    for d in $folders; do
        echo "svn revert -R $d"
	svn revert -R $d
    done
    svn up
    cd - >/dev/null
    echo;echo "Rollback '$1' done!"
    echo
}

checkin() {
    checkDir $1
    checkFileList $1
    cd $1
    svn ci $FILE_LIST
    cd - >/dev/null
}

compilePItrunk() {
    local currDir=$(pwd)
    checkDir $1
    checkProduct $2
    rm -fr $1/build
    cd $1/makecode
    case $2 in
        GPT-2742GX4X5v6)
	    cd trunk-utils/MLD_Scripts
            ./all.sh GPT-2742GX4X5v6
	    cd - >/dev/null
            ;;
        GPT-2841GX2X2v10|GPT-6841JL4L4v11)
            ./configur_MSTC.sh
            ;;
    esac
    make all 2>&1 | tee build.log
    cd $currDir >/dev/null
}

svnOperation() {
    local i
    local totalFiles
    local key
    checkFileList $1
    totalFiles=$(echo $FILE_LIST|awk '{print NF}')
    for i in $FILE_LIST; do
        #echo "svn $2 $1/$i"
        svn $2 $1/$i
	totalFiles=$((totalFiles-1))
	[ $confirm -ne 0 ] && {
            read -n 1 -s -r -p "Press 'q' to exit or others to continue... $totalFiles" key
            echo;echo
	    [ "$key" == "q" ] || [ "$key" == "Q" ] && return
        }
    done
}

syncFiles() {
    local f
    checkDir $1
    checkDir $2
    checkFileList $1
    for f in $FILE_LIST; do 
        echo "$1/$f -> $2/$f"
	if [ -e $2/$f ]; then
            [ $confirm -ne 0 ] && \
                if ! confirmYesNo "overwirte the file $2/$f"; then
                    [ $? -eq 2 ] && return
	            continue
                fi
            rm -fr $2/$f
	fi
        cp $1/$f $2/$f
    done
    echo
}

diffFiles() {
    local f key totalFiles
    checkDir $1
    checkDir $2
    checkFileList $1
#    checkFileList $2
    totalFiles=$(echo $FILE_LIST|awk '{print NF}')
    for f in $FILE_LIST; do
	totalFiles=$((totalFiles-1))
        diff -puN $2/$f $1/$f
	[ $confirm -ne 0 ] && {
            read -n 1 -s -r -p "Press 'q' to exit or others to continue... $totalFiles" key
            echo;echo
	    [ "$key" == "q" ] || [ "$key" == "Q" ] && return
        }
    done
    echo
}

patchFiles() {
    local i f key patchDir patchFile
    checkDir $1
    checkDir $2
    checkFileList $1
    i=0
    patchDir=$(mktemp -d)
    [ -d $2/patches ] && {
        rm -fr $2/patches
        rm -fr $2/.pc
    }
    for f in $FILE_LIST; do
	patchFile=$(printf "%04d-%s.patch" $i  ${f//\//_})
	if ! svn diff -x -p $1/$f > $patchDir/$patchFile; then
            rm -fr $patchDir
            exit -6
	fi
	echo $patchFile >> $patchDir/series
	i=$((i+1))
    done
    mv $patchDir $2/patches
    cd $2 
    if ! quilt push -a; then
        cd - >/dev/null
	echo;echo "patch failed, use following commands to revert files!"
	echo -e "cd $2\nquilt pop -a && rm -fr .pc patches\ncd -\n"
	exit -7
    fi
    cd - >/dev/null
    echo
}

showListVarable() {
    local i
    [ -n "$1" ] && { 
        for i in $1; do
            echo -e "$2$i"
            done	
    }
}

showFiles() {
    showListVarable "$FILE_LIST" "$1"
}

showProduct() {
    showListVarable "$PRODUCT_LIST" "$1"
}

LABEL_LEN=12
usage() {
    echo "Usage: $(basename $0) <top_dir> {checkin|compile <product>|diff|rollback|st} [-y]"
    printf "  %-${LABEL_LEN}s %s\n" "checkin" "check-in following files which stored in 'top_dir'"
    printf "  %-${LABEL_LEN}s %s\n" "compile" "compile the code in 'top-folder'"
    printf "  %-${LABEL_LEN}s %s\n" "dff" "compare two files, use unified format to show differences"
    printf "  %-${LABEL_LEN}s %s\n" "rollback" "rollback all files in folder 'top_dir' by using SVN command 'svn revert'"
    printf "  %-${LABEL_LEN}s %s\n" "st" "check file state by SVN command 'svn st'"
    echo
    echo "Usage: $(basename $0) <src_dir> <dst_dir> {diff|patch|sync} [-y]"
    printf "  %-${LABEL_LEN}s %s\n" "diff" "compare two files, use unified format to show differences"
    printf "  %-${LABEL_LEN}s %s\n" "patch" "generate file patches from 'src_dir' and use quilt to apply patch to 'dst_dir'"
    printf "  %-${LABEL_LEN}s %s\n" "sync" "copy following files from folder 'src_dir' to 'dst_dir'"
    echo
    echo "options:"
    printf "  %-${LABEL_LEN}s %s\n" "-y" "assume \"yes\" as answer to all prompts and run non-interactively"
    echo
    echo "files:"
    showFiles "\t"
    echo
    echo "product:"
    showProduct "\t"
}

errNo=0
topdir=$1
cmd=$2

[ $# -eq 0 ] && usage && exit 0

[ "$3" == "-y" ] && confirm=0
case $cmd in
    diff)
        svnOperation $topdir diff
	;;
    st|state)
	confirm=0
        svnOperation $topdir st
	;;
    rollback)
        rollback $topdir
        ;;
    checkin)
        checkin $topdir
        ;;
    compile)
        product=$3
        [ "$4" == "-y" ] && confirm=0
        compilePItrunk $topdir $product
        ;;
    *)
        src_dir=$1
	dst_dir=$2
	cmd=$3
        [ "$4" == "-y" ] && confirm=0
        case $cmd in
        sync)
	    syncFiles $1 $2
            ;;
        diff)
            diffFiles $1 $2
	    ;;
        patch)
            patchFiles $1 $2
            ;;
	*)
            errMsg="ERRROR: Invalid arguments!"
            errNo=-1
	esac
esac

[ $errNo -ne 0 ] && {
    echo;echo $errMsg;echo
    usage $0
}
exit $errNo

