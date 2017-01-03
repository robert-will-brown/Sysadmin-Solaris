#!/usr/bin/ksh
#
# Prints the time since epoch in seconds
#
# rob.brown@ioko.com
#
/usr/bin/truss /usr/bin/date 2>&1 | /usr/bin/awk '/^time/ {print $NF}'
