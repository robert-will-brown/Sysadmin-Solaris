#!/usr/bin/ksh
#
# Purpose: Set Interfaces for ipmp
#
# robert.will.brown@gmail.com - 26/Jun/2007
PRI_INT=$1
SEC_INT=$2

echo "editing /etc/hostname.${PRI_INT}..."
echo "`hostname`-${PRI_INT} netmask + broadcast + group lan_data deprecated -failover up \ " > /etc/hostname.${PRI_INT}
echo "addif `hostname`-app netmask + broadcast + up" >> /etc/hostname.${PRI_INT}

echo "editing /etc/hostname.${SEC_INT}..."
echo "`hostname`-${SEC_INT} netmask + broadcast + group lan_data deprecated -failover up" > /etc/hostname.${SEC_INT}
