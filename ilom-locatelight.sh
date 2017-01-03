#!/usr/bin/bash
#
# Set the locate light to on or off
#
# OFF          Off
# ON           Steady On
# STANDBY      100ms on 2900ms off blink rate
# SLOW         1HZ blink rate
# FAST         4HZ blink rate
#
PATH=/usr/sbin:/usr/bin
LED="sys.locate.led"

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
  "on"|"ON") 
    BLINK_TYPE="FAST" ;;
  "off"|"OFF") 
    BLINK_TYPE="OFF" ;;
  "status"|"STATUS") 
    ipmitool sunoem sbled get $LED; exit;;
  *) 
    echo "`basename $0` <on|off|status>"; exit ;;
esac

ipmitool sunoem sbled set $LED $BLINK_TYPE
