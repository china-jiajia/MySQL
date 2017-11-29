#!/bin/bash
# 需要启用DEBUG模式时将下面三行注释去掉即可
#set -u
#set -x
#set -e


#export LD_LIBRARY_PATH=/usr/local/mysql/lib/
source /etc/profile

MEM=1
HHD=50
NOW=`date +'%Y%m%d%H%M'`
SYSBSE="/mysql/sysbench/logs"



if [ ! -d $SYSBSE ];then
        mkdir -pv ${SYSBSE}
else
        echo -e "\033[32m ${SYSBSE} Directory Exists \033[0m"           
fi 


cpu() {
echo -e "\033[32m 进行CPU压力测试: 寻找小于1千万的最大质数,并发线程数10,最大请求数100 \033[0m" &&
/usr/bin/sysbench --num-threads=10 --max-requests=100 --test=cpu --debug --cpu-max-prime=10000000 run >> ${SYSBSE}/sysbench_cpu_${NOW}.log
}

memr() {
echo -e "\033[32m 进行内存压力测试: 测试范围32G,并发线程数10,最大请求数100, 读  \033[0m" &&
/usr/bin/sysbench --num-threads=10 --max-requests=100 --test=memory --memory-block-size=8K --memory-total-size=${MEM}G --memory-oper=read run >> ${SYSBSE}/sysbench_memr_${NOW}.log
}

memw() {
echo -e "\033[32m 进行内存压力测试: 测试范围32G,并发线程数10,最大请求数100, 写  \033[0m" &&
/usr/bin/sysbench --num-threads=10 --max-requests=100 --test=memory --memory-block-size=8K --memory-total-size=${MEM}G --memory-oper=write run >> ${SYSBSE}/sysbench_memw_${NOW}.log
}

fileiop() {
echo -e "\033[32m 进行IO压力测试: 20个文件,每个10GB,随机读写 prepare  \033[0m" &&
/usr/bin/sysbench --file-num=20 --num-threads=20 --test=fileio --file-total-size=${HDD}G --max-requests=1000000 --file-test-mode=rndrw prepare >> ${SYSBSE}/sysbench_fileiop_${NOW}.log
}

fileior() {
echo -e "\033[32m 进行IO压力测试: 20个文件,每个10GB,随机读写 run  \033[0m" &&
/usr/bin/sysbench --file-num=20 --num-threads=20 --test=fileio --file-total-size=${HDD}G --max-requests=1000000 --file-test-mode=rndrw run >> ${SYSBSE}/sysbench_fileior_${NOW}.log
}

fileioc() {
echo -e "\033[32m 进行IO压力测试: 20个文件,每个10GB,随机读写 cleanup  \033[0m" && 
/usr/bin/sysbench --file-num=20 --num-threads=20 --test=fileio --file-total-size=${HDD}G --max-requests=1000000 --file-test-mode=rndrw cleanup >> ${SYSBSE}/sysbench_fileioc_${NOW}.log
}

thread() {
echo -e "\033[32m 进行thread测试 \033[0m" &&
/usr/bin/sysbench --num-threads=64 --test=threads --thread-yields=100 --thread-locks=2 run >> ${SYSBSE}/sysbench_thread_${NOW}.log
}

mutex() {
echo -e "\033[32m 进行互斥锁测试 \033[0m" &&
/usr/bin/sysbench --test=mutex --mutex-num=4096 --mutex-locks=50000 --mutex-loops=20000 run >> ${SYSBSE}/sysbench_mutex_${NOW}.log 
}


case "$1" in
                cpu)
                cpu
                ;;
                memr)
                memr
                ;;
                memw)
                memw
                ;;
                fileiop)
                fileiop
                ;;
                fileior)
                fileior
                ;;
                fileioc)
                fileioc
                ;;
                thread)
                thread
                ;;
                mutex)
                mutex
                ;;
                *)
                echo "Usage: service `basename $0` {cpu|memr|memw|fileiop|fileior|fileioc|thread|mutex}"
                exit 2
                ;;
esac

# 记录所有错误及标准输出到 sysbench.log 中
exec 3>&1 4>&2 1>> ./sysbench_`date +%Y%m%d`.log 2>&1
