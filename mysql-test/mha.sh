#!/bin/bash
# 需要启用DEBUG模式时将下面三行注释去掉即可
#set -u
#set -x
#set -e


#export LD_LIBRARY_PATH=/usr/local/mysql/lib/
source /etc/profile

#/usr/bin/masterha_conf_host
#/usr/bin/masterha_master_monitor
#/usr/bin/masterha_master_switch
#/usr/bin/masterha_secondary_check

VIP='10.96.28.128'
IP='/sbin/ip'
SSH_STATUS='/usr/bin/masterha_check_ssh'
EPEL_STATUS='/usr/bin/masterha_check_repl'
START='/usr/bin/masterha_manager'
STATUS='/usr/bin/masterha_check_status'
STOP='/usr/bin/masterha_stop'
CONFILES='/etc/masterha/app1.cnf'
MHALOG='/masterha/logs/manager.log'
MANAGERPID=`/usr/bin/masterha_check_status --conf=/etc/masterha/app1.cnf|awk '{print $2}'|awk -F ':' '{print $2}'|awk -F ")" '{print $1}'`
#MANAGERPID=`ps -ef |grep -v  grep |grep "manager"|awk '{print $2}'`

mha_start() {
	if [ -z "$MANAGERPID" ];then
		nohup	$START --conf=$CONFILES	--remove_dead_master_conf --ignore_last_failover< /dev/null >$MHALOG 2>&1 &  
		$IP addr add $VIP dev bond0
	else 
		echo -e "\033[32m MHAPID is $MANAGERPID \033[0m"
	fi
} 

mha_stop() {
	if [ -z "$MANAGERPID" ];then
		echo -e "\033[32m MHA-Server is STOP! \033[0m"
		exit 0
	else 
		$STOP --conf=$CONFILES	&& 
		$IP addr del $VIP dev bond0
	fi
}

mha_status() {
	$STATUS --conf=$CONFILES  && 
	echo -e "\033[32m Virtual IP is $VIP \033[0m"
}

ssh_status() {
	$SSH_STATUS --conf=$CONFILES 
} 

epel_status() {
	 $EPEL_STATUS --conf=$CONFILES 
} 


case "$1" in
		mha_start)
		mha_start
		;;
		mha_stop)
		mha_stop
		;;
		mha_status)
		mha_status
		;;
		ssh_status)
		ssh_status
		;;
		epel_status)
		epel_status
		;;
		*)
		echo -e  "\033[32mUsage: service `basename $0` {mha_start|mha_stop|mha_status|ssh_status|epel_status}\033[0m"
		exit 2
		;;
esac



# 记录所有错误及标准输出到 sysbench.log 中
exec 3>&1 4>&2 1>> mha_`date +%Y%m%d`.log 2>&1
