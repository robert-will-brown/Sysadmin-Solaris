#!/usr/bin/ksh
#
# Script to check that any configured SDS (disksuite)
# metadevies are not in an errored state.
#
#
SUBJECT="Disksuite problem with `hostname` @ `date`"
MESSAGE="A problem with disksuite was detected by the `echo ${0}` script."
BACKUP_ALERT_ADDR=root@localhost
ALERT_FILE=/etc/managed_service
ERROR="0"


#
# Configure the email address to whom we are sending any
# errors to.
#
if [ -f ${ALERT_FILE} ]; then
	NOTIFY=`grep "^ALERT_EMAIL:" ${ALERT_FILE} |awk '{print $2}'`
	if [ "${NOTIFY}" = "" ]; then
		echo "alert email not found in ${ALERT_FILE}"
		NOTIFY="${BACKUP_ALERT_ADDR}"
	
	fi
else
	echo "file ${ALERT_FILE} not found"
	NOTIFY="${BACKUP_ALERT_ADDR}"
fi


#
# First check that the command can run without errors.
# If a host has no SDS setup at all then it will return
# a non-zero status from this command implying that 
# something is wrong even it it is just unconfigured.
# This is on purpose - we assume that this script is 
# only ever run on a host that should be mirrored.
#
metastat 2>/dev/null 1>/dev/null
if [ "${?}" != "0" ]; then
	ERROR=1
fi


# 
# Now we need to cycle through all the metadevices and check 
# each one in turn.  If its in "Okay" or "resyncing" then its
# Ok, anything else is considered a fault.
#
for STATE in `metastat |grep State: |awk '{print $2}'`
do
	if [ "${STATE}" != "Okay" ] || [ "${STATE}" != "resyncing" ] ; then
		ERROR="1"
	fi
done


#
# Check for Error and send an email if there was a fault
# detected.
#
if [ "${ERROR}" = "1" ]
then

mail ${NOTIFY}<<EOMAIL
X-Priority: 1
Priority: Urgent
Importance: high
Subject: ${SUBJECT}

`echo ${MESSAGE}`

`metastat`
EOMAIL

fi
