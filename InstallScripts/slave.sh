IPADDR=`ifconfig eth0 | awk '/inet addr:/ {print $2}'| awk -F '.' '{print $4}'`

GROUPADD='/usr/sbin/groupadd'
USERADD='/usr/sbin/useradd'
ROOT='/rootuser'
FTPUSER='ftpuser'
FTPPASSWORD='ftpuser'
FTPADDR='172.0.0.1'
FTPDIR='Component-warehouse'

MYSQLGROUP='mysql'
MYSQLUSER='mysql'
BASEDIR='/mnt/mysql5729'
DATA='/data/bmdata'
BINLOG='/data/binlog'
CONF='etc'
INIT='init.d'
SOCKET='/data/bmdata/mysqld.sock'
PORT=`ps -ef | grep mysqld | grep 'port=' | awk -F 'port=' '{print $2}' | sort -rn | head -1`
SRCCONFILE='my.cnf'

MYSQL='/usr/bin/mysql'
PACKAGE='mysql-5.7.29-linux-glibc2.12-x86_64.tar.gz'
SOURCEFOLDER='mysql-5.7.29-linux-glibc2.12-x86_64'
LIB='libev4-4.15-7.1.x86_64.rpm'
BACKFILE='percona-xtrabackup-24-2.4.10-1.el6.x86_64.rpm'

MAXUSERPROCESSES=`ulimit -u`
OPENFILES=`ulimit -n`
LIMITFILE='/etc/security/limits.conf'

SWAPPINESS=`cat /proc/sys/vm/swappiness`
DIRTYRATIO=`cat /proc/sys/vm/dirty_ratio`
DIRTYBACKGROUNDRATIO=`cat /proc/sys/vm/dirty_background_ratio`
SYSCTL='/etc/sysctl.conf'

## MODIFY KERNEL ##
if [[ $SWAPPINESS -ne 5 ]]; then
	echo 'vm.swappiness = 5' >> $SYSCTL
fi

if [[ $DIRTYRATIO -ne 5 ]]; then
	echo 'vm.dirty_ratio = 5' >> $SYSCTL
fi

if [[ $DIRTYBACKGROUNDRATIO -ne 10 ]]; then
	echo 'vm.dirty_background_ratio = 10' >> $SYSCTL
fi

sysctl -p

## MODIFY LIMIT ##
if [[ $OPENFILES -lt 65535 ]]; then
	echo '*                soft    nofile         65535' >> $LIMITFILE
	echo '*                hard    nofile         65535' >> $LIMITFILE
fi

if [[ $MAXUSERPROCESSES -lt 65535 ]]; then
	echo '*                soft    nproc          65535' >> $LIMITFILE
	echo '*                hard    nproc          65535' >> $LIMITFILE
fi

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

## JUDGE mysql service
if [[ ! -n "$PORT" || $PORT = "" ]]; then
	PORT='13306';
else
        PORT=$(($PORT + 1));
fi

## create basedir if not exists
if [ ! -d "$BASEDIR" ]; then
	echo 'THE DIRECTORY '$BASEDIR' NOT EXISTS AND WILL CREATE IT.'
	mkdir -p $BASEDIR
else
	echo 'THE DIRECTORY '$BASEDIR' HAS BEEN EXISTS.'
fi

if [ ! -d "$BASEDIR"/"$CONF" ]; then
        mkdir $BASEDIR/$CONF
fi
if [ ! -d "$BASEDIR"/"$INIT" ]; then
        mkdir $BASEDIR/$INIT
fi

## create datadir if not exists
DATADIR="$DATA"_"$PORT"
if [ ! -d "$DATADIR" ]; then
	echo 'THE DIRECTORY '$DATADIR' NOT EXISTS AND WILL CREATE IT.'
	mkdir -p $DATADIR
   else
	echo 'THE DIRECTORY '$DATADIR' HAS BEEN EXISTS.'
fi

## create mysqlbinlog if not exists
BINLOGDIR="$BINLOG"_"$PORT"
if [ ! -d "$BINLOGDIR" ]; then
	echo 'THE DIRECTORY '$BINLOGDIR' NOT EXISTS AND WILL CREATE IT.'
	mkdir -p $BINLOGDIR
