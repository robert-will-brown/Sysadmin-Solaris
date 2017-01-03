#!/usr/bin/ksh
#
# Count the number of installed zones quickly.  If you've <500 zones then 
# zoneadm can take a long time to return.
#
# rob.brown@ioko.com - 1/Apr/2009
#
if [ ! -f /etc/zones/index ]; then
	echo "Can't find /etc/zones/index"
	exit 1
fi

grep ':installed:' /etc/zones/index |wc -l |awk '{print $1}'
