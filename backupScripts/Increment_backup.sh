#!/bin/bash

## SYSTEM BIN
TAR='/bin/tar'
BACKUP='/usr/bin/innobackupex'

## BACKUP TIMESTAMP FOR FULL and BACKUP 
FULL_DATE=`date +%Y-%m-%d`
INCRE_DATE=`date +%Y-%m-%d_%H-%M`

## THE DIR OF FULL AND INCREMENT AND MONDAY AND FIRST
FULLDIR='/backup/full'
INCREDIR='/backup/increment'
MONDAY='/backup/files/monday'
FIRST='/backup/files/firstday'
FILEDIR='/backup/file'
LOGDIR='/backup/logs'

## USER AND PASSWORD AND CONFIG
uSER='root'
PASSWORD='Ane#56!kdbill'
CONFIG='/mnt/mysql5635/etc/my.cnf'
DUMPDB='BILL'

## THE PARAMETER OF INNOBACKUPEX
PARAMETER='--no-timestamp --incremental --slave-info --safe-slave-backup'

if [ ! -d $FULLDIR ]; then
	mkdir -p $FULLDIR
fi

if [ ! -d $FILEDIR ]; then
        mkdir -p $FILEDIR
fi

if [ ! -d $INCREDIR ]; then
        mkdir -p $INCREDIR
fi

## THE DIR whether is empty 
FULLNULL=`ls -A $FULLDIR | wc -l`
INCREMENTNULL=`ls -A $INCREDIR | wc -l`
FULLDUMP=$FULLDIR/`ls $FULLDIR`
INCREMENTDUMP=$INCREDIR/`ls -t $INCREDIR | head -1`

if [ $INCREMENTNULL -eq 0 ]; then
        echo '------------------------------------------------------------------------------' >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo 'From Full Dump' >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/increment_$INCRE_DATE 2>&1
	$BACKUP --defaults-file=$CONFIG --user=$USER --password=$PASSWORD $PARAMETER --incremental-basedir=$FULLDUMP $INCREDIR/$INCRE_DATE >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo '------------------------------------------------------------------------------' >> $LOGDIR/increment_$INCRE_DATE 2>&1
else
        echo '------------------------------------------------------------------------------' >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo 'From Last Increment' >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/increment_$INCRE_DATE 2>&1
        $BACKUP --defaults-file=$CONFIG --user=$USER --password=$PASSWORD $PARAMETER --incremental-basedir=$INCREMENTDUMP $INCREDIR/$INCRE_DATE >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/increment_$INCRE_DATE 2>&1
        echo '------------------------------------------------------------------------------' >> $LOGDIR/increment_$INCRE_DATE 2>&1
fi




