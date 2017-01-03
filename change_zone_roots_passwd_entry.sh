#!/usr/bin/ksh
#
# Change root shell and home dir, normally called from jumpstart.  RB
# robert.will.brown@gmail.com
# 1/Sep/2008
#
if [ $1 = "" ];then
	echo no passwd path
	exit 1
fi
NEW_PWORD_ENTRY='root:x:0:0:Super-User:\/root:\/usr\/bin\/bash'
OLD_PWORD_ENTRY='root:x:0:0:Super-User:\/:\/sbin\/sh'

PFILE=$1
TMPFILE=/tmp/passwd.tmp

CAT=/usr/bin/cat 
SED=/usr/bin/sed
CP=/usr/bin/cp

${CP} ${PFILE} ${TMPFILE}
${CAT} ${TMPFILE} |${SED} -e "s/${OLD_PWORD_ENTRY}/${NEW_PWORD_ENTRY}/g" > ${PFILE}

rm ${TMPFILE}
