#!/bin/sh
#Make mpd interfaces
#
# Example:
# Create pppoe for multiple interfaces
# ./if_create.sh -links -c 1000 -pppoe_interfaces vlan100-vlan200 -t pppoe

start=0;
count=100;
interface_type="pptp";


help () {
  echo "MPD 3,4 auto links creation
 -s     - Start Number
 -c     - Total Creation Interfaces
 -t     - INterface type pptp, l2tp (Default: pptp)
 -conf  - Create mpd.conf interfaces
 -links - Create mpd.links interfaces
 -h     - help
 -pppoe_interfaces - pppoe interfaces
 
";
}


# Proccess command-line options
#
for _switch ; do
        case $_switch in
        -s)
                start="$2"
                shift; shift
                ;;
        -c)
                count="$2"
                shift; shift
                ;;
        -t)
                interface_type="$2"
                shift; shift;
                ;;
        -conf)  
                mpd_conf=1
                shift
                ;;
        -links)  
                mpd_links=1
                shift
                ;;
        -pppoe_interfaces)
                pppoe_interfaces="$2"
                shift; shift;
                ;;
        -h)     help; exit;
                ;;
        esac
done



conf="";
interfaces_list="";
intefaces_records="";
links_list="";

if [ w`echo "${pppoe_interfaces}" | sed -n "/-/p"` != w ]; then
  FIRST_IF=`echo "${pppoe_interfaces}" | awk -F - '{ print $1 }' | sed  's/[a-z]*//'`
  LAST_IF=`echo "${pppoe_interfaces}" | awk  -F - '{ print $2 }' | sed  's/[a-z]*//'`
  IF_PREFIX=`echo "${pppoe_interfaces}" | awk  -F - '{ print $2 }' | sed 's/\([a-z]*\)[0-9]*/\1/'`
  
  pppoe_interfaces="";
  while [ ${FIRST_IF} -lt ${LAST_IF}  ] ; do
    pppoe_interfaces="${pppoe_interfaces} ${IF_PREFIX}${FIRST_IF}";
    FIRST_IF=`expr ${FIRST_IF} + 1`
  done;
fi;

while [ ${start} -lt ${count}  ]  
 do
   #echo "${start}";
   #mpd.conf
   if [ w${mpd_links} = w1 ]; then

     if [ w${interface_type} = wpppoe ]; then
       for if in ${pppoe_interfaces}; do
         links_list="${links_list}${interface_type}${start}: 
        set link type ${interface_type}
        set pppoe iface ${if}
"
         start=`expr ${start} + 1`
       done;
       start=`expr ${start} - 1`
     else
       links_list=${links_list}"${interface_type}${start}: 
        set link type ${interface_type}
";
     fi;
   else
     interfaces_list="${interfaces_list}  load ${interface_type}${start}
";    

     intefaces_records=${intefaces_records}"${interface_type}${start}:
      new -n -i ng${start} ${interface_type}${start} ${interface_type}${start}
      load ${interface_type}
";
   
   fi;
   start=`expr ${start} + 1`
 done


if [ w${mpd_links} = w1 ]; then
  echo "${links_list}";

else 
  echo "default:";
  echo "${interfaces_list}";
  echo "";
  echo "${intefaces_records}";
fi;



