#!/bin/sh
#Llinux scripts debugging
#set -u
#set -x
#set -e

source /etc/profile

#开始前获取全局配置参数
#每五秒获取一次cpu load,MySQL全局信息，InnoDB引擎相关信息，线程信息 
INTERVAL=5
PREFIX='/tmp/$INTERVAL-sec-status'
RUNFILE=/root/running
RDIP='10.96.28.140'
mysql -h ${RDIP}  -uroot -e 'show global variables'>>mysql-variables

INNODBST='/tmp/stats/innodbstatus'
PROCEST='/tmp/stats/processlist'
DBSTATS='/tmp/stats/dbstatus'
ANAYLYZE=`awk '
        BEGIN{
                printf "#ts date time load QPS";
                fmt = " %.2f";
                }
                /^TS/ { # The timestamp lines begin with TS.
                        ts = substr($2, 1, index($2,".") - 1);
                        load = NF -  2;
                        diff = ts -prev_ts;
                        prev_ts = ts;
                        printf "\n%s %s %s %s",ts,$3,$4,substr($load, 1, length($load)-1);
                }
                /Queries/ {
                        printf fmt, ($2-Queries)/diff;
                        Queries=$2
                }
                ' "$@"`


whilefile(){
sleep 3
echo -e "\033[32m###通过检测 /root/running文件是否存在作为是否进行获取信息的依据,可以在压测结束时删除此文件停止收集###\033[0m"
while  test -e $RUNFILE; do
        file=$(date +%F_%H)
        sleep=$(date +%s.%N |awk "{print $INTERVAL -(\$1 % $INTERVAL)}")
        sleep $sleep
        ts="$(date +"TS %s.%N %F %T")"
        loadavg="$(uptime)"                                 
        echo "$ts $loadavg">> $PREFIX-${file}-status
        mysql -h ${RDIP}  -uroot -e "show global status" >> $PREFIX-${file}-status &  
        echo "$ts $loadavg">> $PREFIX-${file}-innodbstatus
        mysql -h ${RDIP}  -uroot -e "show engine innodb status\G" >> $PREFIX-${file}-innodbstatus &    
        echo "$ts $loadavg">> $PREFIX-${file}-processlist
        mysql -h ${RDIP}  -uroot -e "show full processlist\G" >>$PREFIX-${file}-processlist & 
        echo $ts
done
echo Exiting because $RUNFILE not exist 
}

innodbst(){
for i in `ls $PREFIX-*-innodbstatus`
do 
        ${ANAYLYZE} $i >>${INNODBST}
done
}

procesli(){
for i in `ls $PREFIX-*-processlist`
do 
        ${ANAYLYZE} $i >>${PROCEST}
done
}

dbstatus(){
for i in `ls $PREFIX-*-status`
do 
        ${ANAYLYZE} $i >>${DBSTATS}
done
}



case "$1" in
                whilefile)
                whilefile
                ;;
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
                echo -e "\033[32mUsage: service `basename $0` {whilefile|innodbst|procesli|dbstatus}\033[0m"
                exit 2
                ;;
esac