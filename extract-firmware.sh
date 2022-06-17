#!/bin/bash

# Extract firmware image from dumped NAND flash image

# $1: exit code
# $2: output message
exitScript() {
	[ $1 -ne 0 ] && rm -fr $folder
	[ -n "$2" ] && echo $2
	exit $1
}

usage() {
	echo "Usage: extract-firmware.sh <model> <file>"
	printf "\tmodel: select partition layout by model name\n"
	for ((i=0; i<${#modelList[@]}; i++)); do
		printf "\t\t%s\n" ${modelList[$i]}
	done
	printf "\tfile: input file (dumped flash image)\n"
	exitScript $1
}

# i6901-20: page size=2048 bytes, block size=128Kbytes, OOB size=64 bytes
i6901_20_flashInfo=(2048 128 64)
# i6901-20: partition size (Unit: byte)
i6901_20_partSize=(0x140000 0x100000 0x100000 0x120000 0xce0000 0x1c0000 0x1900000 0x2700000 0x900000 0x1E00000)
# i6901-20: partition name
i6901_20_partName=(boot_master uboot1 uboot2 env config cust_data customer kfs1 mstc_envcfg kfs2)

# i486x: page size=2048 bytes, block size=128Kbytes, OOB size=64 bytes
i486x_flashInfo=(2048 128 64)
# i486x: partition size (Unit: byte)
i486x_partSize=(0x140000 0x100000 0x100000 0x120000 0x1ba0000 0x300000 0x1700000 0x6000000 0x6000000)
# i486x: partition name
i486x_partName=(boot_master uboot1 uboot2 env config data customer kfs1 kfs2)

# flashInfo: Flash Information Array
# [0]: page size (byte)
# [1]: block/erase size (kbyte)
# [2]: OOB size (byte)
# Example: flashInfo=("${i6901_20_flashInfo[@]}")

# partOffset: partition size for each partition
# Example: partSize=("${i6901_20_partSize[@]}")

# partName: partition name for each partition
# Example: partName=("${i6901_20_partName[@]}")

modelList=(i6901-20 i6902-20 i6905-20 i4861 i4863)

case "$1" in
	i690x|"i6901-20"|"i6902-20"|"i6905-20")
		flashInfo=("${i6901_20_flashInfo[@]}")
		partSize=("${i6901_20_partSize[@]}")
		partName=("${i6901_20_partName[@]}")
		;;
	i486x|i4861|i4863)
		flashInfo=("${i486x_flashInfo[@]}")
		partSize=("${i486x_partSize[@]}")
		partName=("${i486x_partName[@]}")
		;;
	*)
		[ -z "$1" ] && {
			echo "!!! You should specify model name !!!";echo
			usage 1
		}
		exitScript 1 "Error: Unknown model name $1!"
esac
modelName=$1
shift

[ ${#partSize[@]} -ne ${#partName[@]} ] && \
	exitScript 2 "Internal Error: Wrong partition information"

[ -z "$1" ] && {
	echo "!!! You should specify input file !!!";echo
	usage 3
}

flashImg=Images/$1
offset=0
pageSize=$((flashInfo[0]))
blockSize=$((flashInfo[1]*1024))
oobSize=$((flashInfo[2]))
progressSign=(- \\ \| /)

folder=Images/${modelName}.fw-`date +%Y%m%d_%H%M%S`

[ -f $flashImg ] || exitScript 4 "Error: file '$flashImg' not exist!"

[ $((blockSize%pageSize)) -ne 0 ] && \
	exitScript 5 "Error: Block size not divisble by page size!"

rm -fr $folder && mkdir -p $folder

printf "$modelName Flash Information:\n"
printf "\t Page Size: $pageSize Bytes\n"
printf "\tBlock Size: $blockSize Bytes\n"
printf "\t  OOB Size: $oobSize Bytes\n"
# partition loop
for ((i=0; i<${#partSize[@]}; i++)); do
	#printf "partSize 0x%x mask 0x%x\n" ${partSize[$i]} $((blockSize-1))
	[ $((partSize[$i] & (blockSize-1))) -ne 0 ] && \
		exitScript 6 "Error: ${partName[$i]} partition size is not aligned!"
	pages=$((partSize[$i]/pageSize))
	printf "\nExtract partition$i\n"
	printf "\t  Name: ${partName[$i]}\n"
	printf "\t  Size: $((partSize[$i])) Bytes\n"
	printf "\t Image: $folder/${partName[$i]}.img\n"
	printf "\tStatus: "
	# first image(master loader) must be including OOB data, can not skip
	if [ $i -eq 0 ]; then
		count=$((pageSize+oobSize))
		fileSize=$(((pageSize+oobSize)*pages))
	else
		count=$pageSize
		fileSize=$((partSize[$i]))
	fi
	for ((j=0; j<pages; j++)); do
		printf "${progressSign[$((j%4))]}"
		dd if=$flashImg bs=1 skip=$offset count=$count >> $folder/${partName[$i]}.img 2>/dev/null
		offset=$((offset+pageSize+oobSize))
		printf "\b"
	done
	if [ `stat -c %s $folder/${partName[$i]}.img` -ne $fileSize ]; then
		# size of extracted image must equal to partition size, except last partition/image
		[ $((i+1)) -ne ${#partSize[@]} ] && exitScript 7 "Extract failed!"
	fi
	echo "Done"
done
exitScript 0
