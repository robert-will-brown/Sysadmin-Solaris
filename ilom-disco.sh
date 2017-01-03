#!/usr/bin/bash
#
# Set all the blade lights to flash like it's saturday night.
# When will I grow up....?
# rob.brown@ioko.com - 17/Apr/2009
#
# OFF          Off
# ON           Steady On
# STANDBY      100ms on 2900ms off blink rate
# SLOW         1HZ blink rate
# FAST         4HZ blink rate
#
PATH=/usr/sbin:/usr/bin
BLINK_TYPE=FAST

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
  "on")
    for LED in `ipmitool sunoem sbled get |awk '{print $1}'`
    do
      ipmitool sunoem sbled set $LED $BLINK_TYPE
    done
  ;;

  "off")
    for LED in `ipmitool sunoem sbled get |awk '{print $1}'`
    do
      ipmitool sunoem sbled set $LED OFF
    done
  ;;

  *)
    echo "Usage: `basename $0` <on|off>"
esac