else
	echo 'THE DIRECTORY '$BINLOGDIR' HAS BEEN EXISTS.'
fi

## CREATE MY.CONF file  ##
CONFFILE="my$PORT.cnf"
if [ ! -f "$CONFFILE" ]; then
	touch $BASEDIR/$CONF/$CONFFILE
fi

## DEPS PACKAGE  ##
RPMCOUNT=`rpm -qa gcc* | wc -l`
if [[ $RPMCOUNT -eq 0 ]]; then
	yum -y install make gcc-c++ cmake bison-devel  ncurses-devel gcc autoconf automake zlib* fiex* libxml* libmcrypt* libtool-ltdl-devel* perl libaio-devel readline-devel openssl* screen lrzsz lsof 
fi

## DOWNLOAD MYSQL-5.7 INSTALL PACKAGE  ##
FILECOUNT=`ls $BASEDIR | wc -l`
if [ ! -f $PACKAGE ]; then
	if [[ $FILECOUNT -lt 3 ]]; then
		wget ftp://$FTPUSER:$FTPPASSWORD@$FTPADDR/$FTPDIR/$PACKAGE
		tar zxvf $PACKAGE 
		mv $SOURCEFOLDER/* $BASEDIR 
		rm -rf $PACKAGE $SOURCEFOLDER
	fi
fi

## MODIFY MY.CNF file  ##
if [ ! -f $SRCCONFILE ]; then
        wget ftp://$FTPUSER:$FTPPASSWORD@$FTPADDR/$FTPDIR/$SRCCONFILE
        cat $SRCCONFILE > $BASEDIR/$CONF/$CONFFILE
	rm -rf $SRCCONFILE
fi

## MODIFY conf file ##
## INSTANCE NUMBER IS THE INSTANCE OF MYSQL AT THE SERVER ##
## IF YOU NEED INSTALL MULTI INSTANCE OF MYSQL THEN MODIFY THE NUMBER ##
INSTANCE=1
PERCPUCORE=`cat /proc/cpuinfo| grep "cpu cores"| uniq | awk -F ':' '{print $2}'`
PHYCPU=`cat /proc/cpuinfo| grep "physical id"| sort| uniq| wc -l`
LOGCPU=`cat /proc/cpuinfo| grep "processor"| wc -l`
TOTALMEM=$((`cat /proc/meminfo | grep MemTotal | awk -F ' ' '{print $2}'`*1024))
USEMEM=$((($TOTALMEM/3+$TOTALMEM/3)/$INSTANCE))
IPADDR=`ifconfig eth0 | awk '/inet / {print $2}'| awk -F '.' '{print $4}'`

CONFSOCKET=`echo $DATADIR/mysql.sock | sed 's#\/#\\\/#g'`
PIDFILE=`echo $DATADIR/mysql.pid | sed 's#\/#\\\/#g'`
SERVERID=$IPADDR$PORT
CONFDATADIR=`echo $DATADIR | sed 's#\/#\\\/#g'`
LOGERROR=`echo $DATADIR/mysql_error.log | sed 's#\/#\\\/#g'`
LOGBIN=`echo $BINLOGDIR/mysql-bin | sed 's#\/#\\\/#g'`
RELAYLOG=`echo $BINLOGDIR/mysql-relay-bin | sed 's#\/#\\\/#g'`

sed -i "s/port.* /&$PORT/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/socket.* /&$CONFSOCKET/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/pid-file.* /&$PIDFILE/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/server_id.* /&$SERVERID/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/datadir.* /&$CONFDATADIR/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/log_error.* /&$LOGERROR/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/innodb_buffer_pool_size.* /&$USEMEM/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/log_bin = /&$LOGBIN/g" $BASEDIR/$CONF/$CONFFILE
sed -i "s/relay_log = /&$RELAYLOG/g" $BASEDIR/$CONF/$CONFFILE

if [[ "$TOTALMEM" -lt 4000000000 ]];then
        JOINBUFFERSIZE=$((524288/$INSTANCE))
        SORTBUFFERSIZE=$((524288/$INSTANCE))
        READRUNBUFFERSIZE=$((524288/$INSTANCE))
        READBUFFERSIZE=$((524288/$INSTANCE))
        MAXALLOWEDPACKET=$((16777216/$INSTANCE))
        TMPTABLESIZE=$((16777216/$INSTANCE))
        MAXHEAPTABLESIZE=$((1048576/$INSTANCE))
        INNODBLOGFILESIZE=$((1073741824/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((8388608/$INSTANCE))
        INNODBREADIOTHREADS=$((2/$INSTANCE))
        INNODBWRITEIOTHREADS=$((2/$INSTANCE))
        INNODBIOCAPACITY=$((200/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=$((8/$INSTANCE))
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.* /&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.* /&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE
elif [ "$TOTALMEM" -lt 8000000000  -a  "$TOTALMEM" -gt 4000000000 ]; then
        JOINBUFFERSIZE=$((2097152/$INSTANCE))
        SORTBUFFERSIZE=$((1048576/$INSTANCE))
        READRUNBUFFERSIZE=$((1048576/$INSTANCE))
        READBUFFERSIZE=$((1048576/$INSTANCE))
        MAXALLOWEDPACKET=$((33554432/$INSTANCE))
        TMPTABLESIZE=$((16777216/$INSTANCE))
        MAXHEAPTABLESIZE=$((2097152/$INSTANCE))
        INNODBLOGFILESIZE=$((1073741824/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((8388608/$INSTANCE))
        INNODBREADIOTHREADS=$((4/$INSTANCE))
        INNODBWRITEIOTHREADS=$((4/$INSTANCE))
        INNODBIOCAPACITY=$((400/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=$((8/$INSTANCE))
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.* /&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.* /&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE        
elif [ "$TOTALMEM" -lt 16000000000  -a  "$TOTALMEM" -gt 8000000000 ]; then
        JOINBUFFERSIZE=$((2097152/$INSTANCE))
        SORTBUFFERSIZE=$((1048576/$INSTANCE))
        READRUNBUFFERSIZE=$((1048576/$INSTANCE))
        READBUFFERSIZE=$((1048576/$INSTANCE))
        MAXALLOWEDPACKET=$((33554432/$INSTANCE))
        TMPTABLESIZE=$((16777216/$INSTANCE))
        MAXHEAPTABLESIZE=$((2097152/$INSTANCE))
        INNODBLOGFILESIZE=$((1073741824/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((8388608/$INSTANCE))
        INNODBREADIOTHREADS=$((4/$INSTANCE))
        INNODBWRITEIOTHREADS=$((4/$INSTANCE))
        INNODBIOCAPACITY=$((500/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=$((8/$INSTANCE))
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.* /&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.* /&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE
elif [ "$TOTALMEM" -lt 32000000000  -a  "$TOTALMEM" -gt 16000000000 ]; then
        JOINBUFFERSIZE=$((2097152/$INSTANCE))
        SORTBUFFERSIZE=$((2097152/$INSTANCE))
        READRUNBUFFERSIZE=$((2097152/$INSTANCE))
        READBUFFERSIZE=$((2097152/$INSTANCE))
        MAXALLOWEDPACKET=$((33554432/$INSTANCE))
        TMPTABLESIZE=$((16777216/$INSTANCE))
        MAXHEAPTABLESIZE=$((4194304/$INSTANCE))
        INNODBLOGFILESIZE=$((2147483648/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((8388608/$INSTANCE))
        INNODBREADIOTHREADS=$((4/$INSTANCE))
        INNODBWRITEIOTHREADS=$((4/$INSTANCE))
        INNODBIOCAPACITY=$((500/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=$((8/$INSTANCE))
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.* /&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.* /&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE
elif [ "$TOTALMEM" -lt 64000000000  -a  "$TOTALMEM" -lt 32000000000 ]; then
        JOINBUFFERSIZE=$((4194304/$INSTANCE))
        SORTBUFFERSIZE=$((2097152/$INSTANCE))
        READRUNBUFFERSIZE=$((2097152/$INSTANCE))
        READBUFFERSIZE=$((2097152/$INSTANCE))
        MAXALLOWEDPACKET=$((42991616/$INSTANCE))
        TMPTABLESIZE=$((16777216/$INSTANCE))
        MAXHEAPTABLESIZE=$((4194304/$INSTANCE))
        INNODBLOGFILESIZE=$((4294967296/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((8388608/$INSTANCE))
        INNODBREADIOTHREADS=$((4/$INSTANCE))
        INNODBWRITEIOTHREADS=$((4/$INSTANCE))
        INNODBIOCAPACITY=$((500/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=$((8/$INSTANCE))
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.* /&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.* /&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE
elif [ "$TOTALMEM" -lt 128000000000  -a  "$TOTALMEM" -gt 64000000000 ]; then
        JOINBUFFERSIZE=$((4194304/$INSTANCE))
        SORTBUFFERSIZE=$((8388608/$INSTANCE))
        READRUNBUFFERSIZE=$((8388608/$INSTANCE))
        READBUFFERSIZE=$((8388608/$INSTANCE))
        MAXALLOWEDPACKET=$((42991616/$INSTANCE))
        TMPTABLESIZE=$((16777216/$INSTANCE))
        MAXHEAPTABLESIZE=$((8388608/$INSTANCE))
        INNODBLOGFILESIZE=$((4294967296/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((8388608/$INSTANCE))
        INNODBREADIOTHREADS=$((4/$INSTANCE))
        INNODBWRITEIOTHREADS=$((4/$INSTANCE))
        INNODBIOCAPACITY=$((2000/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=$((8/$INSTANCE))
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.* /&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.* /&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE
elif [ "$TOTALMEM" -lt 512000000000  -a  "$TOTALMEM" -gt 128000000000 ]; then
        JOINBUFFERSIZE=$((8388608/$INSTANCE))
        SORTBUFFERSIZE=$((16777216/$INSTANCE))
        READRUNBUFFERSIZE=$((16777216/$INSTANCE))
        READBUFFERSIZE=$((16777216/$INSTANCE))
        MAXALLOWEDPACKET=$((85983232/$INSTANCE))
        TMPTABLESIZE=$((33554432/$INSTANCE))
        MAXHEAPTABLESIZE=$((16777216/$INSTANCE))
        INNODBLOGFILESIZE=$((8589934592/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((16777216/$INSTANCE))
        INNODBREADIOTHREADS=$((4/$INSTANCE))
        INNODBWRITEIOTHREADS=$((4/$INSTANCE))
        INNODBIOCAPACITY=$((2000/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=$((8/$INSTANCE))
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.*/&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.*/&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE
elif [ "$TOTALMEM" -gt 512000000000 ]; then
        JOINBUFFERSIZE=$((16777216/$INSTANCE))
        SORTBUFFERSIZE=$((33554432/$INSTANCE))
        READRUNBUFFERSIZE=$((33554432/$INSTANCE))
        READBUFFERSIZE=$((33554432/$INSTANCE))
        MAXALLOWEDPACKET=$((171966464/$INSTANCE))
        TMPTABLESIZE=$((67108864/$INSTANCE))
        MAXHEAPTABLESIZE=$((33554432/$INSTANCE))
        INNODBLOGFILESIZE=$((17179869184/$INSTANCE))
        INNODBLOGBUFFERSIZE=$((33554432/$INSTANCE))
        INNODBREADIOTHREADS=$((8/$INSTANCE))
        INNODBWRITEIOTHREADS=$((8/$INSTANCE))
        INNODBIOCAPACITY=$((4000/$INSTANCE))
        INNODBBUFFERPOOLINSTANCES=12
        sed -i "s/join_buffer_size.* /&$JOINBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/sort_buffer_size.* /&$SORTBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_rnd_buffer_size.* /&$READRUNBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/read_buffer_size.* /&$READBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_allowed_packet.* /&$MAXALLOWEDPACKET/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/tmp_table_size.* /&$TMPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/max_heap_table_size.* /&$MAXHEAPTABLESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_file_size.* /&$INNODBLOGFILESIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_log_buffer_size.* /&$INNODBLOGBUFFERSIZE/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_read_io_threads.* /&$INNODBREADIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_write_io_threads.* /&$INNODBWRITEIOTHREADS/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_io_capacity.* /&$INNODBIOCAPACITY/g" $BASEDIR/$CONF/$CONFFILE
        sed -i "s/innodb_buffer_pool_instances.* /&$INNODBBUFFERPOOLINSTANCES/g" $BASEDIR/$CONF/$CONFFILE
