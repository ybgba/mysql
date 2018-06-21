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
LASTDUMP='/backup/lastdump'

## USER AND PASSWORD AND CONFIG
uSER='root'
PASSWORD='Ane#56!kdbill'
CONFIG='/mnt/mysql5635/etc/my.cnf'
DUMPDB='BILL'

## THE PARAMETER OF INNOBACKUPEX
PARAMETER='--no-timestamp --slave-info --safe-slave-backup'

if [ ! -d $FULLDIR ]; then
	mkdir -p $FULLDIR
fi

if [ ! -d $FILEDIR ]; then
        mkdir -p $FILEDIR
fi

if [ ! -d $INCREDIR ]; then
        mkdir -p $INCREDIR
fi

if [ ! -d $LOGDIR ]; then
        mkdir -p $LOGDIR
fi

if [ ! -d $LASTDUMP ]; then
        mkdir -p $LASTDUMP
fi

## THE DIR whether is empty 
FULLNULL=`ls -A $FULLDIR | wc -l`
INCREMENTNULL=`ls -A $INCREDIR | wc -l`

if [ $FULLNULL -gt 0 -o $INCREMENTNULL -gt 0 ]; then
	echo '------------------------------------------------------------------------------' >> $LOGDIR/full_$FULL_DATE 2>&1
	echo 'Compress And Dump' >> $LOGDIR/full_$FULL_DATE 2>&1
	echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/full_$FULL_DATE 2>&1
	mv $FULLDIR/* $LASTDUMP && mv $INCREDIR/* $LASTDUMP && \
        $BACKUP --defaults-file=$CONFIG --user=$USER --password=$PASSWORD $PARAMETER $FULLDIR/$FULL_DATE >> $LOGDIR/full_$FULL_DATE 2>&1 && \
	$TAR zcvf $FILEDIR/$DUMPDB-$FULL_DATE.tar.gz $LASTDUMP && \
	rm -rf $LASTDUMP/*
        echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/full_$FULL_DATE 2>&1
        echo '------------------------------------------------------------------------------' >> $LOGDIR/full_$FULL_DATE 2>&1
else
        echo '------------------------------------------------------------------------------' >> $LOGDIR/full_$FULL_DATE 2>&1
        echo 'Dump' >> $LOGDIR/full_$FULL_DATE 2>&1
        echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/full_$FULL_DATE 2>&1
        $BACKUP --defaults-file=$CONFIG --user=$USER --password=$PASSWORD $PARAMETER $FULLDIR/$FULL_DATE >> $LOGDIR/full_$FULL_DATE 2>&1   
        echo `date +%Y-%m-%d_%H-%M-%S` >> $LOGDIR/full_$FULL_DATE 2>&1
        echo '------------------------------------------------------------------------------' >> $LOGDIR/full_$FULL_DATE 2>&1
fi



