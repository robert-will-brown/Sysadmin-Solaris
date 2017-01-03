#!/usr/bin/ksh
#
# Create Flash Archive
#
# rob.brown@ioko.com - 28/Sep/2008
#
HOSTNAME=`hostname`
DATE=`date +%H%M-%d-%h-%Y`
FLAR_IMAGE_NAME="${HOSTNAME}-${DATE}"
AUTHOR="rob.brown@ioko.com"
FLAR_DESCRIPTION="Solaris 10 test image"
OUTPUT_DIR="/tmp"

#
# Notes
# * To Exclude a file or directory use -x file/directory
# * If you wish to exclude multiple file/directories then use multiple -x
#   on the same line.
# * By default it uses the -S which skips size checking.  If you want a "proper"
#   archive this should be removed.  (Takes a bloody age though)
#
FILENAME="`date +%H%M-%d-%h-%Y`.flar"
flarcreate -n ${FLAR_IMAGE_NAME}  -S -c \
	-a "${AUTHOR}" \
	-e "${FLAR_DESCRIPTION}"  \
	-x /share \
	${OUTPUT_DIR}/${FILENAME}
