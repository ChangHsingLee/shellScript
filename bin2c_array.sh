#!/bin/bash

# Check input arguments
if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <input_binary_file> [array_name]"
    echo "Example: $0 as21x1x_fw.bin my_fw_array"
    exit 1
fi

INPUT_FILE="$1"

# Check if the file exists
if [ ! -f "$INPUT_FILE" ]; then
    echo "Error: File '$INPUT_FILE' not found."
    exit 1
fi

# Determine the array name: fallback to filename with sanitized characters if not provided
if [ -z "$2" ]; then
    ARRAY_NAME=$(basename "$INPUT_FILE" | tr '.-' '__')
else
    ARRAY_NAME="$2"
fi

# Get file size in bytes
FILE_SIZE=$(wc -c < "$INPUT_FILE")

# Start generating C file content
echo "/* Automatically generated binary-to-C array file */"
echo "/* Original filename: $(basename "$INPUT_FILE") */"
echo "/* File size: $FILE_SIZE Bytes */"
echo ""
echo "const unsigned char ${ARRAY_NAME}[] = {"

# Format output: 12 bytes per line with 0xXX format
# Clean up trailing commas and apply clean indentation
hexdump -v -e '12/1 "0x%02x, " "\n"' "$INPUT_FILE" | sed 's/, $//g' | sed 's/^/    /g'

echo "};"
echo ""
echo "const unsigned int ${ARRAY_NAME}_len = $FILE_SIZE;"
