#!/bin/sh
# Shape/NAT upper  
#

#traffic Class numbers

CLASSES_NUMS='2 3'
VERSION=2.7

#Enable NG shapper
NG_SHAPPER=1
# NAT IP
NAT_IPS="";
FAKE_NET="10.0.0.0/16"
NAT_IF="";

#Negative deposit forward
NEG_DEPOSIT_FWD="1"

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

echo -n $1

if [ w$1 = wstart -a w$2 = w -a w${NG_SHAPPER} != w ]; then


echo -n "ng_car shapper"
#Load kernel modules
kldload ng_ether
kldload ng_car
kldload ng_ipfw



for num in ${CLASSES_NUMS}; do
#  FW_NUM=`expr  `;
  echo "Traffic: ${num} "

  #Shaped traffic
  ${IPFW} add ` expr 9100 + ${num} \* 10 ` skipto ` expr 10100 + ${num} \* 10 ` ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) ${IN_DIRECTION}
  ${IPFW} add ` expr 9100 + ${num} \* 10 + 5 ` skipto ` expr 10100 + ${num} \* 10 + 5 ` ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}


  ${IPFW} add ` expr 10100 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to any ${IN_DIRECTION}
  ${IPFW} add ` expr 10100 + ${num} \* 10 + 5 ` netgraph tablearg ip from any to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) ${OUT_DIRECTION}

  #Unlim traffic
  ${IPFW} add ` expr 10200 + ${num} \* 10 ` allow ip from table\(9\) to table\(${num}\) ${IN_DIRECTION}
  ${IPFW} add ` expr 10200 + ${num} \* 10 + 5 ` allow ip from table\(${num}\) to table\(9\) ${OUT_DIRECTION}


#  ${IPFW}  add ` expr 9000 + ${num} \* 10 ` netgraph tablearg ip from table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2  `\) to table\(${num}\) out via ${EXTERNAL_INTERFACE}
#  ${IPFW}  add ` expr 9000 + ${num} \* 10 + 5 ` netgraph tablearg ip from table\(${num}\) to table\(` expr ${USER_CLASS_TRAFFIC_NUM} + ${num} \* 2 - 2 + 1 `\) out via ${INTERNAL_INTERFACE}
done;

  echo "Global shaper"
  ${IPFW} add 10000 netgraph tablearg ip from table\(10\) to any ${IN_DIRECTION}
  ${IPFW} add 10010 netgraph tablearg ip from any to table\(11\) ${OUT_DIRECTION}
  ${IPFW} add 10020 allow ip from table\(9\) to any ${IN_DIRECTION}
  ${IPFW} add 10025 allow ip from any to table\(9\) ${OUT_DIRECTION}
  ${IPFW} add 10030 allow ip from any to any via ${INTERNAL_INTERFACE} 
#done
else if [ w$1 = wstop -a w$2 = w ]; then

  echo -n "ng_car shapper" 

  for num in ${CLASSES_NUMS}; do
    ${IPFW} delete ` expr 9100 + ${num} \* 10 + 5 ` ` expr 9100 + ${num} \* 10 `  ` expr 9000 + ${num} \* 10 ` ` expr 10100 + ${num} \* 10 ` ` expr 9000 + ${num} \* 10 + 5 ` ` expr 10100 + ${num} \* 10 + 5 ` 
  done;

  ${IPFW} delete 9000 9005 10000 10010 10015
else if [ w$1 = w ]; then
    echo "(start|stop|start nat|stop nat)"
  fi;
 fi;
fi;



#ipfw 10 add divert 8668 ip from 3.3.3.0/24 to any
#ipfw 20 add divert 8778 ip from 4.4.4.0/24 to any
#ipfw 30 add fwd 1.1.1.254 ip from 1.1.1.1 to any
#ipfw 40 add fwd 2.2.2.254 ip from 2.2.2.2 to any
#ipfw 50 add divert 8668 ip from any to 1.1.1.1
#ipfw 60 add divert 8778 ip from any to 2.2.2.2 

#NAT Section
# options         IPFIREWALL_FORWARD
# options         IPFIREWALL_NAT          #ipfw kernel nat support
# options         LIBALIAS
#if [ w${abills_nat_enable} != w ] ; then

ISP_GW2="";

if [ w${NAT_IPS} != w  ] ; then

echo "NAT"
NAT_TABLE=20
NAT_FIRST_RULE=20
NAT_REAL_TO_FAKE_TABLE_NUM=33;
NAT_FAKE_IP_TABLE_NUM=33;



# nat configuration
for IP in ${NAT_IPS}; do
  if [ w$1 = wstart ]; then
    ${IPFW} nat ` expr ${NAT_FIRST_RULE} + 1 ` config ip ${IP} log
    ${IPFW} table ${NAT_REAL_TO_FAKE_TABLE_NUM} add ${IP} ` expr ${NAT_FIRST_RULE} + 1 `
    for f_net in ${FAKE_NET}; do
      ${IPFW} table ` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1` add ${f_net} ` expr ${NAT_FIRST_RULE} + 1 `
    done;
  fi;
done;
#Second way
#${IPFW} nat 22 config ip 192.168.72.140 log
#${IPFW} table 33 add 192.168.72.140 22
#${IPFW} table 34 add 172.19.0.0/16 22
#${IPFW} 30 add fwd 192.168.72.1 ip from 192.168.72.140 to any    


# nat real to fake
#${IPFW} add 00600 nat tablearg ip from any to table\(21\) in recv ${EXTERNAL_INTERFACE}
# nat fake to real
#${IPFW} add 17000 nat tablearg ip from table\(20\) to not 193.138.244.2 out

if [ w$1 = wstart ]; then
  if [ w${NAT_IF} != w ]; then
    NAT_IF="via ${NAT_IF}"
  fi;

  ${IPFW} add 60010 nat tablearg ip from table\(` expr ${NAT_REAL_TO_FAKE_TABLE_NUM} + 1 `\) to any $NAT_IF
  ${IPFW} add 60020 nat tablearg ip from any to table\(${NAT_REAL_TO_FAKE_TABLE_NUM}\) $NAT_IF
  
  if [ w${ISP_GW2} != w ]; then
    ${IPFW} add 30 add fwd ${ISP_GW2} ip from ${NAT_IPS} to any
  fi;
else if [ w$1 = wstop ]; then
  ${IPFW} delete 60010 60020
fi;
fi;

fi;


#FWD Section
if [ w${NEG_DEPOSIT_FWD} != w ]; then
  if [ w${WEB_SERVER_IP} = w ]; then
    WEB_SERVER_IP=127.0.0.1;
  fi;

INTERNAL_IF="ng*";
FWD_RULE=10014;


#Forwarding
if [ w$1 = wstart ]; then
  echo "Negative Deposit Forward Section - start"; 
  ${IPFW} add ${FWD_RULE} fwd ${WEB_SERVER_IP},80 tcp from table\(32\) to any dst-port 80,443 via ${INTERNAL_IF}
  ${IPFW} add `expr ${FWD_RULE}+10` deny ip from table\(32\) to any via ${INTERNAL_IF}
else if [ w$1 = wstop ]; then
  echo "Negative Deposit Forward Section - stop:"; 
  ${IPFW} delete ${FWD_RULE}
  ${IPFW} delete `expr ${FWD_RULE}+10`
else if [ w$1 = wshow ]; then
  echo "Negative Deposit Forward Section - status:"; 
  ${IPFW} show ${FWD_RULE}
fi;
fi;
fi;

fi;
