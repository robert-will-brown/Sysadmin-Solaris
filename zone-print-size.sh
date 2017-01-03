#!/usr/bin/ksh
#
# Calculate the disk space used by each zone.
#
# rob.brown@ioko.com
#

#
# If we are in a non-global zone then exit.
#
if [ "$(zonename)" != "global" ]; then
   echo "$(basename ${0}) must be run from the global zone."
   exit 1
fi

echo "calculating..."

FORMAT="%10s"
printf "${FORMAT} ZONE\n" "SIZE"

zoneadm list -cv |tail +3 |while read ZONE_LINE
do
	ZONE_FS=$(echo ${ZONE_LINE} |awk '{print $4}')
	ZONE=$(echo ${ZONE_LINE} |awk '{print $2}')
	ZONE_SIZE=$(du -sh ${ZONE_FS} |awk '{print $1}')
	
	printf "${FORMAT} ${ZONE}\n" "${ZONE_SIZE}"
done 
