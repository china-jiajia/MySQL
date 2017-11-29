#!/bin/bash

source /etc/profile
IP=`ifconfig  eth0|grep "inet"|awk -F ' ' 'NR==1{print $2}'`
DATABASE=tpcc
USER=tpcc
PASSWORD=tpcc123
NOW=`date +'%Y%m%d%H%M'`
TPCCBSE="/mysql/tpcc/logs" 


if [ ! -d $TPCCBSE ];then
        mkdir -pv ${TPCCBSE}
else
        echo -e "\033[32m ${TPCCBSE} Directory Exists \033[0m"           
fi 


tpload(){
echo -e "\033[32m TPCC-LOAD 创建测试数据 \033[0m"  &&
/mysql/tpcc-mysql/tpcc_load  ${IP} ${DATABASE} ${USER} ${PASSWORD} 300 >> ${TPCCBSE}/tpcc_load_${NOW}.log
}

tpstart(){
echo -e "\033[32m TPCC-START 进行数据测试 \033[0m"  &&
/mysql/tpcc-mysql/tpcc_start -h ${IP} -d ${DATABASE} -u ${USER}  -p ${PASSWORD} -w 200 -c 12 -r 300 -l 1800 -f ${TPCCBSE}/tpcc_mysql_${NOW}.log >> ${TPCCBSE}/tpcc_caseX_${NOW}.log 2>&1
}


case "$1" in
                tpload)
                tpload
                ;;
                tpstart)
               	tpstart
                ;;
                *)
                echo "Usage: service `basename $0` {tpload|tpstart}"
                exit 2
                ;;
esac


# 记录所有错误及标准输出到 tpcc.log 中
exec 3>&1 4>&2 1>> ./tpcc_`date +%Y%m%d`.log 2>&1
