#!/bin/sh
# Message filter managment script
# Add, del filters

version=0.1
DEBUG=1;
IP=$1;
MYSQL_USER=root;
MYSQL_DB=abills;
MSGS_TABLE_NUM=100

if [ w$1 = w ]; then
  echo "Add arguments";
  exit
fi;



#Add online filter
if [ w$1 = wadd ]; then
  SQL="select INET_NTOA(framed_ip_address) from dv_calls WHERE uid IN ($3);";
  OUTPUT=`mysql -D ${MYSQL_DB} -u ${MYSQL_USER} -e "$SQL"`;

  for LINE in ${OUTPUT}; do
  
    IP=`echo ${LINE} | awk '{ print $1 }'`;
 #   UID=`echo ${LINE} | awk '{ print $2 }'`;
   
    if [ ${IP} != 'INET_NTOA(framed_ip_address)' ]; then
      if [ w${DEBUG} != w ]; then
        echo "/sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}";
      fi;
      /sbin/ipfw table ${MSGS_TABLE_NUM} add ${IP} ${UID}
    fi;
    
  done;
# Del redirect  
else 
  if [ w${DEBUG} != w ]; then
    echo "IP deleted - ${IP}"
  fi;
  /sbin/ipfw table ${MSGS_TABLE_NUM} delete ${IP}
fi;
