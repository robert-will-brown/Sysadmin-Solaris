#!/usr/bin/ksh
##########################################################################
# Shellscript:  netinfo 
# Author     :  Rob Brown <robert.will.brown@gmail.com>
# Category   :  Sys Admin
# CreateDate :  20-03-2006 
# Version    :  See ${VER}
##########################################################################
# Description: Cycle through all configured and unconfigured network 
#              interfaces and show the most commonly required information.
# Platform: Solaris
#
##########################################################################
# Change history (most recent first)
#
# When          Who             Comments
# ----          ---             --------
# 26-10-2008    Rob Brown       dladm now does some of what the script was
#                               written to do.  Sentence was added to the
#                               end of the script to let the user know.
# 06-07-2006    Rob Brown       Tidied up and tested on more interfaces.
# 05-07-2006    Martin Robbins  Added interfaces eri, elxl 
# 15-06-2006    Laurie Baker    Fixed 100M/bits error.
# 24-03-2006    Rob Brown       Fixed Bugs when run as a non root user
# 23-03-2006    Rob Brown       Added a function to convert the hexidecimal
#                               ifconfig output of the netmask to decimal
#                               for ease of reading.
# 23-03-2006    Rob Brown       Use picld instead of path_to_inst for 
#                               increased speed.
# 20-03-2006    Rob Brown       Creation.
##########################################################################

#
# Variables
#
IFCONFIG=/usr/sbin/ifconfig
AWK=/usr/bin/awk
KSTAT=/usr/bin/kstat
GREP=/usr/bin/grep

VER="2.0.10"
THISSCRIPT=`basename $0`
HOSTNAME=`hostname`
PICLD_PROBLEM_1="false"	
SHOW_HOSTNAME_NOT_IP="false"

CONTRIBS="Rob Brown, Martin Robbins, Laurie Baker"

CSV="false"
PRINTALL="false"

case $1 in
	"-ocsv")
		CSV="true"
	;;

	"-printnames")
		SHOW_HOSTNAME_NOT_IP="true"
	;;
	"-ver")
		echo "${THISSCRIPT} ${VER}"
		exit	
	;;		

	"-v"|"-printall")
		PRINTALL="true"
	;;

	"")
		continue
	;;

	-h|-help|*)
		echo "${THISSCRIPT} Version: ${VER}"
		echo "Contributers: ${CONTRIBS}"
		echo "${THISSCRIPT} <-h> <-ocsv> <-ver> <-v|-printall> <-printnames>"
		echo "-ocsv\t\tOutput in CSV format"
		echo "-printall | -v\tPrint all data, Verbose"
		echo "-printnames\tPrint hostnames associated with the interface not the IP address"
		echo "-ver\t\tPrint version and exit"
		echo "-h\t\tPrint this help dialog and exit"
		exit 1	
	;;
esac


#
# Functions
#
sanity_chk()
{
	# Are we in a zone?
	if [ -x /usr/bin/zonename -a "`/usr/bin/zonename`" != "global" ]; then
		echo "Run from global zone"
		exit 1
	fi
	
	# Check the platform.  Would be nice to include all the i386 devices but
	# picld does not support the network class for the pcn I tested.
	if [ -x "`uname -p`" != "sparc" ]; then
		echo "`uname -p` is an unsupported platform"
		exit 1
	fi

	# Is picld running?  If it's less than SunOS 5.9, then probably not.
	if [ ! -x /usr/sbin/prtpicl ]; then
		echo "picld not found, to older version of Solaris?"
		echo "Only supported on Solaris 9 and greater"
		exit 1
	fi

	# Is user root?
	ID=`id`
	USER=`expr "${ID}" : 'uid=\([^(]*\).*'`
	if [ "${USER}" != "0" ]; then
		echo "* You're not root, some Speed and Duplex information will not be available *"
		ROOT_USER="false"
	else
		ROOT_USER="true"
	fi

	if [ "${PRINTALL}" = "false" -a "${CSV}" = "false" ]; then
		SCREEN="small"
	else
		# User wants to see everything regardless of formatting.
		SCREEN="big"
	fi
}


