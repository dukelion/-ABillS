#!/bin/sh
# Shape upper 
#

#traffic Class numbers

CLASSES_NUMS='2 3'
VERSION=1.0




IPFW=/sbin/ipfw
EXTERNAL_INTERFACE=`/sbin/route get 91.203.4.17 | grep interface: | awk '{ print $2 }'`
INTERNAL_INTERFACE=ng*

PKG_DIRECTION="TO_SERVER"

if [ w${PKG_DIRECTION} = wTO_SERVER ] ; then
  IN_DIRECTION="in recv ${INTERNAL_INTERFACE}"
  OUT_DIRECTION="out xmit ${INTERNAL_INTERFACE}"
else
  IN_DIRECTION="out xmit ${EXTERNAL_INTERFACE}"
  OUT_DIRECTION="in recv ${EXTERNAL_INTERFACE}"
fi; 


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

  #Unlim traffic
  ${IPFW} add ` expr 9000 + ${num} \* 10 ` allow ip from table\(9\) to table\(${num}\) ${IN_DIRECTION}
  ${IPFW} add ` expr 9000 + ${num} \* 10 + 5 ` allow ip from table\(${num}\) to table\(9\) ${OUT_DIRECTION}


  #Shaped traffic
  ${IPFW} add ` expr 9100 + ${num} \* 10 ` skipto ` expr 10100 + ${num} \* 10 ` ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) ${IN_DIRECTION}
  ${IPFW} add ` expr 9100 + ${num} \* 10 + 5 ` skipto ` expr 10100 + ${num} \* 10 + 5 ` ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}


  ${IPFW} add ` expr 10100 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to any ${IN_DIRECTION}
  ${IPFW} add ` expr 10100 + ${num} \* 10 + 5 ` netgraph tablearg ip from any to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}


#  ${IPFW}  add ` expr 9000 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) out via ${EXTERNAL_INTERFACE}
#  ${IPFW}  add ` expr 9000 + ${num} \* 10 + 5 ` netgraph tablearg ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) out via ${INTERNAL_INTERFACE}
done;

  echo "Global shaper"
  ${IPFW} add 9000 allow ip from table\(9\) to any ${IN_DIRECTION}
  ${IPFW} add 9005 allow ip from any to table\(9\) ${OUT_DIRECTION}

  ${IPFW}  add 10000 netgraph tablearg ip from table\(10\) to any ${IN_DIRECTION}
  ${IPFW}  add 10010 netgraph tablearg ip from any to table\(11\) ${OUT_DIRECTION}
  ${IPFW}  add 10015 allow ip from any to any via ng*
#done
else if [ w$1 = wstop ]; then
  for num in ${CLASSES_NUMS}; do
    ${IPFW} delete ` expr 9100 + ${num} \* 10 + 5 ` ` expr 9100 + ${num} \* 10 `  ` expr 9000 + ${num} \* 10 ` ` expr 10100 + ${num} \* 10 ` ` expr 9000 + ${num} \* 10 + 5 ` ` expr 10100 + ${num} \* 10 + 5 ` 
  done;

  ${IPFW} delete 9000 90005 10000 10010 10015
else
  echo "(start|stop)"
fi;
fi;


#NAT Section
if [ w${abills_nat_enable} != w ] ; then

FAKE_NET=192.168.0.0/16
NAT_TABLE=20
NAT_FIRST_RULE=20
NAT_IPS="91.200.156.56 91.200.156.57 91.200.156.58"
NAT_REAL_TO_FAKE_TABLE_NUM=31;


# nat configuration
for IP in ${NAT_IPS}; do
  ${IPFW} nat ` expr ${NAT_FIRST_RULE} + 1 ` config ip ${IP} log deny_in
  ${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} add ${IP} ` expr ${NAT_FIRST_RULE} + 1 `
done;


# nat real to fake
#${IPFW} add 00600 nat tablearg ip from any to table\(21\) in recv ${EXTERNAL_INTERFACE}
# nat fake to real
#${IPFW} add 17000 nat tablearg ip from table\(20\) to not 193.138.244.2 out


${IPFW} add 10 nat 123 ip from ${FAKE_NET} to any
${IPFW} add 20 nat 123 ip from any to table\(21\)

fi;
