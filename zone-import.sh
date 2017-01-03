#!/usr/bin/ksh
#
# import-zone - Import a zone that has been deported with deport-zone 
#               script.
#
# This script should still be considered "beta", not like googlemail,
# but more like Windows ME.
#
# rob.brown@ioko.com - Wed Oct 1st 2008 - Original
#
ZFS_RECEIVE_PATH=/share/dump
THIS_SCRIPT=`basename $0`

#
# If we are in a non-global zone then exit.
#
if [ "$(zonename)" != "global" ]; then
   echo "$(basename ${0}) must be run from the global zone."
   exit 1
fi



#
# Check the arguments passed, we only need the zonename but we can take more
#
if [ ${#} -lt 1 ]; then
	echo "Usage: ${THIS_SCRIPT} <Zone Name> [Physical NIC] [ZFS Pool]"
	echo "Zone Name is required, all others can be answered interactivly"
	echo "  Zone Name    - The name of the deported Zone to be imported"
	echo "  Physical NIC - The physical interface to which the Zone should bind"
	echo "  ZFS Pool     - The ZFS Pool in which to place the Zone"
	exit 1
else
	ZONE=$1
	ZONE_IF=$2
	POOL=$3
fi


#
# Check to see if the user has passed a NIC, if not then prompt
#
if [ "${ZONE_IF}" = "" ]; then
	echo "\n- Select NIC - \n"
	dladm show-dev
	echo "\nWhich NIC?: \c"
	read ZONE_IF
fi


#
# Check to see if the user has passed a ZFS pool, if not then prompt
#
if [ "${POOL}" = "" ]; then
	echo "\n- Select ZFS pool - \n"
	zpool list
	echo ""
	echo "\nWhich ZFS pool?: \c"
	read POOL
fi


#
# Does the pool that the user selected exist?  If it does then
# set the Zone filesystem path
#
zpool list ${POOL} 2>/dev/null 1>/dev/null
if [ "${?}" != "0" ]; then
	echo "ZFS pool ${POOL} does not exist"
	exit 1
else 
	ZONE_FS=${POOL}/${ZONE}
fi


#
# Check for lockfile
#
echo "Checking for lockfile...\c"
LOCKFILE=${ZFS_RECEIVE_PATH}/.${ZONE}.lock
if [ -f ${LOCKFILE} ]; then
	echo "problem"
	echo ""
	echo "${LOCKFILE} exists."
	echo "Maybe someone else is importing or exporting this zone now?  You need"
	echo "to be sure before you manually remove the lockfile."
	echo ""
	echo "lockfile says:"
	cat ${LOCKFILE}
	echo ""
	exit 1
else
	echo "${0} on `hostname` @ `date`" > ${LOCKFILE}
	echo "ok"
fi

#
# Does the ZFS filesystem file exists?
#
echo "Checking ${ZFS_RECEIVE_PATH}/${ZONE} exists...\c"
if [ ! -f ${ZFS_RECEIVE_PATH}/${ZONE} ]; then
	echo "problem"
	echo ""
	echo "${ZFS_RECEIVE_PATH}/${ZONE} not found"
	echo ""
	exit 1
else
	echo "ok"
fi


#
# Check the interface they gave us is valid
#
echo "Validating NIC ${ZONE_IF}...\c"
NIC_VALID="no"
for NIC in $(ifconfig -a|grep mtu |grep -v lo0 |awk '{print $1}' |cut -f1 -d: |uniq)
do
	if [ "${NIC}" = "${ZONE_IF}" ]; then
		NIC_VALID="yes"
	fi
done
if [ "${NIC_VALID}" = "no" ]; then
	echo "problem"
	echo "Invalid NIC: ${ZONE_IF}"
	exit 1
else
	echo "ok"
fi


#
# Check the zone does not exist already
#
echo "Checking if ${ZONE} already exists on this host..\c"
ZONE_CONFIG=`zoneadm -z ${ZONE} list -p 2>/dev/null 1>/dev/null`
if [ ${?} = "0" ]; then
	echo "problem" 
	echo ""
	echo "${ZONE} seems to be already configured on this host?"
	echo ""
	exit 1
else
	echo "ok."
fi

#
# Ran into a problem a while back - even though the zone 
# had been removed the xml file for it existed still.  This caused
# an error with this script.  This check is for that scenario
#
if [ -f /etc/zones/${ZONE}.xml ]; then
	echo "problem" 
	echo ""
	echo "/etc/zones/${ZONE}.xml already exists, it shouldn't." 
	echo ""
	exit 1
fi

# Try pinging the host in a crap attempt to see if it's alive elsewhere
echo "Trying to make sure ${ZONE} isn't alive anywhere...\c"
ping ${ZONE} 2 > /dev/null 1 > /dev/mull
if [ ${?} = "0" ]; then
	echo "problem"
	echo ""
	echo "${ZONE} seems to be alive on the network, exiting."
	echo ""
	exit 1
else
	echo "ok"
fi


# !! need to check if the ZFS  filesystem already exists !!


echo "Receiving ${ZONE_FS} from ${ZFS_RECEIVE_PATH}/${ZONE}...\c"
zfs receive ${ZONE_FS} < ${ZFS_RECEIVE_PATH}/${ZONE} 2>/dev/null 1>/dev/null
if [ "${?}" != "0" ]; then
	echo "error, exiting."
	echo ""
	echo "The receive of the filesystem failed.  This is _probably_ because you've got a"
	echo "filesystem called ${ZONE_FS} already and we are trying to write over the top if it."
	echo ""
	exit 1
else
	echo "done."
fi



echo "Configuring ${ZONE}..."
zonecfg -z ${ZONE}<<EOF
create -a /${ZONE_FS}
verify
commit
exit
EOF
echo "done configuring"

#
# Change the NIC to be the arg2
#
OLD_ZONE_IF=`zonecfg -z ${ZONE} info |grep physical: |awk '{print $2}'`
echo "Changing ${OLD_ZONE_IF} to ${ZONE_IF}...\c"
zonecfg -z ${ZONE}<<EOF
select net physical=${OLD_ZONE_IF}
set physical=${ZONE_IF}
end
verify
commit
exit
EOF
echo "ok"

# Attach the Zone
# The -F is really nasty but I guess a nesesity, really like to work round this properly,
echo "Attaching ${ZONE}...\c"
zoneadm -z ${ZONE} attach -F
if [ "${?}" != "0" ]; then
	echo "error, exiting."
	exit 1
else
	echo "done."
fi

# Boot the zone
echo "Booting ${ZONE}...\c"
zoneadm -z ${ZONE} boot
echo "zone is booting"

echo "$ZONE imported and belived to be running on `hostname`" > ${LOCKFILE}
