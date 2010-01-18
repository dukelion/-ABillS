#!/bin/sh
# ABillS IPN filter example
# ARGUMENTS:
# %STATUS (ONLINE_ENABLE,ONLINE_DISABLE,HANGUP) %LOGIN %IP %FILTER_ID [-debug]
# $conf{IPN_FILTER}='/home/asmodeus/abills2/misc/ipn_filter.sh %STATUS "%LOGIN" "%IP" "%FILTER_ID" "%UID" debug';

VERSION=0.1
debug=1;

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

if [ w${DEBUG} != w ]; then
  DATE=`/bin/date "+%Y-%m-%d %H-%M-%S"`;
  echo "${DATE} STATUS: ${STATUS} LOGIN: ${LOGIN} IP: ${IP} FILTER_ID: $FILTER_ID UID: ${UID}"
fi;

#Some actions
if [ ${STATUS} = ONLINE_ENABLE ]; then


else if [ ${STATUS} = HANGUP ]; then

else if [ ${STATUS} = ONLINE_DISABLE ]; then


fi;
fi;
fi;




