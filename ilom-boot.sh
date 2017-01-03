#!/usr/bin/bash
#
# Select which device to boot from on the next boot
#
# rob.brown@ioko.com (from an idea by alex)
# robert.will.brown@gmail.com - 16/Apr/2009
#
PATH=/usr/sbin:/usr/bin
BOOTDEV=$1

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


case $1 in
  "cdrom"|"cd"|"dvd"|"dvdrom") 
    BOOTDEV="cdrom" ;;
  "net"|"pxe") 
    BOOTDEV="pxe" ;;
  "bios") 
    BOOTDEV="bios" ;;
  "disk") 
    BOOTDEV="disk" ;;
  *)
    echo "Usage `basename $0` <net|cdrom|disk|bios>"
    exit 1;;
esac

ipmitool chassis bootdev $BOOTDEV
