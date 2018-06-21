#!/bin/bash

GROUPADD='/usr/sbin/groupadd'
USERADD='/usr/sbin/useradd'
MAKE='/usr/bin/make'
CP='/bin/cp'
CHOWN='/bin/chown'
WGET='/usr/bin/wget'
TAR='/bin/tar'
YUM='/usr/bin/yum'
CMAKE='/usr/bin/cmake'
ROOT='/root'

MYSQLGROUP='mysql'
MYSQLUSER='mysql'
BASEDIR='/mnt/mysql5636'
DATADIR='/data/ane56'
MYSQLBINLOG='/data/mysqlbinlog'
CONF='/mnt/mysql5636/etc'
INIT='/mnt/mysql5636/init.d'
SOCKET='/data/ane56/mysqld.sock'
PORT='3306'
MYSQL='/usr/bin/mysql'
PACKAGE='percona-server-5.6.36-82.0.tar.gz'
SOURCEFOLDER='percona-server-5.6.36-82.0'
LIB='libev4-4.15-7.1.x86_64.rpm'
BACKFILE='percona-xtrabackup-24-2.4.7-1.el6.x86_64.rpm'


## create mysql group if not exists
USERGROUP=`grep 'mysql' /etc/group | awk -F ':' '{print $1}'`
if [[ $USERGROUP = $MYSQLGROUP ]]; then
	echo 'The group has being exists.'
   else
	echo 'The group not exists and will create it.'
	$GROUPADD $MYSQLGROUP
fi

## create mysql user if not exists
USER=`grep 'mysql' /etc/passwd | awk -F ':' '{print $1}'`
if [[ $USER = $MYSQLUSER ]]; then
	echo 'The user has being exists.'
   else
	echo 'The user not exists and will create it.'
	$USERADD -r -g $MYSQLGROUP $MYSQLUSER
fi

## create basedir if not exists
if [ ! -d $BASEDIR ]; then
	echo 'The basedir not exists and will create it.'
	mkdir -p $BASEDIR
	mkdir $CONF
	mkdir $INIT
   else
	echo 'The basedir has being exists.'
fi

## create datadir if not exists
if [ ! -d $DATADIR ]; then
        echo 'The datadir not exists and will create it.'
        mkdir -p $DATADIR
   else
        echo 'The datadir has being exists.'
fi

## create mysqlbinlog if not exists
if [ ! -d $MYSQLBINLOG ]; then
        echo 'The mysqlbinlog not exists and will create it.'
        mkdir -p $MYSQLBINLOG
   else
        echo 'The mysqlbinlog has being exists.'
fi

## download install package if not exists
if [ ! -f $PACKAGE ]; then
	$WGET https://www.percona.com/downloads/Percona-Server-5.6/Percona-Server-5.6.36-82.0/source/tarball/percona-server-5.6.36-82.0.tar.gz
fi

## delete folder if the install folder exists
if [ ! -d $SOURCEFOLDER ]; then
	$TAR zxvf $PACKAGE
	cd $SOURCEFOLDER
else
	rm -rf $SOURCEFOLDER
	$TAR zxvf $PACKAGE
        cd $SOURCEFOLDER
fi

## deps package
$YUM -y install make gcc-c++ cmake bison-devel  ncurses-devel gcc autoconf automake zlib* fiex* libxml* libmcrypt* libtool-ltdl-devel* perl libaio-devel readline-devel openssl* screen lrzsz lsof

