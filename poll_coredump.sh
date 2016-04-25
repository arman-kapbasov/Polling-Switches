#!/bin/bash
#Arman Kapbasov
#Parts adapted from www.stackoverflow.com 

#change X_interval value for amount of seconds to wait poll to poll
X_interval=10

#================USAGE============
#To run..
#        ./poll_coredump.sh [IP filename] [email address]

#if you specify email address, script will send you email notifications 
#make sure you're linux machine has postfix or sendmail installed
#if no email is specified, default output is the command line


#flags
#add -h for HELP menu
#no flag (default) monitors coredumps
#add -s to monitor system failure units
#add -c to monitor coredumps


#Default output..
#       Goes to STDOUT

#==========Flags==========
#HELP Function
function HELP {
  echo -e \\n"To run:"\\n"     ./poll_coredump.sh [IP filename] [email *optional*]"\\n
  echo -e "Prompt HELP menu:
     ./poll_coredump.sh -h"\\n
  echo -e "Additional flags:
     ./poll_coredump.sh -c [IP filename] ------- Monitor coredumps"
  echo  -e "     ./poll_coredump.sh -s [IP filename] ------- Monitor failed system units"\\n
  echo -e "Change the interval time X within file: 
     Edit variable 'X_interval'"\\n
  exit 1
}
echo "#options"> .config
core=0
sys=0
while getopts "hscd:f:" opt; do
        case $opt in
        h)
                HELP
            exit 1
        ;;
	s)
		echo "sys" >> .config	
	;;
	c) 
		echo "core" >> .config
	;;
        \?)
                echo -e \\n"Unrecognized option -$OPTARG"
                HELP
                exit 1
        ;;
        esac
done

sysfile=".sysfile"
tempfile=".tempfile"
echo "#This file is used to monitor coredumps" >  $tempfile
echo "#format is: [timestamp] [switch coredump name]" >>  $tempfile
echo "#This file is used to monitor systemfails" >  $sysfile
echo "#format is: [timestamp] [systemfail]" >>  $sysfile

core_dump(){
	$(scp -r $c root@$line:/var/lib/systemd/coredump $line.coredump)
        if [ "$(ls -A $line.coredump)" ]; then
        	for file in $line.coredump/*
                        do
                                if grep $file $tempfile > /dev/null; then
                                        :
                                        #do nothing if already exists
                                else
                                        echo "$timedateO $file" >> $tempfile
					ecount=$((ecount+1))
                                        if [ $eflag -eq 0 ]; then
                                                echo "Coredump found on IP $line at $timedateO"
                                        else
                                                echo "Coredump found on IP $line at $timedateO" | mail -s "Coredump on <$line>" $email
                                                echo -en ">Email count [${ecount}]\r"
                                        fi
                                fi
                        done
        fi
        rm -r $line.coredump
}
system_fail(){
	$(ssh $c root@$line "cd && systemctl list-units  -all --state=failed | grep failed | awk '{ print \$2}'" > $timedate.sys </dev/null)
	while read line1
	do
		if grep $line1 .sys_$line > /dev/null; then
			:
			#do nothing
		else
		 	echo $line1 >> .sys_$line
			ecount=$((ecount+1))
			if [ $eflag -eq 0 ]; then
                        	echo "Failed service on IP $line at $timedateO [$line1] "
                        else
                                echo "Failed service on IP $line at $timedateO [$line1]" | mail -s "Failed service on <$line>" $email
                                echo -en ">Email count [${ecount}]\r"
                        fi

		fi
	done< <(cat $timedate.sys)
	rm $timedate.sys
}

#================Read from file==========
read_file(){
c="$p -o StrictHostKeyChecking=no -o LogLevel=ERROR -o UserKnownHostsFile=/dev/null"
#cat $IP_file | grep -v '^#' | while read line
while read line
do
	timedateO=$(date +"%d/%m/%Y %r")
        if [ "$line" != "" ]; then
        	if [ $core -eq 1 ]; then
			core_dump
		fi
		if [ $sys -eq 1 ]; then
                       	system_fail
                fi
	fi #remove white lines
done< <(cat $IP_file | grep -v '^#')
}
#check for command line arguments
if [ $# -eq 0 ]; then
    echo -e \\n"Error:Invalid script call; opening [HELP MENU].."
    HELP
    exit 1
fi
#used for traking number of emails
ecount=0 
count=$(wc -l ".config" | awk '{print $1;}')
if [ $count -eq 1 ]; then
	core=1
	IP_file=${1}
	eflag=0
	email=""
	if [ $# -eq 2 ]; then
   		eflag=1
 		email="${2}"
	fi
else
	if grep "sys" .config  > /dev/null; then
		sys=1
	fi
	if grep "core" .config  > /dev/null; then
                core=1
        fi
	IP_file=${2}
	eflag=0
	email=""
	if [ $# -eq 3 ]; then
   		eflag=1
   		email="${3}"
	fi
fi
rm .config
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
	 cat $sysfile > .sys_$line
      else
         echo -e "$line [cannot connect].."
         flag=1
      fi
   fi #remove white lines
done < <(cat $IP_file | grep -v '^#') 
if [ $flag -eq 1 ]; then
   echo -e \\n"One or more IPs are not reachable!"
   echo -e ">>Exiting.."\\n
   rm .sys*
   exit 1
fi
rm .sysfile
#============Main loop===================i
echo "Starting.."
while : 
do
   timedate=$(date +"%Y.%m.%d-%H.%M.%S")
   read_file
   sleep $X_interval
done


