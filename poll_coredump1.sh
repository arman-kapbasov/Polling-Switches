#!/bin/bash
#Arman Kapbasov
#Parts adapted from www.stackoverflow.com 

#change X_interval value for amount of seconds to wait poll to poll
X_interval=15

#================USAGE============
#To run..
#        ./poll_coredump.sh [IP filename]

#add -h for HELP menu

#Default output..
#       Goes to STDOUT

#==========Flags==========
#HELP Function
function HELP {
  echo -e \\n"To run:"\\n"     ./poll_coredump.sh [IP filename]"\\n
  echo -e "Prompt HELP menu:
     ./poll_coredump.sh -h"\\n
  echo -e "Change the interval time X within file: 
     edit variable 'X_interval'"\\n
  exit 1
}

while getopts "hod:f:" opt; do
        case $opt in
        h)
                HELP
            exit 1
        ;;
        \?)
                echo -e \\n"Unrecognized option -$OPTARG"
                HELP
                exit 1
        ;;
        esac
done

#================Read from file==========
read_file(){
c="$p -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null"
#cat $IP_file | grep -v '^#' | while read line
while read line
do
	timedateO=$(date +"%d/%m/%Y %r")
        if [ "$line" != "" ]; then
		#echo -e "\n${line} [${timedate}]"
		$(scp -r $c root@$line:/var/lib/systemd/coredump $timedate.$line.coredump)
		if [ "$(ls -A $timedate.$line.coredump)" ]; then
			#for file in $timedate.$line.coredump/*
			#do
				echo "Coredump found on IP $line at $timedateO"
			#done
		fi
		rm -r $timedate.$line.coredump
		#output=$output 	
        fi #remove white lines
done< <(cat $IP_file | grep -v '^#')
echo ""
}
#check for command line arguments
if [ $# -eq 0 ]; then
    echo -e \\n"Error:Invalid script call; opening [HELP MENU].."
    HELP
    exit 1
fi
IP_file=${1}

#==========initial connectivity check========
ok="22/tcp open ssh"
flag=0
#cat $IP_file | grep -v '^#' |  while read line
while read line
do
   if [ "$line" != "" ]; then
      var=`nmap $line -PN -p ssh| grep 22/tcp`
      if [[ $(echo $var) == $ok ]] ; then
         echo -e $line" [connection ready].."
      else
         echo -e "$line [cannot connect].."
         flag=1
      fi
   fi #remove white lines
done < <(cat $IP_file | grep -v '^#') 
if [ $flag -eq 1 ]; then
   echo -e \\n"One or more IPs are not reachable!"
   echo -e ">>Exiting.."\\n
   exit 1
fi
#============Main loop===================
echo "Starting.."
while : 
do
   timedate=$(date +"%Y.%m.%d-%H.%M.%S")
   read_file 
   sleep $X_interval
done


