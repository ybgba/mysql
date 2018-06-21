
#!/bin/bash
ADDR="172.17.1.9 172.17.1.16 172.17.18.14 172.17.18.15 172.17.17.11 172.17.18.10"
KDGIS="172.17.18.13"
PORT="3306 3307 3308 3309"
USER=dba
PASSWORD=qwe123

# url为告警api地址，不可修改
to_user="yangbiao,lijialin,lianghongxiang,wanglei,taohaobo,wanglinyao"
base_url="https://alert.ane56.com/sendText"
url="${base_url}?to_user=${to_user}"




for i in $ADDR
        do
        RESULTS=`mysql -h$i -u$USER -p$PASSWORD -e "show slave status \G;" 2>&1 | grep -Ew 'Slave_IO_Running|Slave_SQL_Running' | awk -F ':' '{print $2}'`;
        if [[ $RESULTS =~ 'No' ]]
                then
                content_conn=`echo $i 'replication is failed, please check it!'`;
                curl "${url}" -d "&content=${content_conn}"
        fi
done

for j in $PORT
        do
        KDGIS_RESULTS=`mysql -h$KDGIS -u$USER -p$PASSWORD -P$j -e "show slave status \G;" 2>&1 | grep -Ew 'Slave_IO_Running|Slave_SQL_Running' | awk -F ':' '{print $2}'`;
        if [[ $KDGIS_RESULTS =~ 'No' ]]
                then
                content_conn=`echo $KDGIS 'instance' $j 'replication is failed, please check it!'`;
                curl "${url}" -d "&content=${content_conn}"
        fi
done