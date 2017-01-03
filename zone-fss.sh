#!/usr/bin/ksh
#
# Script to allow the listing and setting of how many
# Fair Share Scheduling "shares" each zone can have.
#
# rob.brown@ioko.com - Oct 7 2008
#
FORMAT="%10s"

#
# If we are in a non-global zone then exit.
#
if [ "$(zonename)" != "global" ]; then
   echo "$(basename ${0}) must be run from the global zone."
   exit 1
fi


print_fss_shares()
{
	printf "${FORMAT} ZONE\n" "SHARES"

	for ZONE in `zoneadm list`
	do
		SHARES=`prctl -n zone.cpu-shares -i zone ${ZONE} |grep "privileged" |awk '{print $2}'`
		printf "${FORMAT} ${ZONE}\n" "${SHARES}"
	done
}

print_usage()
{
	echo "Usage: `basename $0` [ list | set <Zone Name> <Number of Shares> ]"
}

if [ $# -lt 1 ]; then
	print_usage
else
	case ${1} in
		"set")
			if [ $# -lt 3 ]; then
				print_usage
				exit 1	
			else
				ZONE_NAME=$2
				SHARE_COUNT=$3

				#
				# Check the zone exists.
				#
				ZONEADM_OUT=`zoneadm -z ${ZONE_NAME} list 2>&1 > /dev/null`
				if [ "${?}" != "0" ]; then
					echo "$ZONE_NAME is not a valid zone"
					exit 1
				fi

				#
				# Set the amount of shares.
				#
				prctl -n zone.cpu-shares -v ${SHARE_COUNT} -r -i zone ${ZONE_NAME}
			fi
			print_fss_shares
		;;
		"list"|"l"|"-l"|"-list"|"--list")
			print_fss_shares
		;;
		*)
			print_usage
		;;
	esac
fi
