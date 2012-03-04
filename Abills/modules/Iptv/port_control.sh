#!/bin/sh
# ssh port enable command

ACTION=$1
NAS_IP=$2
PORT_ID=$3
NAS_LOGIN=$3
NAS_PASSWORD=$3

PATH_LOG="/usr/abills/var/log/iptv"
PATH_CONF="/usr/abills/var/log/iptv/lock"
PROGRAMS_PATH=/usr/abills/Abills/modules/Iptv/
TODAY=`date  +%Y_%m_%d`
TIME=`date "+%H:%M:%S"`
TIMESTAMP="$TODAY"_"$TIME"
FILE="enable_${NAS_IP}_e${PORT_ID}_$TIME.log"
RETRY=1
VERSION=0.01


if [ "${ACTION}" = "" ] ; then
  echo "Arguments not specified ";
  echo "$0 [up/down] [nas_ip] [port_id] [nas_login] [nas_password]";
  exit;
fi;


if [ ! -d $PATH_LOG/$TODAY ]; then
  if [ ! -d $PATH_LOG ]; then
	  mkdir $PATH_LOG
  fi
	mkdir $PATH_LOG/$TODAY
fi


# make lockfile filled with timestamp
if [ ! -d $PATH_CONF/lock ]; then
	if [ ! -d $PATH_CONF ]; then
	  mkdir $PATH_CONF
	fi;
	
	mkdir $PATH_CONF/lock
fi

if [ x${ACTION} = xup ]; then
  FILE="enable_${NAS_IP}_e${PORT_ID}_$TIME.log"
else
  FILE="disable_${NAS_IP}_e${PORT_ID}_$TIME.log"
fi;


echo $TIMESTAMP > $PATH_CONF/lock/lock_${NAS_IP}_e${PORT_ID}

while [ $RETRY -gt 0 ]; do
	#init ssh session and writing output to file
	echo "---------------------------------------------" > $PATH_LOG/$TODAY/$FILE
	echo "`date "+%Y-%m-%d %H:%M:%S"` Parameters: ${NAS_IP} ${PORT_ID}" >> $PATH_LOG/$TODAY/$FILE
	echo "---------------------------------------------" >> $PATH_LOG/$TODAY/$FILE
	
	if [ x${ACTION} = xup ]; then
	  ${PROGRAMS_PATH}/enable "${NAS_IP}" "${PORT_ID}" "${NAS_LOGIN}" "${NAS_PASSWORD}">> $PATH_LOG/$TODAY/$FILE
	else
	  ${PROGRAMS_PATH}/disable "${NAS_IP}" "${PORT_ID}" "${NAS_LOGIN}" "${NAS_PASSWORD}" >> $PATH_LOG/$TODAY/$FILE
	fi;

	#parsing logfile
	/usr/bin/grep -qi connection $PATH_LOG/$TODAY/$FILE

	if [ $? -eq  0 ];	then
		# connection failed.
		# if not the last chance, replace the log file
		if [ $RETRY -ne 1 ]; then
			echo "Failed to connect. Retrying..." > $PATH_LOG/$TODAY/$FILE
		fi
		# wait for a while
		sleep 30
		# exit if lock file is modified by another instance (most recently started)
		if [ `cat $PATH_CONF/lock/lock_$1_e$2` != $TIMESTAMP ];	then 
			echo "Another instance already running. Exiting." > $PATH_LOG/$TODAY/$FILE
			exit 0
		fi
	else
		# connection succeeded
		exit 0
	fi
	RETRY=$(( $RETRY - 1 ))
done


echo "Failed to connect to ${NAS_IP}. Port e${PORT_ID}. See log file $PATH_LOG/$TODAY/$FILE for detail." >> $PATH_LOG/failed.log

