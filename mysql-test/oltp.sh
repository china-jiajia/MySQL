#!/bin/bash
# 需要启用DEBUG模式时将下面三行注释去掉即可
#set -u
#set -x
#set -e


#export LD_LIBRARY_PATH=/usr/local/mysql/lib/
source /etc/profile

DBIP=`ifconfig  eth0|grep "inet"|awk -F ' ' 'NR==1{print $2}'`
DBPORT=3306
DBUSER='test'
DBPASSWD='test123'
NOW=`date +'%Y:%m:%d:%H:%M'`
DBNAME="sysbench"
TBLCNT=50
WARMUP=300
DURING=900
ROWS=10000000
MAXREQ=20000000
LUA=/usr/local/share/sysbench/oltp_read_write.lua
SYSLOG="/mysql/sysbench/logs"

# 并发压测的线程数，根据机器配置实际情况进行调整
RUN_NUMBER="8 64 128 256 512 768 1024 1664 2048 4096"

if [ ! -d $SYSLOG ];then
	mkdir -pv ${SYSLOG}
else
	echo -e "\033[32m ${SYSLOG} Directory Exists \033[0m" 		
fi



prepare() {
echo -e "\033[32m SYSBENCH 创建测试数据 \033[0m"  && 
/usr/bin/sysbench  --test=${LUA}  --mysql-user=${DBUSER} --mysql-password=${DBPASSWD} --mysql-port=${DBPORT}  --mysql-host=${DBIP}  --mysql-db=${DBNAME} --tables=10 --table-size=${ROWS} --threads=32 --events=5000000 --report-interval=5 prepare >> ${SYSLOG}/sysbench_prepare_${NOW}.log
} 



sysbench() {
echo -e "\033[32m SYSBENCH 进行数据测试 \033[0m"  &&
# 一般至少跑3轮测试，我正常都会跑10轮以上

round=1
while [ $round -lt 4 ]
do

rounddir=logs-round${round}
mkdir -p ${SYSLOG}/${rounddir}

for thread in `echo "${RUN_NUMBER}"`
do
 
/usr/bin/sysbench  --test=${LUA} --mysql-user=${DBUSER} --mysql-port=${DBPORT} --mysql-password=${DBPASSWD} --mysql-host=${DBIP} --mysql-db=${DBNAME} --tables=10 --table-size=${ROWS} --threads=${thread}  --report-interval=5 --time=${DURING} --percentile=99 run  >> ${SYSLOG}/${rounddir}/sbtest_${thread}_${NOW}.log


sleep 300
done

round=`expr $round + 1`
sleep 300
done
}


cleanup() {
echo -e "\033[32m SYSBENCH 清除测试数据 \033[0m"  &&
 /usr/bin/sysbench  --test=${LUA}  --mysql-user=${DBUSER} --mysql-password=${DBPASSWD} --mysql-port=${DBPORT}  --mysql-host=${DBIP}  --mysql-db=${DBNAME} --tables=10 --table-size=${ROWS} --threads=32 --events=5000000 --report-interval=5 cleanup >> ${SYSLOG}/sysbench_cleanup_${NOW}.log
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
