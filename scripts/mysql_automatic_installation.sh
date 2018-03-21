#!/bin/bash
#MySQL_Automatic_Installation scripts
#by jiajia


yum remove -y mariadb*
yum install -y perl-Module-Install.noarch  libaio libaio-devel

groupadd mysql
useradd -g mysql -d /usr/local/mysql -s /sbin/nologin -M mysql
cd /tmp
wget https://downloads.mysql.com/archives/get/file/mysql-5.7.20-linux-glibc2.12-x86_64.tar.gz
tar xf mysql-5.7.20-linux-glibc2.12-x86_64.tar.gz -C /opt/
ln -sv /opt/mysql-5.7.20-linux-glibc2.12-x86_64  /usr/local/mysql

mkdir /data/mysql/mysql3306/{data,logs,tmp} -pv
chown -R mysql.mysql /data/
chown -R mysql.mysql /usr/local/mysql/
chown -R mysql.mysql /usr/local/mysql


cat >/etc/my.cnf<<EOF
[client]
port            = 3306
socket          = /tmp/mysql3306.sock

[mysql]
prompt="\\u@\\h [\\d]>"
no-auto-rehash

[mysqld]
user = mysql
basedir = /usr/local/mysql
datadir = /data/mysql/mysql3306/data
port = 3306

socket = /tmp/mysql3306.sock
event_scheduler = 0

tmpdir = /data/mysql/mysql3306/tmp
interactive_timeout = 300
wait_timeout = 300

character-set-server = utf8

open_files_limit = 65535
max_connections = 100
max_connect_errors = 100000
lower_case_table_names =1

log-output=file
slow_query_log = 1
slow_query_log_file = slow.log
log-error = error.log
log_warnings = 2
pid-file = mysql.pid
long_query_time = 1
log-slow-slave-statements = 1

binlog_format = row
server-id = 1003306
log-bin = /data/mysql/mysql3306/logs/mysql-bin
max_binlog_size = 256M
sync_binlog = 0
expire_logs_days = 10
log_bin_trust_function_creators=1

secure_file_priv="/tmp"
gtid-mode = on
enforce-gtid-consistency=1

skip_slave_start = 1
max_relay_log_size = 128M
relay_log_purge = 1
relay_log_recovery = 1
relay-log=relay-bin
relay-log-index=relay-bin.index
log_slave_updates

table_open_cache = 2048
table_definition_cache = 2048
table_open_cache = 2048
max_heap_table_size = 96M
sort_buffer_size = 128K
join_buffer_size = 128K
thread_cache_size = 200
query_cache_size = 0
query_cache_type = 0
query_cache_limit = 256K
query_cache_min_res_unit = 512
thread_stack = 192K
tmp_table_size = 96M
key_buffer_size = 8M
read_buffer_size = 2M
read_rnd_buffer_size = 16M
bulk_insert_buffer_size = 32M

myisam_sort_buffer_size = 128M
myisam_max_sort_file_size = 10G
myisam_repair_threads = 1

innodb_buffer_pool_size = 100M
innodb_buffer_pool_instances = 1
innodb_data_file_path = ibdata1:100M:autoextend
innodb_flush_log_at_trx_commit = 2
innodb_log_buffer_size = 8M
innodb_log_file_size = 100M
innodb_log_files_in_group = 3
innodb_max_dirty_pages_pct = 50
innodb_file_per_table = 1
innodb_rollback_on_timeout
innodb_io_capacity = 2000
transaction_isolation = READ-COMMITTED
innodb_flush_method = O_DIRECT
EOF


/usr/local/mysql/bin/mysqld --defaults-file=/etc/my.cnf --initialize

cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
echo -e "#MySQL PATH\nexport PATH=\$PATH:/usr/local/mysql/bin" >>/etc/profile
source /etc/profile

/etc/init.d/mysqld start 


chmod +x /etc/rc.d/rc.local
echo "/etc/init.d/mysqld start" >>/etc/rc.d/rc.local
PW=`cat /data/mysql/mysql3306/data/error.log |grep 'temporary password'`
print "MySQL root Password is ${PW}"
