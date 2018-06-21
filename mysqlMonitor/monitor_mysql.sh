#!/bin/bash

HOST_IP=`ifconfig bond0 | awk "NR==2" | awk '{print $2}' | cut -d : -f 2`
HOSTNAME=`hostname`
PASSWD='ane56!pda'

## WECHAT  ##
base_url="http://alert.ane56.com/sendText"
to_user="yangbiao,lihui,lijialin,wanglinyao,lianghongxiaong"
url="${base_url}?to_user=${to_user}"

## SLAVE STATUS ##
#mysql -e 'show slave status \G;' | grep 'Slave_IO_Running\|Slave_SQL_Running\|Seconds_Behind_Master' > /tmp/slave_status.txt

#BEHIND_MASTER=`cat /tmp/slave_status.txt | awk "NR==3" | awk '{print $2}'`
#if [ $BEHIND_MASTER -gt 0 ]  
#	then
#	echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The slave behind value is '$BEHIND_MASTER', please check it.'
#fi

#SQL_RUNNING=`cat /tmp/slave_status.txt | awk "NR==2" | awk '{print $2}'`    
#if [ $SQL_RUNNING != 'Yes' ]
#    then
#    echo '['$HOST_IP']''The slave sql running  is '$SQL_RUNNING', please check it.'
#fi


#IO_RUNNING=`cat /tmp/slave_status.txt | awk "NR==1" | awk '{print $2}'`
#if [ $IO_RUNNING != 'Yes' ]
#    then
#    echo '['$HOST_IP']''The slave IO running  is '$IO_RUNNING', please check it.'
#fi

## ACTIVE CONNECTIONS AND TOTAL CONNECTIONS  ##
mysql -e 'show full processlist;' | grep -v Sleep | sort -k6rn | wc -l > /tmp/processlist.txt
mysql -e 'show full processlist;' | wc -l >> /tmp/processlist.txt
ACTIVE_CONN=`cat /tmp/processlist.txt | awk "NR==1"`
TOTAL_CONN=`cat /tmp/processlist.txt | awk "NR==2"`
if [ $TOTAL_CONN -gt 400 ]
	then
	content_conn=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The total connections of mysql is '$TOTAL_CONN', please check it.'`
	curl "${url}" -d "&content=${content_conn}"	
fi

## CHECK MYSQL RUNNING STATUS ##
PORT=`netstat -anp | grep 3306 | wc -l`
STATE=`mysqladmin ping | awk '{print $3}'`
if [ $STATE != 'alive' -o $PORT -eq 0 ]
	then
	content_state=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The mysql is '$STATE', please check it.'`
        curl "${url}" -d "&content=${content_state}"       
fi

## CHECK THE MEMORY USED ##
MEM_USED=`free -m | awk "NR==2" | awk '{print $3}'`
MEM_IDLE=`free -m | awk "NR==2" | awk '{print $4}'`
MEM_USAGE_PERCENT=`free | awk "NR==2" | awk '{printf "%.2f\n",($2-$4-$6-$7)/$2*100}'`
if [[ $MEM_USAGE_PERCENT > 75 ]]
	then
	content_mem=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The memory usage percent is '$MEM_USAGE_PERCENT'%, please check it.'`
        curl "${url}" -d "&content=${content_mem}"      
fi

## CPU 1m,5m,15m ##
CPU_NUM=`cat /proc/cpuinfo |grep "physical id"|sort |uniq|wc -l`
LOAD1=`uptime | awk -F ',' '{print $4}' | awk -F ':' '{print $2}'`
LOAD5=`uptime | awk -F ',' '{print $5}'`
LOAD15=`uptime | awk -F ',' '{print $6}'`
L_1=`echo $LOAD1 $CPU_NUM | awk "{print $LOAD1/$CPU_NUM}"`
L_5=`echo $LOAD5 $CPU_NUM | awk "{print $LOAD5/$CPU_NUM}"`
L_15=`echo $LOAD15 $CPU_NUM | awk "{print $LOAD15/$CPU_NUM}"`
L1=`echo $L_1 | awk "{print $L_1*100}" | awk -F '.' '{print $1}'`
L5=`echo $L_5 | awk "{print $L_5*100}" | awk -F '.' '{print $1}'`
L15=`echo $L_15 | awk "{print $L_15*100}" | awk -F '.' '{print $1}'`
if [ $L1 -gt 300 -o $L5 -gt 300 -o $L15 -gt 300 ]
    	then
    	content_cpu=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The cpu load is '$L_1','$L_5','$L_15', please check it.'`
        curl "${url}" -d "&content=${content_cpu}"
fi

## MYSQL STATUS ##
#mysql -poffice123.. -e 'show global status like "Com_insert";' | awk "NR==2" | awk '{print $2}'
#mysql -poffice123.. -e 'show global status like "Com_update";' | awk "NR==2" | awk '{print $2}'
#mysql -poffice123.. -e 'show global status like "Com_delete";' | awk "NR==2" | awk '{print $2}'
#mysql -poffice123.. -e 'show global status like "Com_select";' | awk "NR==2" | awk '{print $2}'

## MYSQL TMP ##
mysql -e 'show global status;' | grep 'Created_tmp_disk_tables\|Created_tmp_tables' > /tmp/tmp_table.txt
TMP_DISK=`cat /tmp/tmp_table.txt | awk "NR==1" | awk '{print $2}'`
TMP=`cat /tmp/tmp_table.txt | awk "NR==2" | awk '{print $2}'`
TMP_TABLE_RATE=`echo $[($TMP_DISK/$TMP)*100]`
if [ $TMP_TABLE_RATE -gt 25 ]
	then
	content_table_rate=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The tmp table rate of mysql is '$TMP_TABLE_RATE'%, please check it.'`
        curl "${url}" -d "&content=${content_table_rate}"
