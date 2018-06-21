-- manager
ndb_mgmd -f /mnt/mysqlndb757/etc/config.ini --reload
ndb_mgmd -f /mnt/mysqlndb757/etc/config.ini --initial

-- data
ndbd

-- api
/mnt/mysqlndb757/init.d/mysql start
