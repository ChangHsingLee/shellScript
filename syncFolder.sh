#!/bin/sh
[ -z "$FILE_LIST" ] && \
FILE_LIST="\
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

syncRevision() {
    local subDIR1 subDIR2 dir1 dir2
    if ! confirmYesNo "rollback all codes in $1 to SVN revision $2"; then
	return
    fi
    pushd . >/dev/null
    cd $1
    subDIR1=$(svn pg svn:externals -R | grep -v -E "^http"|cut -d' ' -f1|sort)
    for dir1 in $subDIR1; do
        pushd . >/dev/null
        cd $dir1
        subDIR2=$(svn pg svn:externals .|cut -d' ' -f2|sort)
        for dir2 in $subDIR2; do
                pushd . >/dev/null
                cd $dir2 >/dev/null
                echo $PWD
                svn up -r $2
                popd >/dev/null
        done
        popd >/dev/null
    done
    popd >/dev/null
}

showRevision() {
    local d folders externals
    checkDir $1
    cd $1
    folders=""
    externals=$(svn propget svn:externals -R|grep -v "^https"|cut -d' ' -f1|sort)
    for d in $externals; do
	#echo "externals: $d"
	folders="$folders $d $(svn propget svn:externals $d|awk -v var=$d 'NF {print var"/"$2}'|sort)"
    done
    # show revision
    for d in $folders; do
        echo "$d: r$(svn info $d|grep Revision|cut -d' ' -f2)"|sed 's/^.\///g'
    done
    cd - >/dev/null
}

revert() {
    local d folders externals
    checkDir $1
    [ $confirm -ne 0 ] && \
    if ! confirmYesNo "revert all codes in $1"; then
	return
    fi
    cd $1
    folders=""
    externals=$(svn propget svn:externals -R|grep -v "^https"|cut -d' ' -f1|sort)
    for d in $externals; do
	#echo "externals: $d"
	folders="$folders $d $(svn propget svn:externals $d|awk -v var=$d 'NF {print var"/"$2}'|sort)"
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
    echo;echo "Revert '$1' done!"
    echo
}

checkin() {
    local f
    checkDir $1
    checkFileList $1
    cd $1
    for f in $FILE_LIST; do
        # add new file
        if [ -n "$(svn st $f | grep '^?')" ]; then
            #echo "svn add $f"
            svn add $f
        fi
    done
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

genPatches() {
    local srcDir=$1
    local patchDir=$2
    local i f patchFile tmpDir

    checkDir $srcDir
    checkFileList $srcDir
    if [ -e $patchDir ]; then
	[ -z "$(find $patchDir -maxdepth 0 -empty)" ] && { \
            # If folder is not empty, confirmation is needed before overwriting
	    [ $confirm -ne 0 ] && {
                if ! confirmYesNo "$patchDir is not empty! overwrite it"; then
                    echo; echo "Abort process, skip to generate patch file!"; echo
	            exit -6
                fi
            }
            tmpDir=$(mktemp -d) && mv $patchDir $tmpDir/ && rm -fr $tmpDir &
            mkdir -p $patchDir
	}
    else
        mkdir -p $patchDir
    fi
    i=0
    for f in $FILE_LIST; do
	patchFile=$(printf "%04d-%s.patch" $i ${f//\//_})
	if ! svn diff -x -p $srcDir/$f > $patchDir/$patchFile; then
            rm -fr $patchDir
            exit -7
	fi
        if [ -s $patchFile ]; then
            # file is empty (file not be modified)
            rm -f $patchFile
        else
            echo $patchFile >> $patchDir/series
        fi
	i=$((i+1))
    done
}

patchFiles() {
    local patchDir

    checkDir $2
    # generate patch files
    patchDir=$(mktemp -d)
    genPatches $1 $patchDir
    [ -d $2/patches ] && {
        rm -fr $2/patches
        rm -fr $2/.pc
    }
    mv $patchDir $2/patches
    # appliy aptches
    cd $2 
    if ! quilt push -a; then
        cd - >/dev/null
	echo;echo "patch failed, use following commands to restore files!"
	echo -e "cd $2\nquilt pop -a && rm -fr .pc patches\ncd -\n"
	exit -8
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

LABEL_LEN=20
usage() {
    echo "Usage1: [FILE_LIST=\"file1 file2 ...\"] $(basename $0) <top_dir> <OPTION> [-y]"
    echo "OPTION is one of below options:"
    printf "  %-${LABEL_LEN}s %s\n" "checkin" "check-in specific files which stored in 'top_dir'"
    printf "  %-${LABEL_LEN}s %s\n" "compile <product>" "compile the code in 'top_dir', supported products:"
    showProduct "$(printf "  %-$((LABEL_LEN+4))s " " ")"
    printf "  %-${LABEL_LEN}s %s\n" "diff" "show modifications with unified format for specific files from 'top_dir' by SVN"
    printf "  %-${LABEL_LEN}s %s\n" "patch" "generate patches of specific files from 'top_dir' by SVN"
    printf "  %-${LABEL_LEN}s %s\n" "revert" "remove untracked files and revert specific files in 'top_dir' by SVN"
    printf "  %-${LABEL_LEN}s %s\n" "st" "check status of specific files in 'top_dir' by SVN"
    printf "  %-${LABEL_LEN}s %s\n" "showRev" "show all SVN revision(including externals) in 'top_dir'"
    printf "  %-${LABEL_LEN}s %s\n" "syncRev <rev>" "sync SVN revision(including externals) in 'top_dir'"
    echo
    echo "Usage2: [FILE_LIST=\"file1 file2 ...\"] $(basename $0) <src_dir> <dst_dir> <OPTION> [-y]"
    echo "OPTION is one of below options:"
    printf "  %-${LABEL_LEN}s %s\n" "diff" "compare specific files between 'src_dir' and 'dst_dir', and show the differences in unified format"
    printf "  %-${LABEL_LEN}s %s\n" "patch" "generate patches of specific files from 'src_dir' by SVN and apply them to 'dst_dir' with quilt"
    printf "  %-${LABEL_LEN}s %s\n" "sync" "copy specific files from folder 'src_dir' to 'dst_dir'"
    echo
    echo "option -y: assume \"yes\" as answer to all prompts and run non-interactively"
    echo
    echo "specific files: files are listed in environment variable 'FILE_LIST'"
    showFiles "\t"
    echo
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
    revert)
        revert $topdir
        ;;
    checkin)
        checkin $topdir
        ;;
    compile)
        product=$3
        [ "$4" == "-y" ] && confirm=0
        compilePItrunk $topdir $product
        ;;
    patch)
       genPatches $topdir $topdir/patches
       ;;
    showRev)
       showRevision $topdir
       ;;
    syncRev)
       [ "$4" == "-y" ] && confirm=0
       syncRevision $topdir $3
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