fi

## MYSQL CONNECTIONS ##
mysql -e "show global status;" | grep 'Threads_created\|Connections' > /tmp/connections.txt
CONNECTIONS=`cat /tmp/connections.txt | awk "NR==1" | awk '{print $2}'`
THREADS_CREATED=`cat /tmp/connections.txt | awk "NR==2" | awk '{print $2}'`
CONN_RATE=`echo $THREADS_CREATED $CONNECTIONS | awk "{print ($THREADS_CREATED/$CONNECTIONS)*100}"`

## TABLE SCAN rate ##
mysql -e 'show global status;' | grep 'Handler_read_rnd_next\|Com_select' > /tmp/table_scan.txt
Handler_read_rnd_next=`cat /tmp/table_scan.txt | awk "NR==2" | awk '{print $2}'`
Com_select=`cat /tmp/table_scan.txt | awk "NR==1" | awk '{print $2}'`
TABLE_SCAN=`echo $[$Handler_read_rnd_next/$Com_select]`
if [ $TABLE_SCAN -gt 3500 ]
	then 
	content_scan=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The table scan is '$TABLE_SCAN', please check the some SQL.'`
        curl "${url}" -d "&content=${content_scan}"
fi

## INNODB BUFFER READ HITS ##
mysql -e "show global status;" | grep 'Innodb_buffer_pool_read_requests\|Innodb_buffer_pool_reads\|Innodb_buffer_pool_read_ahead' > /tmp/INNODB_READ_HITS.txt
Innodb_buffer_pool_read_requests=`cat /tmp/INNODB_READ_HITS.txt | awk "NR==4" | awk '{print $2}'`
Innodb_buffer_pool_reads=`cat /tmp/INNODB_READ_HITS.txt | awk "NR==5" | awk '{print $2}'`
Innodb_buffer_pool_read_ahead=`cat /tmp/INNODB_READ_HITS.txt | awk "NR==2" | awk '{print $2}'`
INNODB_BUFFER_READ_HITS=`echo $Innodb_buffer_pool_read_requests $Innodb_buffer_pool_reads $Innodb_buffer_pool_read_ahead | awk "{print ($Innodb_buffer_pool_read_requests-$Innodb_buffer_pool_reads-$Innodb_buffer_pool_read_ahead)/$Innodb_buffer_pool_read_requests*100}" | awk -F '.' '{print $1}'`
if [ $INNODB_BUFFER_READ_HITS -lt 95 ] 
	then
	content_read=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The Innodb buffer read hits is '$INNODB_BUFFER_READ_HITS'%, please check it.'`
        curl "${url}" -d "&content=${content_read}"
fi

## INNODB PAGE USAGE ##
mysql -e "show global status;" | grep 'Innodb_buffer_pool_pages_data\|Innodb_buffer_pool_pages_free\|Innodb_buffer_pool_pages_total' > /tmp/innodb_page.txt
PAGE_DATA=`cat /tmp/innodb_page.txt | awk "NR==1" | awk '{print $2}'`
PAGE_FREE=`cat /tmp/innodb_page.txt | awk "NR==2" | awk '{print $2}'`
PAGE_TOTAL=`cat /tmp/innodb_page.txt | awk "NR==3" | awk '{print $2}'`
PAGE_USAGE_RATE=`echo $PAGE_DATA $PAGE_TOTAL | awk "{print $PAGE_DATA/$PAGE_TOTAL*100}" | awk -F '.' '{print $1}'`
if [ $PAGE_USAGE_RATE -gt 90 ]
	then
    	content_page=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The Innodb page usage is '$PAGE_USAGE_RATE'%, please increase innodb buffer size.'`
        curl "${url}" -d "&content=${content_page}"
fi

## INNODB LOG ##
mysql -e "show global status;" | grep 'Innodb_log_waits' > /tmp/innodb_log.txt
LOG_WAITS=`cat /tmp/innodb_log.txt | awk "NR==1" | awk '{print $2}'`
if [ $LOG_WAITS -gt 0 ]
	then
    	content_wait=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The Innodb log waits is '$LOG_WAITS', please check log buffer size.'`
        curl "${url}" -d "&content=${content_wait}"
fi

## OPEN FILE ##
mysql -e "show variables;" | grep 'open_files_limit' > /tmp/open_file.txt
mysql -e "show global status;" | grep 'Open_files' >> /tmp/open_file.txt
mysql -e "show global status;" | grep 'Open_tables' >> /tmp/open_file.txt
open_files_limit=`cat /tmp/open_file.txt | awk "NR==1" | awk '{print $2}'`
Open_files=`cat /tmp/open_file.txt | awk "NR==2" | awk '{print $2}'`
Open_tables=`cat /tmp/open_file.txt | awk "NR==3" | awk '{print $2}'`
OPEN_LIMIT=`echo $open_files_limit | awk "{print $open_files_limit*0.7}" | awk -F '.' '{print $1}'`
if [ $Open_files -gt $OPEN_LIMIT ]
	then
    	content_file=`echo '[ '$HOST_IP'-'$HOSTNAME' ]'' The open files is '$Open_files', please check it.'`
        curl "${url}" -d "&content=${content_file}"
fi


















