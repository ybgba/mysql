#!/bin/bash

RESULTS=`echo 'show slave status \G;' | mysql -uroot -proot | grep -w Slave_SQL_Running | awk '{print $2}'`

if [ $RESULTS = 'No' ]; then
	mysql -uroot -proot -e 'stop slave;';
	mysql -uroot -proot -e 'start slave;'
fi
