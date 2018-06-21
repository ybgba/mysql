#!/bin/bash

numactl --interleave=all  /mnt/mysql5720/bin/mysqld_safe --defaults-file=/mnt/mysql5720/etc/my_3306.cnf &


