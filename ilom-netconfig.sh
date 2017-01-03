#!/usr/bin/ksh
#
# Print the network configuration of the ILOM
#
# robert.will.brown@gmail.com - 16/Apr/209
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
  "list") 
    ipmitool lan print |egrep "IP Address|MAC Address|Subnet Mask|Default Gateway IP|MAC Address"
  ;;

  "set")
    echo "IP Address: \c"; read IPADDR
    echo "Netmask   : \c"; read NETMASK
    echo "Gateway   : \c"; read GATEWAY

    ipmitool lan set 1 ipsrc static
    ipmitool lan set 1 ipaddr $IPADDR
    ipmitool lan set 1 netmask $NETMASK
    ipmitool lan set 1 defgw ipaddr $GATEWAY
  ;;

  *)
    echo "Usage: `basename $0` <list|set>"
    exit 1
  ;;
esac
