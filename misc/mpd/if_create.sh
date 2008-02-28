#!/bin/sh
#Make mpd interfaces

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
        -h)     help; exit;
                ;;
        esac
done



conf="";
interfaces_list="";
intefaces_records="";
links_list="";


while [ ${start} -lt ${count}  ]  
 do
   #echo "${start}";
   #mpd.conf
   if [ w${mpd_links} = w1 ]; then
     links_list=${links_list}"${interface_type}${start}: 
        set link type ${interface_type}
";
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



