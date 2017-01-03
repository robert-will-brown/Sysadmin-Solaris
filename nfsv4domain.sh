#!/usr/bin/ksh
#
# Print the currently running NFS v4 domain.
#
CURRENT_DOMAIN_FILE=/var/run/nfs4_domain
CONFIG_DOMAIN_FILE=/etc/default/nfs

if [ -f $CURRENT_DOMAIN_FILE ]; then
	CURRENT_NFS_DOMAIN=`cat $CURRENT_DOMAIN_FILE`
else
	echo "no ${CURRENT_DOMAIN_FILE}"
fi

if [ -f $CONFIG_DOMAIN_FILE ]; then
	CONFIG_NFS_DOMAIN=`cat $CONFIG_DOMAIN_FILE |grep "^NFSMAPID_DOMAIN" |sed 's/NFSMAPID_DOMAIN=//g'`
	if [ "${CONFIG_NFS_DOMAIN}" = "" ]; then
		CONFIG_NFS_DOMAIN="Not set"
	fi
fi

echo "Current NFS domain: $CURRENT_NFS_DOMAIN"
echo "   NFSMAPID_DOMAIN: $CONFIG_NFS_DOMAIN"
