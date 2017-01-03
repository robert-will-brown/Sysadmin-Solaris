#!/usr/bin/ksh
#
# Purpose: Script to mirror root disk using Solstice Disksuite.
# Rob Brown 14/05/2001
#
# Updated on 28 August 2008 to exclude slice 6 as its used for the 
# local_zone pool.
#
ROOTDISK=$1
ROOTMIRROR=$2
METADBSLICE=$3
PATH=$PATH:/usr/opt/SUNWmd/sbin:/usr/dt/bin:/usr/openwin/bin:/bin:/usr/bin:/usr/ucb:/usr/sbin:/usr/openwin/bin
CRON_CHK_STRING_1='#'
CRON_CHK_STRING_2='# Once daily test SDS (Disksuite) for errors'
CRON_CHK_STRING_3='10 9 * * * /opt/IOKOtools/chk-sds'

#
# Sanity Chk.  Ensure Binaries exist and
# determine Paths to them. Also ensure no
# disksuite metadb's have been configured.
# Check users has sufficent permissions and check
# they are frood enough to continue.
#

#
# Configure Paths
#
if [ -f /usr/opt/SUNWmd/sbin/metastat ]; then
	METASTAT=/usr/opt/SUNWmd/sbin/metastat
	METADB=/usr/opt/SUNWmd/sbin/metadb
	METAINIT=/usr/opt/SUNWmd/sbin/metainit
	METATTACH=/usr/opt/SUNWmd/sbin/metattach
	METAROOT=/usr/opt/SUNWmd/sbin/metaroot
	MDTAB=/etc/opt/SUNWmd/md.tab

elif [ -f /usr/sbin/metastat ]; then
	METASTAT=/usr/sbin/metastat
	METADB=/usr/sbin/metadb
	METAINIT=/usr/sbin/metainit
	METATTACH=/usr/sbin/metattach
	METAROOT=/usr/sbin/metaroot
	MDTAB=/etc/lvm/md.tab

else
	echo No Disksuite binaries found - please ensure it is installed.
	exit 1
fi


#
# Do Any metadbs already exist?
#
${METADB} > /dev/null
if [ "$?" -ne "1" ]
then
	echo "Metadb's may exist, or funny return code from metadb - please clear down before rerunning ${0}."
	exit 1
fi


#
# Is user root?
#
ID=`id`
USER=`expr "${ID}" : 'uid=\([^(]*\).*'`

if [ "${USER}" != "0" ]; then
	echo "You must be root to run $0"
	exit 1
fi


#
# Are Disk variables populated?
#
if [ "${ROOTDISK}" = "" ] || [ "${ROOTMIRROR}" = "" ] || [ "${METADBSLICE}" = "" ]; then
	echo "Information missing: "
	echo "Usage: $0 rootdisk rootmirror metadbslice"
	echo "e.g. ${0} c1t0d0 c1t1d0 s7"
	exit 1
fi



#
# Main
#
echo "Backing up old system/vfstab..."
cp /etc/vfstab /etc/vfstab.pre-`basename ${0}`
cp /etc/system /etc/system.pre-`basename ${0}`


#
# Write vtoc and check, bomb out on any errors.
#
echo "Writing ${ROOTDISK}'s vtoc ---> ${ROOTMIRROR}..."
prtvtoc /dev/rdsk/${ROOTDISK}s2 > /tmp/root-vtoc
fmthard -s /tmp/root-vtoc /dev/rdsk/${ROOTMIRROR}s2

FMTHARD_RTN=${?}
if [ "${FMTHARD_RTN}" -ne "0" ]; then
        echo "Error Writing the vtoc from ${ROOTDISK} to ${ROOTMIRROR}, are they"
        echo "the same type/size of disk??  Exiting."
        exit 1
fi

echo "Creating MetaDatabases..."
${METADB} -a -c 3 -f ${ROOTDISK}${METADBSLICE}
${METADB} -a -c 3 -f ${ROOTMIRROR}${METADBSLICE}

echo "Meta DataBase: "
${METADB}

for SLICE in `cat /tmp/root-vtoc |grep -v '*' |awk '{print $1}'`
do
	if [ ${SLICE} -eq "2" ] || \
		[ ${SLICE} -eq `echo ${METADBSLICE} |cut -c2` ] || \
		[ ${SLICE} -eq "6" ] || \
		[ ${SLICE} -eq "8" ] || \
		[ ${SLICE} -eq "9" ]
	then
		echo "Not Touching slice ${SLICE}"
	else
		echo Creating Sub Disks and Mirroring Slice ${SLICE}
		MD_ROOT="d`expr ${SLICE} + 10`"
		MD_MIRR="d`expr ${SLICE} + 20`"
		MD_MIRROBJECT=d${SLICE}
		${METAINIT} -f ${MD_ROOT} 1 1 ${ROOTDISK}s${SLICE}
		${METAINIT} ${MD_MIRR} 1 1 ${ROOTMIRROR}s${SLICE}
		${METAINIT} ${MD_MIRROBJECT} -m ${MD_ROOT}

		echo "${METATTACH} ${MD_MIRROBJECT} ${MD_MIRR}" >> /etc/rc3.d/S98finish_mirror

		cp /etc/vfstab /etc/vfstab.pre-rootmirror
		cp /etc/vfstab /tmp/vfstab

		if [ ${SLICE} -eq "0" ]
		then
			${METAROOT} ${MD_MIRROBJECT}
		else
			# Need to change entry in vfstab
			echo "Altering the vfstab..."
			cat /etc/vfstab |sed -e "s/\/dsk\/${ROOTDISK}s${SLICE}/\/md\/dsk\/${MD_MIRROBJECT}/" > /tmp/vfstab
			cp /tmp/vfstab /etc/vfstab
			cat /etc/vfstab |sed -e "s/\/rdsk\/${ROOTDISK}s${SLICE}/\/md\/rdsk\/${MD_MIRROBJECT}/" > /tmp/vfstab
			cp /tmp/vfstab /etc/vfstab
		fi
	fi
done

# Create md.tab, and make the finish_mirror script runable at next boot.
echo "${METASTAT} -p >> ${MDTAB}" >> /etc/rc3.d/S98finish_mirror
echo "/usr/bin/rm /etc/rc3.d/S98finish_mirror" >> /etc/rc3.d/S98finish_mirror
chmod 755 /etc/rc3.d/S98finish_mirror


# Add the SDS checks script to roots cron
echo "${CRON_CHK_STRING_1}" >> /var/spool/cron/crontabs/root
echo "${CRON_CHK_STRING_2}" >> /var/spool/cron/crontabs/root
echo "${CRON_CHK_STRING_3}" >> /var/spool/cron/crontabs/root

echo "This system must now be rebooted, to attach new mirrors."
