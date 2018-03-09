#!/bin/bash
#Llinux scripts debugging
#set -u
#set -x
#set -e

source /etc/profile

INNODBST='/tmp/stats/innodbstatus'
PROCEST='/tmp/stats/processlist'
DBSTATS='/tmp/stats/dbstatus'
ANAYLYZE='/root/hi_anaylyze.sh'



innodbst(){
for i in `ls /root/5-sec-status-*-innodbstatus`
do 
	/bin/bash ${ANAYLYZE} $i >>${INNODBST}
done
}

procesli(){
for i in `ls /root/5-sec-status-*-processlist`
do 
	/bin/bash ${ANAYLYZE} $i >>${PROCEST}
done
}

dbstatus(){
for i in `ls /root/5-sec-status-*-status`
do 
	/bin/bash ${ANAYLYZE} $i >>${DBSTATS}
done
}



case "$1" in
		innodbst)
		innodbst
		;;
		procesli)
		procesli
		;;
		dbstatus)
		dbstatus
		;;
		*)
		echo -e "\033[32mUsage: service `basename $0` {innodbst|procesli|dbstatus}\033[0m"
		exit 2
		;;
esac