fi

cd $BASEDIR
chown $MYSQLUSER:$MYSQLGROUP -R .
chown $MYSQLUSER:$MYSQLGROUP -R $DATADIR
chown $MYSQLUSER:$MYSQLGROUP -R $BINLOGDIR
chmod 777 -R $DATADIR

## CREATE THE SCRIPTS FOR STARTUP OF MYSQL##
STARTFILE="$BASEDIR/init.d/start$PORT.sh"
if [ ! -f $STARTFILE ]; then
	touch $STARTFILE
	echo "#!/bin/bash" > $STARTFILE
	echo "$BASEDIR/bin/mysqld_safe --defaults-file=$BASEDIR/$CONF/$CONFFILE &" >> $STARTFILE
fi

## STARTUP MYSQL INSTANCE ##
DATACOUNT=`ls $DATADIR | wc -l`
if [[ $DATACOUNT -lt 1 ]]; then
	bin/mysqld --defaults-file=$BASEDIR/$CONF/$CONFFILE --initialize --user=$MYSQLUSER --basedir=$BASEDIR --datadir=$DATADIR
#	bin/mysqld_safe --defaults-file=$BASEDIR/$CONF/$CONFFILE &
	sh $STARTFILE
	echo "The Database instance has been startup."
fi


sleep 5

