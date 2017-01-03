#!/usr/bin/ksh
#
# Prints the time since epoch in seconds
#
# robert.will.brown@gmail.com @ioko
# 26/Oct/2008 
#
/usr/bin/truss /usr/bin/date 2>&1 | /usr/bin/awk '/^time/ {print $NF}'
