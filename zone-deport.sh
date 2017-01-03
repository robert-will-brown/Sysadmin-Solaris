#!/usr/bin/ksh
#
# Deport a zone and stick it on shared storage.
# RB
# robert.will.brown@gmail.com - 9/Oct/2008
#
#
ZFS_SEND_PATH=/share/dump
THIS_SCRIPT=`basename ${0}`
ZONE=$1

#
# If we are in a non-global zone then exit.
#
if [ "$(zonename)" != "global" ]; then
   echo "$(basename ${0}) must be run from the global zone."
   exit 1
fi


if [ "${1}" = "" ]; then
	echo "Usage: ${THIS_SCRIPT} <Zone Name>"
	exit 1
fi


#
# Check the zone exists and get the zoneadm detail if it does
#
ZONE_CONFIG=`zoneadm -z ${ZONE} list -p`
if [ ${?} != "0" ]; then
	echo "problem with $ZONE, does it exist?"
	exit 1
fi


#
# See if someone has already deported this zone and created a file.
# if they have then prompt whether to overwrite it or not.
#
if	[ -f ${ZFS_SEND_PATH}/${ZONE} ];then
	echo "WARNING: ${ZFS_SEND_PATH}/${ZONE} exists already, do you want to overwrite? (y/n): \c"
	read OVERWRITE_FILE
	if [ "${OVERWRITE_FILE}" != "y" ]; then
			echo "exiting"
			exit 0
	fi
fi

ZONE_PATH=`echo ${ZONE_CONFIG} |cut -f4 -d:`
ZONE_STATUS=`echo ${ZONE_CONFIG} |cut -f3 -d:`
case ${ZONE_STATUS} in
	"installed")
		echo "${ZONE} is in a(n) ${ZONE_STATUS} state, continuing..."
	;;

	"running")
		echo "WARNING: ${ZONE} is still running, do you want me to shut it down? (y/n): \c"
		read SHUT_IT_DOWN
		if [ "${SHUT_IT_DOWN}" = "y" ]; then
				echo "Halting ${ZONE}..."
				zoneadm -z ${ZONE} halt
		else
				echo "exiting"
				exit 0
		fi
	;;

	*)
		echo "${ZONE} is in a(n) ${ZONE_STATUS} state which is invalid for this script, please fix"
		exit 1
	;;
esac


#
# Check that the Zone does not have any extra Filesystems.
# e.g. Oracle zones sometimes have /u01 /u02 /u03 these
# would not be copied across with the zone which would 
# cause the zonecfg verify to fail.
#
echo "Checking for additional Zone filesystems...\c"
ZONE_FS_CHECK=`cat /etc/zones/${ZONE}.xml |grep "filesystem"`
if [ "${ZONE_FS_CHECK}" != "" ]; then
	echo "problem"
	echo ""
	echo "${ZONE} has additional Filesystems mounted, I'm not clever enough"
	echo "to copy them yet, suggest you do so by hand."
	exit 1
else
	echo "done."
fi

#
# Detach the zone.
#
echo "Detaching zone...\c"
zoneadm -z ${ZONE} detach
echo "done."


#
# Send the Zone to the NFS share
#
ZONE_FS=`zfs list ${ZONE_PATH} |tail +2 |awk '{print $1}'`
echo "Sending the ${ZONE_FS} to the NFS mount"

echo " - Snapshotting ${ZONE_FS}...\c"
ZONE_SNAPSHOT_NAME="${ZONE_FS}@${THIS_SCRIPT}_`date +%H%M%S-%d-%h-%Y`"
zfs snapshot ${ZONE_SNAPSHOT_NAME} 
echo "done."

echo " - Sending ${ZONE_SNAPSHOT_NAME}...\c"
zfs send ${ZONE_SNAPSHOT_NAME} > ${ZFS_SEND_PATH}/${ZONE}
echo "done."


#
# Remove the Zone configuration
#
echo "Removing ${ZONE}'s configuration from the Global Zone...\c"
zonecfg -z ${ZONE} delete -F
echo "done."

echo "${ZONE} deported to ${ZFS_SEND_PATH}/${ZONE}, use import_zone to reuse"

echo "

!! PLEASE NOTE !!

This script has left ${ZONE}'s filesystem(s) in place.  These should be deleted 
after the zone has been bought back online on another host to stop it from 
being bought back online on this host, and to remove the chance of stale data.

Once you have the zone in it's new position and it's running, and you've tested
it then on this host use:

 # zfs destroy -r ${ZONE_FS}

"
