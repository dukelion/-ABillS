#!/bin/sh
# Shape upper 
#

#traffic Class numbers

CLASSES_NUMS='2'
VERSION=0.3




IPFW=/sbin/ipfw
EXTERNAL_INTERFACE=`netstat -rn | grep default | awk '{ print $6 }'`
INTERNAL_INTERFACE=ng*

#Main users table num
USERS_TABLE_NUM=10
FW_START_NUM=4000

#First class number
NETS_TABLE_START_NUM=2

#First Class traffic users
USER_CLASS_TRAFFIC_NUM=10


if [ w$1 = wstart ]; then
#Load kernel modules
kldload ng_ether
kldload ng_car
kldload ng_ipfw



for num in ${CLASSES_NUMS}; do
#  FW_NUM=`expr  `;
  echo "Traffic: ${num} "
  ${IPFW}  add ` expr 9000 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) out via ${EXTERNAL_INTERFACE}
  ${IPFW}  add ` expr 9000 + ${num} \* 10 + 5 ` netgraph tablearg ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) out via ${INTERNAL_INTERFACE}
done;

  ${IPFW}  add 10000 netgraph tablearg ip from table\(10\) to any out via ${EXTERNAL_INTERFACE}
  ${IPFW}  add 10010 netgraph tablearg ip from any to table\(11\) out via ${INTERNAL_INTERFACE}
#done
else if [ w$1 = wstop ]; then
  ${IPFW} delete 09000 09010 10000 10010
else
  echo "(start|stop)"
fi;
fi;
