#!/usr/bin/ksh
#
# Script to set the ilom details for a host
# based on a static text file mapping of:
#
# hostname:ILOM IP:ILOM Netmask:ILOM Gateway
# robert.will.brown@gmail.com - 16/Apr/2009
#
INPUTFILE="ilom-details"
PATH=/usr/sbin:/usr/bin
HOSTNAME=`hostname`

if [ ! -x /usr/sbin/ipmitool ]; then
	echo "No ipmitool"
	exit 1
fi

if [ "`uname -p`" != "i386" ]; then
	echo "platform `uname -p` not supported"
	exit 1
fi

SYS_CONFIG=`prtdiag |grep "System Configuration: " |sed 's/System Configuration: //g'`
if [ "${SYS_CONFIG}" = "VMware, Inc. VMware Virtual Platform" ]; then
	echo "VMware unsupported"
	exit 1
fi

if [ ! -f ${INPUTFILE} ]; then
	echo "Input file: \"${INPUTFILE}\" not found"
	exit 1
fi

# First find this hosts details in the file, populate the vars
# and then check we have all the details we need.
DETAILS=`grep "^${HOSTNAME}:" ${INPUTFILE}`
ILOM_IP=`echo $DETAILS |cut -f2 -d:`
ILOM_NM=`echo $DETAILS |cut -f3 -d:`
ILOM_GW=`echo $DETAILS |cut -f4 -d:`

if [[ -z "${DETAILS}" || -z ${ILOM_IP} || -z ${ILOM_NM} || -z ${ILOM_GW} ]]; then
	echo "No entry, or incomplete entry in \"${INPUTFILE}\" for $HOSTNAME"
	exit 1
fi

ipmitool lan set 1 ipsrc static
ipmitool lan set 1 ipaddr $ILOM_IP
ipmitool lan set 1 netmask $ILOM_NM
ipmitool lan set 1 defgw ipaddr $ILOM_GW

