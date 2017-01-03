#!/usr/bin/ksh
#
# Control all zones in one hit
#
# robert.will.brown@gmail.com - 26/Oct/2008
#
FORMAT="%10s"

if [ "${#}" = "0" ];
then
	echo "Usage: `basename ${0}` <bootall> <haltall> <print-autoboot> <autoboot-true-all> <autoboot-false-all>"
	exit 1
else
	ACTION=$1
	ZONES=`zoneadm list -c |grep -v global`
fi

case ${ACTION} in
	"bootall") 
		for ZONE in $ZONES
		do
			zoneadm -z $ZONE boot
		done
	;;

	"haltall")
		for ZONE in $ZONES
		do
			zoneadm -z $ZONE halt
		done
	;;

	"print-autoboot")
		printf "${FORMAT} ZONE\n" "AUTOBOOT?"
		for ZONE in $ZONES
		do
			AUTOBOOT_STATUS=`zonecfg -z $ZONE info|grep autoboot |sed "s/autoboot: //g"`
			printf "${FORMAT} ${ZONE}\n" "${AUTOBOOT_STATUS}"
		done
	;;

	"autoboot-true-all")
		echo "Not yet implemented"
	;;

	"autoboot-false-all")
		echo "Not yet implemented"
	;;

	*)
		echo "command ${ACTION} not recognised"
		exit 1
	;;
esac



