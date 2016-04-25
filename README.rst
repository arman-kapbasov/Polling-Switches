============================================
Polling Switches Script
============================================

Library to poll switches for coredumps and failed system units


Link to SIG Wiki
============================================

	https://rndwiki.corp.hpecorp.net/confluence/display/hpnevpg/Coredump+and+Failed+System+Units+Polling+Script


Usage
============================================

Running:
To run..
./poll_coredump.sh [IP filename] [email address]
   if you specify email address, script will send you email notifications
   make sure you're linux machine has postfix or sendmail installed
   if no email is specified, default output is the command line
add -h flag for HELP menu
     ./poll_coredump.sh -h
 
no flag (default) monitors coredumps:
      ./poll_coredump.sh [IP filename]
add -s to monitor system failure units
      ./poll_coredump.sh -s [IP filename]
add -c to monitor coredumps
      ./poll_coredump.sh -c [IP filename]
 
To change the interval:
     edit the variable 'X_interval' on top of the script within the file 