print_detail()
{
	INTF_NAME=$1
	INTF_TYPE=$2
	INTF_STATUS=$3
	INTF_MAC=$4
	INTF_IP=$5
	INTF_NETMASK=$6
	INTF_BC=$7
	INTF_SPEED=$8
	INTF_DUPLEX=$9
	INTF_LINKSTATE=${10}
	INTF_UP=${11}
	INTF_DEVPATH=${12}
	
	# Check to see we are passed an actual netmask not a column header, and if
	# we are then send it off to the function that converts from hex to dec
	INTF_NETMASK_FIRSTCHAR=`echo ${INTF_NETMASK} |cut -c1`
	if [ ${INTF_NETMASK_FIRSTCHAR} = "f" ]; then
		hex2dec ${INTF_NETMASK}
		INTF_NETMASK=${OUT_NETMASK}
	fi

	if [ "${CSV}" = "true" ]; then
		echo "${HOSTNAME},${INTF_NAME},${INTF_TYPE},${INTF_STATUS},${INTF_MAC},${INTF_HOSTNAME},${INTF_IP},${INTF_NETMASK},${INTF_BC},${INTF_SPEED},${INTF_DUPLEX},${INTF_LINKSTATE},${INTF_UP},\"${INTF_DEVPATH}\",${THISSCRIPT} Version: ${VER}"
	else
		if [ "${INTF_TYPE}" = "Virt" ]; then
			INTF_NAME="-->${INTF_NAME}"
		fi

		if [ "${SCREEN}" = "small" ]; then
			echo "${INTF_NAME} ${INTF_TYPE} ${INTF_STATUS} ${INTF_IP} \
				${INTF_SPEED} ${INTF_DUPLEX} ${INTF_LINKSTATE} ${INTF_UP}" | \
				${AWK} '{printf("%-10s %-5s %-10s %-15s %-10s %-8s %-6s %-6s\n",$1,$2,$3,$4,$5,$6,$7,$8)}'
		else
			echo "${INTF_NAME} ${INTF_TYPE} ${INTF_STATUS} ${INTF_MAC} ${INTF_IP} \
				${INTF_NETMASK} ${INTF_BC} ${INTF_SPEED} ${INTF_DUPLEX} ${INTF_LINKSTATE} ${INTF_UP} ${INTF_DEVPATH}" | \
				${AWK} '{printf("%-10s %-5s %-10s %-18s %-15s %-15s %-15s %-10s %-7s %-s %-4s %-0s\n",$1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)}'
		fi
	fi
	INTF_NAME=$1
}


# Used for converting the Netmask from Hex to Decimal
# Needs a rewrite to clean it up in a loop
hex2dec()
{
	IN_NETMASK="`echo $1 |tr "[a-z]" "[A-Z]"`"

	# Convert ffffff00 to uppercase or bc doesn't like it
	NM_NUM=`echo ${IN_NETMASK} |cut -c1,2`
	OUT_NETMASK1=`echo "obase=10;ibase=16; ${NM_NUM}" | bc`

	NM_NUM=`echo ${IN_NETMASK} |cut -c3,4`
	OUT_NETMASK2=`echo "obase=10;ibase=16; ${NM_NUM}" | bc`

	NM_NUM=`echo ${IN_NETMASK} |cut -c5,6`
	OUT_NETMASK3=`echo "obase=10;ibase=16; ${NM_NUM}" | bc`

	NM_NUM=`echo ${IN_NETMASK} |cut -c7,8`
	OUT_NETMASK4=`echo "obase=10;ibase=16; ${NM_NUM}" | bc`

	OUT_NETMASK="${OUT_NETMASK1}.${OUT_NETMASK2}.${OUT_NETMASK3}.${OUT_NETMASK4}"
}


