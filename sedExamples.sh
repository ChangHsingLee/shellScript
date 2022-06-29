#/bin/sh

# Set first character in each word to uppercase and others to lowercase
# This captures two groups for each word (a word character, followed by zero or more word characters). 
# The replacement uses \U to upper-case the first group and \L to lower-case the rest.
# \w is shorthand for [[:alnum:]_], i.e. anything considered to be a letter or digit in your locale, plus _.
echo "abc3.def.gg3" | sed -E 's/(\w)(\w*)/\U\1\L\2/g; s/\.//g'
echo "abc3 def gg3" | sed -E 's/(\w)(\w*)/\U\1\L\2/g; s/\.//g'
