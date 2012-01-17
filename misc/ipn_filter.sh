#!/bin/sh
# ABillS IPN filter example
# ARGUMENTS:
# %STATUS (ONLINE_ENABLE,ONLINE_DISABLE,HANGUP) %LOGIN %IP %FILTER_ID [-debug]
# $conf{IPN_FILTER}='/home/asmodeus/abills2/misc/ipn_filter.sh %STATUS "%LOGIN" "%IP" "%FILTER_ID" "%UID" debug';

VERSION=0.3;
debug=0;

if [ w$4 = w ]; then
  if [ w${debug} = w0 ]; then
    exit;
  fi;
 
  echo "ABillS IPN filter $version. Debug mode: ${debug}";
  echo "Not enought arguments"
  echo "ipn_filter.sh %STATUS (ONLINE_ENABLE,ONLINE_DISABLE,HANGUP) \"%LOGIN\" \"%IP\" \"%FILTER_ID\" \"%UID\" debug"
  exit;
fi;

STATUS=$1;
LOGIN=$2;
IP=$3;
FILTER_ID=$4;
UID=$5;
DEBUG=$6;
IPFW=/sbin/ipfw

if [ w${DEBUG} != w ]; then
  DATE=`/bin/date "+%Y-%m-%d %H-%M-%S"`;
  echo "${DATE} STATUS: ${STATUS} LOGIN: ${LOGIN} IP: ${IP} FILTER_ID: $FILTER_ID UID: ${UID}"
fi;

#Forward ip filter
# filter format: 
#  fwd:local_ip:external_ip
forward_ip () {

 FILTER_NAME=`echo ${FILTER_ID} | awk -F: '{print $1}'`;
 if [ w${FILTER_NAME} = wfwd ]; then
      echo "Forward filter";
      LOCAL=`echo ${FILTER_ID} | awk -F: '{print $2}'`;
      REMOTE=`echo ${FILTER_ID} | sed 's/fwd:\([0-9.]*\):\([0-9.]*\).*/\2/'`;
      if [ w$debug != w0 ]; then
        echo "FWD: ${LOCAL} -> ${REMOTE}"
      fi;
   if [ ${STATUS} = ONLINE_ENABLE ]; then
      ${IPFW} nat ${UID} config redirect_addr ${LOCAL} ${REMOTE}
      ${IPFW}  table 34 add ${LOCAL} ${UID}
      ${IPFW}  table 33 add ${REMOTE} ${UID}
   else
      ${IPFW}  table 34 delete ${LOCAL}
      ${IPFW}  table 33 delete ${REMOTE}
   fi;
 fi;
}

forward_ip;


#Some actions
if [ ${STATUS} = ONLINE_ENABLE ]; then


else if [ ${STATUS} = HANGUP ]; then

else if [ ${STATUS} = ONLINE_DISABLE ]; then


fi;
fi;
fi;




