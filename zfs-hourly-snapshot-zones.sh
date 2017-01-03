#!/usr/bin/ksh
#
# Run from cron - Snapshot all the named zfs filesystems.
#
# rob.brown@ioko.com
#
HOUR=`date +%I`
MERIDIEM=`date +"%r" |awk '{print $2}' |tr "[A-Z]" "[a-z]"`

# Pretty it up
FIRST_HOUR_NUMBER=`echo ${HOUR} |cut -c1`
SECOND_HOUR_NUMBER=`echo ${HOUR} |cut -c2`
if [ "${FIRST_HOUR_NUMBER}" = "0" ]; then
	HOUR=${SECOND_HOUR_NUMBER}
fi

for ZONE_DIR in `zoneadm list -p |cut -f4 -d: |tail +2`
do
	# 
	# We have the path to the zone, now get the Zone Filesystem.
	#
	ZFS_LIST_OUT=`zfs list -H ${ZONE_DIR}`
	if [ "${?}" = "0" ]; then
		ZFS_FS=`echo ${ZFS_LIST_OUT} |awk '{print $1}'`
		SNAPSHOT_NAME=${ZFS_FS}@${HOUR}${MERIDIEM}

		#
		# Does the snapshot filesystem exist?
		#
		zfs list ${SNAPSHOT_NAME} 2>/dev/null 1>/dev/null
		RETURN_CODE=$?
		if [ "${RETURN_CODE}" = "0" ]; then
			#
			# It exists already, (probably from 24 hours ago) so blow it away.
			#
			zfs destroy ${SNAPSHOT_NAME}
		fi

		#
		# Create the snapshot.
		#
		zfs snapshot ${SNAPSHOT_NAME} 

	fi
done
