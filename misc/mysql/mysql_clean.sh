#!/bin/sh
# Clean Mysql logs
# Freeradius log


VERSION=0.2;
MYSQL_BIN_PREFIX='abills-bin.';
MYSQL_DATADIR='/var/db/mysql';
USER=root
PASSWORD=

#Rotate mysql general_log
MYSQL_CMD="USE mysql;
CREATE TABLE IF NOT EXISTS general_log2 LIKE general_log;
CREATE TABLE IF NOT EXISTS general_log_backup LIKE general_log;
DROP TABLE IF EXISTS general_log_backup2;
RENAME TABLE general_log_backup TO general_log_backup2, general_log TO general_log_backup, general_log2 TO general_log;
";

#MYSQL_CMD="TRUNCATE TABLE general_log;";

# Disable mysql General LOG
/usr/local/bin/mysql -D mysql -u ${USER} --password=${PASSWORD} -e "SET GLOBAL general_log = 'OFF';"
/usr/local/bin/mysql -D mysql -u ${USER} --password=${PASSWORD} -e "${MYSQL_CMD}"

#Clean mysql bin log
#rm /usr/mysql/asr-bin.*




cd ${MYSQL_DATADIR}


 
WORK_BIN=`mysql -u ${USER} --password=${PASSWORD} -e "show master status;" | grep abills | awk '{ print $1 }'`
for file in  ` ls ${MYSQL_BIN_PREFIX}0*`; do

  if [ ${file} != ${WORK_BIN} ]; then
    if [ ${file} != ${WORK_BIN}index ] ; then
      echo "${file}";
      rm ${MYSQL_DATADIR}/${file};
    fi;
  fi;


done;

rm -rf /var/log/radacct/*
