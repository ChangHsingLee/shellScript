#!/bin/sh
# Change date time string "YYYY/MM/DD hh:mm:ss" to Epoch time
date --date='2024/01/22 12:30:06' +%s
# Change Epoch time to date time string "YYYY/MM/DD hh:mm:ss"
date --date='@1705897806' +"%Y/%m/%d %H:%M:%S"
# 
