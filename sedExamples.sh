#/bin/sh

# Set first character in each word to uppercase and others to lowercase and remove whitespace
# This captures two groups for each word (a word character, followed by zero or more word characters). 
# The replacement uses \U to upper-case the first group and \L to lower-case the rest.
# \w is shorthand for [[:alnum:]_], i.e. anything considered to be a letter or digit in your locale, plus _.
echo "abc3 def gg3" | sed -E 's/(\w)(\w*)/\U\1\L\2/g; s/ //g'
# Set first character in each word to uppercase and others to lowercase and charcter '.'
echo "abc3.def.gg3" | sed -E 's/(\w)(\w*)/\U\1\L\2/g; s/\.//g'

# change character ':', '/' or '-' to '.' in string
echo "test/string-1234" | sed 's/[\/:-]/\./g'

# 
echo 'eqid           = "test_id"' | sed '/eqid.*=/ s/=.*/= "New ID"/g'

# Print lines between two patterns (refer to https://www.baeldung.com/linux/print-lines-between-two-patterns)
# Syntax: sed -n /Pattern1/, /Pattern2/{ commands... }
# Printing the Data Blocks Including Both Boundaries
sed -n '/Pattern1/, /Pattern2/p' input.txt
# Printing the Data Blocks Excluding Both Boundaries
sed -n '/Pattern1/, /Pattern2/{ /Pattern1/! { /Pattern2/! p } }' input.txt
# Printing the Data Blocks Excluding Lines which including 3th pattern
sed -n '/Pattern1/, /Pattern2/{ /Pattern3/!p }' input.txt
# cat string between '<' and '>'
echo "for test <MyTest String>!!!" | sed -n 's/.*<\(.*\)>.*/\1/p'
echo "for test <MyTest String>!!!" | sed -r 's/.*<(.*)>.*/\1/'
echo "for test <MyTest String1>!!!<MyTest String2>QQQ" | sed -r 's/.*<(.*)>.*<(.*)>.*/\1 \2/'
# replace string between '{' and '}'
echo "for test {MyTest String}!!!" | sed -E "s/(.*\{).*(\}.*)/\1String Be Changed\2/g"
# to strip the first 5 characters of each line
sed -i 's/^.\{5\}//g' logfile
# remove line which start from char. '#'
sed -i '/^\s*\#/d' testFile.txt
# insert word or text after position 'n' of each line; example n=7, insert txt="DualFW_", output => IMG000_DualFW_GPT-5610C1_TW_20240308141827.img
echo IMG000_GPT-5610C1_TW_20240308141827.img | sed 's/./&DualFW_/7'
# insert word or text after match in middle of the line; example pattern=GPT-5610C1_, insert txt="DualFW_", output => IMG000_GPT-5610C1_DualFW_TW_20240308150642.img
echo IMG000_GPT-5610C1_TW_20240308150642.img|sed 's/GPT-5610C1_/&DualFW_/'
# remove trailing characters '0'
echo "91245d0b00ab000200120400f800000080010000400f0000000800103e02c2b6000000000000000000000000" | sed 's/0*$//'
# count number of lines
 sed -n '$=' <file name>
 
