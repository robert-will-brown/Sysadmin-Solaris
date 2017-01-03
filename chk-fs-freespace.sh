#!/usr/bin/ksh
#
# Purpose: Check if filesystems are full
# Platfrom: All 
# robert.will.brown@gmail.com
# 1/Sep/2008 
#
HIGH_WATER="80"

for FS_CAPACITY in `df -k |awk '{print $5}' |grep % |cut -f1 -d%`
do
	if [ "${FS_CAPACITY}" -gt "${HIGH_WATER}" ]; then
		echo "Filesystem over 80%"
	fi
done
