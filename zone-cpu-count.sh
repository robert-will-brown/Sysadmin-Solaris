#!/usr/bin/ksh
#
# Print the number of CPUs allocated to each Zone
#
# rob.brown@ioko.com - 9/Oct/2008
#
FORMAT="%10s"


#
# If we are in a non-global zone then exit. 
#
if [ "$(zonename)" != "global" ]; then
	echo "$(basename ${0}) must be run from the global zone."
	exit 1
fi

printf "${FORMAT} ZONE\n" "CPU(s)"


#
# First the Global Zone
#
CPU_COUNT=`psrinfo |wc -l |awk '{print $1}'`
printf "${FORMAT} `zonename`\n" "${CPU_COUNT}"


#
# Now all non-global Zones
#
for ZONE in `zoneadm list |grep -v global`
do
	CPU_COUNT=`zlogin ${ZONE} "psrinfo |wc -l" |awk '{print $1}'`
	printf "${FORMAT} ${ZONE}\n" "${CPU_COUNT}"
done
