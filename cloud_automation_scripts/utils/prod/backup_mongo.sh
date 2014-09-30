#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########Variables##########
#backup location
backup_L='/tmp/mongobkp/'
#mongo location
mongo_L='/dbfiles/data/mongo/'
#mongo server
mongo_server='localhost'
#mongo port used
port=27017
#username and password
admin_user='MongoAdmin'
passwd='m5YM9gN5'
#mongo role
mongo_role='admin'
#mongo configuration file location
conf_file='/etc/mongod.conf'
#backup formatted date
backup_date=$(date +%y%m%d_%H_%M)
#location for the application output
log_output=$backup_L"log."$backup_date
#replicaset
MONGO_RPLSET=$(echo `hostname` | awk -F'-' '{print $3}')
#backup_file name
backup_file_name="mongo_"$MONGO_RPLSET"_bkp_"$backup_date".tar.gz"
#backup file
backup_file=$backup_L$backup_file_name
#backup container in swirt
BACKUP_CONTAINER='mongo_backups'
#save pwd
PWD=`pwd`

#OpenStack config
export OS_TENANT_NAME=kyprivate
export OS_USERNAME=kyprivate
export OS_PASSWORD=kyprivate2014
export OS_AUTH_URL="http://203.130.40.133:5000/v2.0/"

function logToFile(){
	if [ ! -d "$backup_L" ]; then
		mkdir -p $backup_L
	fi
	echo $1 >> $log_output
}

##########Check and configure `swift` command ##########
if  which swift >/dev/null  2>&1 ; then
		logToFile 'Swift is installed' 
	else
		if  which pip &>/dev/null 2>&1; then
			logToFile 'Python-pip is installed... Installing swiftclient ...' 
			pip install python-swiftclient
		else
			logToFile "Installing python-pip and swiftclient ..." 
			yum install -y python-pip	
			pip install python-swiftclient
		fi
fi

##########Functions##########
# function shutdown_mongo stop the application
function shutdown_mongo {
mongo $mongo_server:$port/$mongo_role -u $admin_user -p $passwd --eval "printjson(db.shutdownServer())"
}

# function create_mongo_backup verify if the backup location exists if not create the location
# and after that create a backup
function create_mongo_backup {
if [ ! -d "$backup_L" ]; then
    mkdir -p $backup_L
fi
tar -zcvPf $backup_file $mongo_L
chown -R mongod:mongod $backup_L
}

# function to copy backup archive to swift and clean local file
function copyFileToSwift(){
cd $backup_L
swift upload $BACKUP_CONTAINER $backup_file_name
cd $PWD
rm -f $backup_file
}

# function start_mongo start the mongo application
function start_mongo {
mongod -f $conf_file
}

# function run_backup check first if the mongo application is started if not write a error message
# in the output file, if the application is started run the above functions to make the backup
function run_backup {
echo "Backup started: `date`"
echo " "

mongo --eval "db.stats()"  # do a simple harmless command of some sort
RESULT=$?   # returns 0 if mongo eval succeeds

if [ $RESULT -ne 0 ]; then
    echo "Error mongo is not running, `date`"
    exit 1
else
    #stop the mongo application
    shutdown_mongo
    #make the backup
    create_mongo_backup
	#copy file to swift
	copyFileToSwift
    #start the application
    start_mongo
fi

echo " "
echo "Backup ended: `date`"
} >> $log_output


##############################
# run the function run_backup
run_backup
