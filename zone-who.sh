#!/usr/bin/ksh
#
# Show who is logged into which Zone.
#
# rob.brown@ioko.com - 24/Oct/2008
#

#
# Global Zones
#
LOCAL_WHO=`who -q |grep '# users=' |cut -f2 -d=`
if [ "${LOCAL_WHO}" != "0" ]; then
	echo "--> `zonename` <--"
	finger |tail +2
fi


#
# Local Zones
#
for ZONE in `zoneadm list |grep -v global`
do
	WHOSON=`zlogin ${ZONE} "who -q |grep \"# users=\" |cut -f2 -d="`
	if [ "${WHOSON}" != "0" ]; then
		echo ""
		echo "--> ${ZONE} <--"
		zlogin ${ZONE} finger |tail +2
	fi
done

