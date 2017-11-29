#!/bin/bash
# 需要启用DEBUG模式时将下面三行注释去掉即可
#set -u
#set -x
#set -e


#export LD_LIBRARY_PATH=/usr/local/mysql/lib/
source /etc/profile

DBIP=`ifconfig  eth0|grep "inet"|awk -F ' ' 'NR==1{print $2}'`
DBPORT=3306
DBUSER='sysbench'
DBPASSWD='sysbench123'
NOW=`date +'%Y:%m:%d:%H:%M'`
DBNAME="sbtest"
TBLCNT=50
WARMUP=300
DURING=900
ROWS=20000000
MAXREQ=20000000
LUA=/mysql/lua/oltp.lua
SYSBSE="/mysql/sysbench/logs"

# 并发压测的线程数，根据机器配置实际情况进行调整
RUN_NUMBER="8 64 128 256 512 768 1024 1664 2048 4096"

if [ ! -d $SYSBSE ];then
	mkdir -pv ${SYSBSE}
else
	echo -e "\033[32m ${SYSBSE} Directory Exists \033[0m" 		
fi 


prepare() {
echo -e "\033[32m SYSBENCH 创建测试数据 \033[0m"  &&
/usr/bin/sysbench  --mysql-host=$DBIP --mysql-port=$DBPORT --mysql-user=$DBUSER --mysql-password=$DBPASSWD --test=$LUA --oltp_tables_count=10 --oltp-table-size=100000 --rand-init=on prepare >> ${SYSBSE}/sysbench_prepare_${NOW}.log
}



sysbench() {
echo -e "\033[32m SYSBENCH 进行数据测试 \033[0m"  &&
# 一般至少跑3轮测试，我正常都会跑10轮以上
while [ $round -lt 4 ]
do

round=1
rounddir=logs-round${round}
mkdir -p ${rounddir}

for thread in `echo "${RUN_NUMBER}"`
do

/usr/bin/sysbench --test=$LUA --db-driver=mysql --mysql-host=$DBIP --mysql-port=$DBPORT --mysql-user=$DBUSER --mysql-password=$DBPASSWD --oltp-table-size=${ROWS} --rand-init=on --threads=${thread} --oltp-read-only=off --report-interval=1 --rand-type=uniform --max-time=${DURING} --max-requests=0 --percentile=99 run >> ${SYSBSE}/${rounddir}/sbtest_${thread}_${NOW}.log

sleep 300
done

round=`expr $round + 1`
sleep 300
done
}


cleanup() {
/usr/bin/sysbench  --mysql-host=$DBIP --mysql-port=$DBPORT --mysql-user=$DBUSER --mysql-password=$DBPASSWD --test=$LUA --oltp_tables_count=10 --oltp-table-size=100000 --rand-init=on cleanup >> ./sysbench_cleanup_${NOW}.log
}


case "$1" in
		prepare)
		prepare
		;;
		sysbench)
		sysbench
		;;
		cleanup)
		cleanup
		;;
		*)
		echo "Usage: service `basename $0` {prepare|sysbench|cleanup}"
		exit 2
		;;
esac



# 记录所有错误及标准输出到 sysbench.log 中
exec 3>&1 4>&2 1>> sysbench_`date +%Y%m%d`.log 2>&1