# Get information for the named interface
get_intf_detail()
{
	INTF_NAME=${1}
	# Test if interface is plumbed
	${IFCONFIG} ${INTF_NAME} 2>/dev/null 1>/dev/null
	IFCONFIG_RTRN_CODE=${?}
	if [ "${IFCONFIG_RTRN_CODE}" = "0" ]; then
		INTF_STATUS="plumbed"

		# See if the interface has a link and is set to UP
		INTF_LINKSTATE=`${IFCONFIG} ${INTF_NAME} |${GREP} flags= |${GREP} RUNNING`
		if [ "${INTF_LINKSTATE}" = "" ]; then
			# Cable not connected?
			INTF_LINKSTATE="bad"
		else
			INTF_LINKSTATE="good"
		fi

		INTF_UP=`${IFCONFIG} ${INTF_NAME} |${GREP} flags= |${GREP} "UP"`
		if [ "${INTF_UP}" = "" ]; then
			# Interface not set to up
			INTF_UP="down"
		else
			INTF_UP="up"
		fi
		
		INTF_IP=`${IFCONFIG} ${INTF_NAME} |${GREP} inet |${AWK} '{print $2}'`
		INTF_HOSTNAME=`getent hosts ${INTF_IP} |awk '{print $2}' |cut -f1 -d.`
		INTF_HOSTNAME_RTRN=${?}
		if [ "${SHOW_HOSTNAME_NOT_IP}" = "true" ]; then
			INTF_IP="${INTF_HOSTNAME}"
		fi
		INTF_NETMASK=`${IFCONFIG} ${INTF_NAME} |${GREP} inet |${AWK} '{print $4}'`

		# Getting the broadcast address can be tricky.  This tries to check
		# wether the interface is broadcasting and if it is tries to capture it.
		# if not it sets it to null
		INTF_BC=`${IFCONFIG} ${INTF_NAME} |${GREP} flags= |${GREP} BROADCAST`
		if [ "${INTF_BC}" = "" ]; then
			INTF_BC="-"	
		else
			INTF_BC=`${IFCONFIG} ${INTF_NAME} |${GREP} inet |${GREP} broadcast |${AWK} '{print $6}'`
			if [ "${INTF_BC}" = "" ]; then
				INTF_BC="-"
			fi
		fi

		if [ "${ROOT_USER}" = "true" ]; then
			if [ "${INTF_TYPE}" = "Phys" ]; then
				case ${INTF_MODEL} in
					ce|ipge)
						DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} link_duplex |${AWK} '{ print $2 }'`
						case "${DUPLEX}" in
							0) INTF_DUPLEX="bad" ;;
							1) INTF_DUPLEX="half" ;;
							2) INTF_DUPLEX="full" ;;
						esac
	
  						SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} link_speed |${AWK} '{ print $2 }'`
						case "${SPEED}" in
							10) INTF_SPEED="10Mbit/s" ;;
							100) INTF_SPEED="100Mbit/s" ;;
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
					;;
	
					elxl)
						DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} duplex |${AWK} '{ print $2 }'`
						case "${DUPLEX}" in
							0) INTF_DUPLEX="bad" ;;
							1) INTF_DUPLEX="half" ;;
							2) INTF_DUPLEX="full" ;;
						esac
	
						SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} ifspeed |${AWK} '{ print $2 }'`
						case "${SPEED}" in
							0) INTF_SPEED="10Mbit/s" ;;
							1) INTF_SPEED="100Mbit/s" ;;
						esac
					;;

					bge)
						DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE}:parameters |${GREP} link_duplex |${AWK} '{ print $2 }'`
						case "${DUPLEX}" in
							0) INTF_DUPLEX="bad" ;;
							1) INTF_DUPLEX="half" ;;
							2) INTF_DUPLEX="full" ;;
						esac
	
      				SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE}:parameters |${GREP} link_speed |${AWK} '{ print $2 }'`
						case "${SPEED}" in
							10) INTF_SPEED="10Mbit/s" ;;
							100) INTF_SPEED="100Mbit/s" ;;
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
					;;
	
					hme)
						# If interface is an hme then we won't have got all the
						# information from picld.  Look elsewhere for it.
						INTF_MAC=`${IFCONFIG} -a |${GREP} ether |${AWK} '{print $2}'`

						DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} link_duplex |${AWK} '{ print $2 }'`
						case "${DUPLEX}" in
							0) INTF_DUPLEX="bad" ;;
							1) INTF_DUPLEX="half" ;;
							2) INTF_DUPLEX="full" ;;
						esac

      				SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} ifspeed |${AWK} '{ print $2 }'`
						case "${SPEED}" in
							# 100000000 has been tested but 10 hasn't, please check then remove this comment
							10) INTF_SPEED="10Mbit/s" ;;
							100000000) INTF_SPEED="100Mbit/s" ;;
						esac
					;;

					dmfe)
						# How do I do this with a dmfe?
						#DUPLEX=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} link_duplex |${AWK} '{ print $2 }'`
						DUPLEX="unknown"
  						SPEED=`${KSTAT} ${INTF_MODEL}:${INTF_INSTANCE} |${GREP} ifspeed |${AWK} '{ print $2 }'`
						INTF_DUPLEX="${DUPLEX}"
						case "${SPEED}" in
							10) INTF_SPEED="10Mbit/s" ;;
							100) INTF_SPEED="100Mbit/s" ;;
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
					;;
	
					*)
						/usr/sbin/ndd -set /dev/${INTF_MODEL} instance ${INTF_INSTANCE}
						SPEED=`/usr/sbin/ndd -get /dev/${INTF_MODEL} link_speed`
      				DUPLEX=`/usr/sbin/ndd -get /dev/${INTF_MODEL} link_mode`
						case "$SPEED" in
							0) INTF_SPEED="10Mbit/s" ;;
							1) INTF_SPEED="100Mbit/s" ;;
							1000) INTF_SPEED="1Gbit/s" ;;
						esac
						case "$DUPLEX" in
							0) INTF_DUPLEX="half" ;;
							1) INTF_DUPLEX="full" ;;
							*) INTF_DUPLEX="${DUPLEX}" ;;
						esac
					;;
				esac
	
			else
				# It's a virtual Interface
				VIRT_TXT="--^"
				INTF_SPEED="${VIRT_TXT}"
				INTF_DUPLEX="${VIRT_TXT}"
				INTF_MAC="${VIRT_TXT}"
				INTF_DEVPATH="${VIRT_TXT}"
			fi
			else
				# user isn't root
				NOT_ROOT_TXT="-*"
				INTF_SPEED="${NOT_ROOT_TXT}"
				INTF_DUPLEX="${NOT_ROOT_TXT}"
			fi

		else
			# It's an unplumbed interface
			INTF_STATUS="unplumbed"
			INTF_IP="-"
			INTF_NETMASK="-"
			INTF_BC="-"
			INTF_SPEED="-"
			INTF_DUPLEX="-"
			INTF_LINKSTATE="-"
			INTF_UP="-"
			# hme's don't report their mac via picld.  So set it to nothing
			if [ "${INTF_MODEL}" = "hme" ]; then
				INTF_MAC="-"
			fi
		fi
}



