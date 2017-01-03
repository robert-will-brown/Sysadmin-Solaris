#!/usr/bin/ksh
#
# Show zones and proccess count.
#
while sleep 3
do
	clear
	date
	zoneadm list -cv
	echo "\nProcess count: `ps -ef |wc -l |awk '{print $1}'`"
done
