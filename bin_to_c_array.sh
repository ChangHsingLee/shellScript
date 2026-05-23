#!/bin/bash

INCLUDE_HEADER=0
ZIP_COMPRESS=0
ARRAY_NAME=""

# Display usage instructions
usage() {
    echo "Usage: $0 [-i] [-z] [-n <name>] <input_file>"
    echo "Options:"
    echo "  -i        Include 8-byte Big Endian verification header (4-byte file size + 4-byte CRC32)"
    echo "  -n <name> Specify a custom C array name"
    echo "  -z        Use zip to compress data and then convert to the C array"
    echo "Example:"
    echo "  $0 -i -n an8833x_fw as21x1x_fw.bin"
    exit 1
}

# Parse options using standard getopts
while getopts "izn:" opt; do
    case "$opt" in
        i)
            INCLUDE_HEADER=1
            ;;
        n)
            ARRAY_NAME="$OPTARG"
            ;;
	z)
            ZIP_COMPRESS=1
	    ;;
        *)
            usage
            ;;
    esac
done

# Shift arguments so that $1 becomes the <input_file>
shift $((OPTIND - 1))

ORIGINAL_FILE="$1"

# Check if input file argument is provided and valid
if [ -z "$ORIGINAL_FILE" ] || [ ! -f "$ORIGINAL_FILE" ]; then
    echo "Error: Input file valid path is required."
    usage
fi

# Determine the array name
if [ -z "$ARRAY_NAME" ]; then
    ARRAY_NAME=$(basename "$ORIGINAL_FILE" | tr '.-' '__')
fi

# 1. Get original file size (4 bytes integer)
FILE_SIZE=$(wc -c < "$ORIGINAL_FILE")

# 2. Calculate CRC32 of the original binary file
if command -v crc32 >/dev/null 2>&1; then
    #CRC_HEX=$(crc32 "$ORIGINAL_FILE")
    CRC_HEX=$(printf "%08X" 0x$(crc32 "$ORIGINAL_FILE"))
else
    exit 2
fi

# 3. Create a temporary file to construct the Big Endian Header + Payload
INPUT_BIN=$(mktemp)

if [ $INCLUDE_HEADER -ne 0 ]; then

    # Write 4 bytes of File Size in BIG ENDIAN format (Most Significant Byte first)
    printf "0: %02x%02x%02x%02x" \
        $(((FILE_SIZE >> 24) & 0xFF)) \
        $(((FILE_SIZE >> 16) & 0xFF)) \
        $(((FILE_SIZE >> 8) & 0xFF)) \
        $((FILE_SIZE & 0xFF)) | xxd -r - "$INPUT_BIN"

    # Append 4 bytes of CRC32 in BIG ENDIAN format (Most Significant Byte first)
    CRC_VAL=$((16#$CRC_HEX))
    printf "0: %02x%02x%02x%02x" \
        $(((CRC_VAL >> 24) & 0xFF)) \
        $(((CRC_VAL >> 16) & 0xFF)) \
        $(((CRC_VAL >> 8) & 0xFF)) \
        $((CRC_VAL & 0xFF)) | xxd -r - >> "$INPUT_BIN"

    # Append the original binary data payload
    cat "$ORIGINAL_FILE" >> "$INPUT_BIN"
else
    cp "$ORIGINAL_FILE" "$INPUT_BIN"
fi

if [ $ZIP_COMPRESS -ne 0 ]; then
    ARRAY_DECOMPRESSED_SIZE=$(wc -c < "$INPUT_BIN")
    zip -q9 ${INPUT_BIN}.zip $INPUT_BIN
    rm -f $INPUT_BIN
    INPUT_BIN=${INPUT_BIN}.zip
fi
# 4. Start generating C file content
ARRAY_SIZE=$(wc -c < "$INPUT_BIN")

echo "/* This is automatically generated file */"
echo "/* Original Filename       : $(basename "$ORIGINAL_FILE") */"
echo "/* File Size               : $FILE_SIZE ($(printf "0x%X" $FILE_SIZE)) Bytes */"
echo "/* File CRC32              : 0x$CRC_HEX */"
echo "/* Array Size              : $ARRAY_SIZE ($(printf "0x%X" $ARRAY_SIZE)) Bytes */"
[ $ZIP_COMPRESS -ne 0 ] && \
echo "/* Array Decompressed Size : $ARRAY_DECOMPRESSED_SIZE ($(printf "0x%X" $ARRAY_DECOMPRESSED_SIZE)) Bytes */"
echo
echo "const unsigned char ${ARRAY_NAME}[] = {"

# Format the combined binary data into C hex format (12 bytes per line)
xxd -i < "$INPUT_BIN" | sed 's/^/    /g'

echo "};"
echo

# Clean up temporary file
rm -f "$INPUT_BIN"