## MODIFY DEFAULT PASSWORD ##
LOGFILE="$DATADIR/mysql_error.log"
DEFAULTPASSWORD=`grep 'A temporary password' "$LOGFILE" | awk -F"root@localhost: " '{ print $2}'`
DEFAULTPASSWORD1=$DEFAULTPASSWORD
MYSQL='/mnt/mysql5729/bin/mysql'
HOST='127.0.0.1'
USER='root'
PORTCURRENT=$PORT
CURRENTPASSWORD='qwe123'

$MYSQL --connect-expired-password -h$HOST -u$USER -p${DEFAULTPASSWORD} -P$PORTCURRENT <<EOF
	alter user root@localhost identified by "${CURRENTPASSWORD}";
	show databases;
EOF

## CREATE STOP SCRIPT ##
STOPFILE="$BASEDIR/init.d/stop$PORT.sh"
if [ ! -f $STOPFILE ]; then
        touch $STOPFILE
        echo "#!/bin/bash" > $STOPFILE
        echo "$BASEDIR/bin/mysqladmin -h$HOST -u$USER -p$CURRENTPASSWORD -P$PORT shutdown" >> $STOPFILE
fi

## setup slave ##
MASTER_IP='127.0.0.1'
MASTER_USER='root'
MASTER_PASSWORD='qwe123'
MASTER_PORT='13306'
REPL_USER='repl'
REPL_PASSWORD='qwe123'
MYSQLDUMP='/usr/bin/mysqldump'
DUMPFILE='master.sql'

$MYSQLDUMP -h$MASTER_IP -u$MASTER_USER -p$MASTER_PASSWORD -P$MASTER_PORT --set-gtid-purged=off --all-databases --master-data=2 --single-transaction -R --triggers --events > $DUMPFILE

$MYSQL -h$HOST -u$USER -p$CURRENTPASSWORD -P$PORTCURRENT < $DUMPFILE

$MYSQL -h$HOST -u$USER -p$CURRENTPASSWORD -P$PORTCURRENT <<EOF
	change master to master_host="${MASTER_IP}",master_user="${REPL_USER}",master_password="${REPL_PASSWORD}",master_port=${MASTER_PORT},master_auto_position=1;
	start slave;
EOF

$MYSQL -h$HOST -u$USER -p$CURRENTPASSWORD -P$PORTCURRENT -e 'show slave status \G;' | grep -w "Slave_IO_Running\|Slave_SQL_Running" | awk -F ':' '{print $2}'