sanity_chk

if [ "${CSV}" = "false" ]; then
	print_detail Interface Type Status MAC_Addr IP_Addr Netmask Broadcast Speed Duplex Link Up? Dev_Path
	print_detail ========= ==== ====== ======== ======= ======= ========= ===== ====== ==== === ========
fi


# Use picld to enumerate the information for each virtual interface, then check
# if the physical has any virtual interfaces, if so then enurmerate those as well.
COUNT=0
/usr/sbin/prtpicl -vc network |egrep "instance|driver-name|local-mac-address|devfs-path" |while read LINE
do
	COUNT=`expr ${COUNT} + 1`
	ITEM=`echo ${LINE} |awk '{print $1}'`
	case ${ITEM} in
		":local-mac-address")
			INTF_MAC=`echo ${LINE} |awk '{print $2":"$3":"$4":"$5":"$6":"$7}'`
		;;

		":devfs-path")
			INTF_DEVPATH=`echo ${LINE} |awk '{print $2}'`
		;;

		":driver-name")
			INTF_MODEL=`echo ${LINE} |awk '{print $2}'`
		;;

		":instance")
			INTF_INSTANCE=`echo ${LINE} |awk '{print $2}'`
		;;
	esac

	# Needs to capture if its a hme as you wont get all the information from picld
	# Explanation of logic:  If count=4 i.e if we have all four lines model, mac, instance and devfs_path
	# then continue the script.  Otherwise if its an hme (picld will never give us all four lines)
	# then count to 3 (ensure that we have the two lines that picld does give us and then continue.
	if [ "${COUNT}" = "4" ] || [ "${INTF_MODEL}" = "hme" -a "${COUNT}" = "3" ] ; then
		INTF_NAME="${INTF_MODEL}${INTF_INSTANCE}"
		INTF_TYPE="Phys"

		# On certain combinations of systems and cards, when an entire group is unplumbed 
		# picld does not provide the instance number, or the device path correctly.
		if [ "${INTF_INSTANCE}" = "-1" ]; then
			get_intf_detail
			INTF_NAME="${INTF_MODEL}?"
			PICLD_PROBLEM_1="?=Instance number is not reported correctly by picld, sorry."
		fi

		get_intf_detail ${INTF_NAME}
		print_detail ${INTF_NAME} ${INTF_TYPE} ${INTF_STATUS} ${INTF_MAC} ${INTF_IP} ${INTF_NETMASK} ${INTF_BC} ${INTF_SPEED} ${INTF_DUPLEX} ${INTF_LINKSTATE} ${INTF_UP} ${INTF_DEVPATH}

		# Check to see if INTF_NAME has any Virtual Interfaces
		for VIRT_NIC in `${IFCONFIG} -a |${GREP} "${INTF_NAME}" |${AWK} '{print $1}'`
		do
			VIRT_INTF_NAME=`echo ${VIRT_NIC} |${AWK} '{printf "%s", substr ($1,1,length($1)-1)}'`
			if [ "${VIRT_INTF_NAME}" != "${INTF_NAME}" ]; then
				INTF_TYPE="Virt"
				get_intf_detail ${VIRT_INTF_NAME}
				print_detail ${VIRT_INTF_NAME} ${INTF_TYPE} ${INTF_STATUS} ${INTF_MAC} ${INTF_IP} ${INTF_NETMASK} ${INTF_BC} ${INTF_SPEED} ${INTF_DUPLEX} ${INTF_LINKSTATE} ${INTF_UP} ${INTF_DEVPATH}
			fi
		done

		COUNT=0
	fi
done

# Print any errors
if [ "${CSV}" = "false" ]; then
	if [ "${PICLD_PROBLEM_1}" != "false" ]; then
		echo "${PICLD_PROBLEM_1}"
	fi
fi

echo ""
echo "Consider using \"dladm show-dev\" in Solaris 10+"