## install mysql
$CMAKE -DCMAKE_INSTALL_PREFIX=$BASEDIR -DMYSQL_DATADIR=$DATADIR -DSYSCONFDIR=$CONF -DWITH_MYISAM_STORAGE_ENGINE=1 -DWITH_INNOBASE_STORAGE_ENGINE=1 -DWITH_MEMORY_STORAGE_ENGINE=1 -DWITH_ARCHIVE_STORAGE_ENGINE=1 -DWITH_BLACKHOLE_STORAGE_ENGINE=1 -DWITH_PERFSCHEMA_STORAGE_ENGINE=1 -DWITH_FEDERATED_STORAGE_ENGINE=1 -DMYSQL_UNIX_ADDR=$SOCKET -DMYSQL_TCP_PORT=$PORT -DENABLED_LOCAL_INFILE=1 -DWITH_PARTITION_STORAGE_ENGINE=1 -DEXTRA_CHARSETS=all -DDEFAULT_CHARSET=utf8 -DDEFAULT_COLLATION=utf8_general_ci -DMYSQL_USER=$MYSQLUSER && \
$MAKE && $MAKE install 
cd $BASEDIR 
$CHOWN -R $MYSQLUSER:$MYSQLUSER . 
scripts/mysql_install_db --user=$MYSQLUSER --datadir=$DATADIR 
$CP support-files/mysql.server $INIT/mysql 
$CHOWN -R $MYSQLUSER:$MYSQLUSER $DATADIR 
$CHOWN -R $MYSQLUSER:$MYSQLUSER $MYSQLBINLOG 
$CP $BASEDIR/bin/* /usr/bin 
cat << EOF > $CONF/my.cnf
[client]
port = 3306
socket = /data/ane56/mysqld.sock
[mysqld]
server_id = 1 # 每组里面的 serverid 必须不同
port = 3306
log_bin_trust_function_creators = 1
sql_mode = NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
#read_only = 1 # SLAVE 机器开启这个选项
# GENERAL #
user = mysql
default-storage-engine = InnoDB
socket = /data/ane56/mysqld.sock
pid-file = /data/ane56/mysql.pid
# LOGGING #
log_output=TABLE
datadir = /data/ane56
#general_log_file = /data/ane56/mysql_general.log
log_error = /data/ane56/mysql_error.log
#log_queries_not_using_indexes = 1
slow_query_log = 1
long_query_time = 1
#slave_skip_errors = all
# MyISAM #
key_buffer_size = 32M
join_buffer_size = 1M
sort_buffer_size = 2M
read_rnd_buffer_size = 1M
# SAFETY #
max_allowed_packet = 16M
max_connect_errors = 1000000
wait_timeout = 600
interactive_timeout = 600
lower_case_table_names = 1
# BINARY LOGGING #
log_bin = /data/mysqlbinlog/mysql_bin
relay_log = /data/mysqlbinlog/mysql-relay-bin
expire_logs_days = 7
sync_binlog = 500
log_slave_updates
binlog_format = ROW
#binlog_ignore_db = mysql,information_schema
# CACHES AND LIMITS #
tmp_table_size = 32M
max_heap_table_size = 32M
query_cache_type = 0
query_cache_size = 0
max_connections = 5000
open_files_limit = 65535
table_definition_cache = 4096
table_open_cache = 3000
# INNODB #
innodb_flush_method = O_DIRECT
innodb_log_files_in_group = 3
innodb_log_file_size = 1G
innodb_log_buffer_size = 128M # 如果 Innodb_log_waits 不为 0 可以适当增加
innodb_file_per_table = 1
innodb_flush_log_at_trx_commit = 1 # 1 安全级别最高，性能最低（ SSD 除外）， 0 性能最高，安全最低（不建议）， 2 保证了性能和安全
innodb_buffer_pool_size = 90G # 设置当前内存的 60%-65%
innodb_read_io_threads = 4 # 加大可增加读性能
innodb_write_io_threads = 4 # 加大可增加写性能
innodb_io_capacity = 200 # 根据磁盘 iops 调整， SSD 可调高
innodb_buffer_pool_instances = 8
# CHARACTER #
character_set_server = utf8
collation_server = utf8_general_ci
explicit_defaults_for_timestamp = true
EOF

## startup mysql service
$INIT/mysql start

## delete mysql user and database
$MYSQL -e "delete from mysql.user where user <> 'root' or host <> 'localhost';"
$MYSQL -e "drop database test;"

## change engine for the table slow_log 
sed -i '/low_query_log/s/^/#/' $CONF/my.cnf
$INIT/mysql stop
$INIT/mysql start
$MYSQL -e "drop table mysql.slow_log;"
$MYSQL -e "CREATE TABLE mysql.slow_log (start_time timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,user_host mediumtext NOT NULL,query_time time NOT NULL,lock_time time NOT NULL,rows_sent int(11) NOT NULL,rows_examined int(11) NOT NULL,db varchar(512) NOT NULL,last_insert_id int(11) NOT NULL,insert_id int(11) NOT NULL,server_id int(10) unsigned NOT NULL,sql_text mediumtext NOT NULL,thread_id bigint(21) unsigned NOT NULL,KEY start_time (start_time),KEY query_time (query_time)) ENGINE=MyISAM;"
sed -i '/low_query_log/s/^#//' $CONF/my.cnf
$INIT/mysql stop
$INIT/mysql start

rm -rf $ROOT/percona-*

## install xtrabackup
## download if not exists
cd $ROOT
if [ ! -f $LIB ]; then
        $WGET ftp://ftp.pbone.net/mirror/ftp5.gwdg.de/pub/opensuse/repositories/home:/rudi_m/RedHat_RHEL-6/x86_64/libev4-4.15-7.1.x86_64.rpm
fi

## download if not exists
if [ ! -f $BACKFILE ]; then
        $WGET https://www.percona.com/downloads/XtraBackup/Percona-XtraBackup-2.4.7/binary/redhat/6/x86_64/percona-xtrabackup-24-2.4.7-1.el6.x86_64.rpm
fi

cd $ROOT 
rpm -ivh $LIB
$YUM install -y $BACKFILE
rm -rf *.rpm

echo 'The mysql server was install completed.'




