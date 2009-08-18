#!/bin/sh
# Shape upper 
#

#traffic Class numbers

CLASSES_NUMS='1 2 3'
VERSION=0.2




IPFW=/sbin/ipfw
EXTERNAL_INTERFACE=`netstat -rn | grep default | awk '{ print $6 }'`
INTERNAL_INTERFACE=ng*

#Main users table num
USERS_TABLE_NUM=10
FW_START_NUM=4000

#First class number
NETS_TABLE_START_NUM=2

#First Class traffic users
USER_CLASS_TRAFFIC_NUM=12

#Load kernel modules
kldload ng_ether
kldload ng_car
kldload ng_ipfw



#for num in ${CLASSES_NUMS}; do
#  FW_NUM=`expr  `;
  ${IPFW}  add 09000 netgraph tablearg ip from table\(${USER_CLASS_TRAFFIC_NUM}\) to table\(${NETS_TABLE_START_NUM}\) out via ${EXTERNAL_INTERFACE}
  ${IPFW}  add 09010 netgraph tablearg ip from table\(${NETS_TABLE_START_NUM}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + 1 `\) out via ${INTERNAL_INTERFACE}

  ${IPFW}  add 10000 netgraph tablearg ip from table\(10\) to any out via ${EXTERNAL_INTERFACE}
  ${IPFW}  add 10010 netgraph tablearg ip from any to table\(11\) out via ${INTERNAL_INTERFACE}

#done
