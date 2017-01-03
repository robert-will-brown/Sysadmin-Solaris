#!/usr/bin/ksh
#
# Print HBAs and usefull information.
#
# robert.will.brown@gmail.com
# 1/Jan/2009
#
PATH=/usr/sbin:/usr/bin

# Are we in a zone?
if [ -x /usr/bin/zonename -a "`/usr/bin/zonename`" != "global" ]; then
	echo "`basename $0` does not support running from a non global zone"
	exit 1
else
	printf "%-20s%-20s%-20s%-20s\n" "Device" "WWN" "State" "Speed" 

	for WWN in `fcinfo hba-port |grep "HBA Port WWN:" |sed 's/HBA Port WWN: //g'`
	do
		DEVICE=`fcinfo hba-port ${WWN} |grep "OS Device Name: " |sed 's/OS Device Name: //g'`
		STATE=`fcinfo hba-port ${WWN} |grep "State: " |sed 's/State: //g'`
		SPEED=`fcinfo hba-port ${WWN} |grep "Current Speed: " |sed 's/Current Speed: //g'`

		printf "%-20s%-20s%-20s%-20s\n" $DEVICE $WWN $STATE $SPEED
	done
fi
