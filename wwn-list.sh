#!/usr/bin/ksh
#
# Print all the WWNs of this hosts HBAs.
#
# robert.will.brown@gmail.com - 1/Jan/2009
#

#
# Test if we are in the global zone, if we are then execute.
#
if [ -x /usr/bin/zonename -a "`/usr/bin/zonename`" != "global" ]; then
	echo "`basename $0` does not support running from a non global zone"
	exit 1
else
	/usr/sbin/fcinfo hba-port |grep "HBA Port WWN:" |sed 's/HBA Port WWN: //g'
fi
