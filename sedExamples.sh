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
# to strip the first 5 characters of each line
sed -i 's/^.\{5\}//g' logfile
