#!/usr/bin/ksh
#
# Show zones and proccess count.
#
# robert.will.brown@gmail.com - 9/Oct/2008
while sleep 3
do
	clear
	date
	zoneadm list -cv
	echo "\nProcess count: `ps -ef |wc -l |awk '{print $1}'`"
done
