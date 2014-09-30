#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########Variables##########
#backup location
backup_L='/tmp/mysqlbkp/'
#mongo location
mysql_L='/dbfiles/'
#mysql server
mysql_server='localhost'
#mysql port used
port=3306
#mysql db_name
mysql_db_name='che001'
#username and password
admin_user='root'
passwd='6NxRy8D6'
#backup formatted date
backup_date=$(date +%y%m%d_%H_%M)
#location for the application output
log_output=$backup_L"log."$backup_date
#backup_file name
backup_file_name="mysql_rs0_bkp_"$backup_date".tar.gz"
#backup file
backup_file=$backup_L$backup_file_name
#backup container in swift
BACKUP_CONTAINER='mysql_backups'
#save pwd
PWD=`pwd`

#OpenStack config
export OS_TENANT_NAME=kycloudstaging
export OS_USERNAME=kycloud
export OS_PASSWORD=kycloud2014
export OS_AUTH_URL="http://203.130.40.98:5000/v2.0/"

function logToFile(){
	if [ ! -d "$backup_L" ]; then
		mkdir -p $backup_L
	fi
	echo $1 >> $log_output
}

##########Functions##########
# function stop_slave 
function stop_slave {
	service mysqld stop
}

# function create_mysql_backup verify if the backup location exists if not create the location
# and after that create a backup
function create_mysql_backup {
if [ ! -d "$backup_L" ]; then
    mkdir -p $backup_L
fi
tar -zcvPf $backup_file $mysql_L
chown -R mysql:mysql $backup_L
}

# function to copy backup archive to swift and clean local file
function copyFileToSwift(){
cd $backup_L
swift upload $BACKUP_CONTAINER $backup_file_name
cd $PWD
rm -f $backup_file
}

# function start_slave operations back to normal
function start_slave {
	service mysqld start
}

# function run_backup check first if the mysql application is started if not write a error message
# in the output file, if the application is started run the above functions to make the backup
function run_backup {
echo "Backup started: `date`"
echo " "
	if [ -z "$passwd" ]; then
		mysql --host $mysql_server -u $admin_user $mysql_db_name -N -s -e "select timestamp(now())"
	else
		mysql --host $mysql_server -u $admin_user -p$passwd $mysql_db_name -N -s -e "select timestamp(now())"
	fi
RESULT=$?   # returns 0 if mysql command succeeds

if [ $RESULT -ne 0 ]; then
    echo "Error mysql is not running, `date`"
    exit 1
else
    #stop the mysql application
    stop_slave
    #make the backup
    create_mysql_backup
	#copy file to swift
	copyFileToSwift
    #start the application
    start_slave
fi

echo " "
echo "Backup ended: `date`"
} >> $log_output


##############################
# run the function run_backup
run_backup
