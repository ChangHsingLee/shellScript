#!/bins/sh
# find any files '*.py' but ignore folder 'build'
find . -name build -type d -prune -o -name *.py
