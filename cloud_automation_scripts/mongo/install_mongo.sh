#!/bin/bash

STARTTIME=$(date +%s)
SERVICE=$1

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

# PARAMETERS FILE
SWIFT_MONGO_KEY='mongo_key'
SWIFT_UTILS_CONTAINER='script_utils'


. /tmp/config_params.sh
. /tmp/config_func.sh

rm -f  /tmp/config_params.sh /tmp/config_func.sh

setHostname
configureLocalRepo
addKydevUser
removeDevopsUserSudoPassword

installAndConfigureZabbix
startZabbix

##########If no input parameter use hostname as service##########
if [ -z "$1" ]; then
	SERVICE=$(hostname)
fi
TYPE=$(echo $SERVICE | awk -F'-' '{print $1"-"$2}')
SERVER_NO=$(echo $SERVICE | awk -F'-' '{print $4}')
RPLSET=$(echo `hostname` | awk -F'-' '{print $3}')

##########Getting curent host ip##########
 findMyIP

##########If current ip not found exit##########
if [ -z "$myip" ]; then
	logMessageToFile "ERROR"  "Could not get your ip for the specified host $(hostname)... $SERVICE not installed! "
	exit 1;
fi

##########Adding hostname in hosts##########
configureHostname

##########Saving current directory path##########
PWD_DIR=$(pwd)

##########Save nova available instances in temporary file##########
nova list > $PWD_DIR/nova_instances.tmp

##########Installing new service##########
logMessageToFile "INFO"  'Unnstaling service mongo-10gen mongo-10gen-server' 
yum --disablerepo="*" --enablerepo="LocalRepo" remove -y mongo-10gen mongo-10gen-server
logMessageToFile "INFO"  'Instaling service mongo-10gen mongo-10gen-server' 
yum --disablerepo="*" --enablerepo="LocalRepo" install -y mongo-10gen mongo-10gen-server
logMessageToFile "INFO"  'Configuring service mongo-10gen mongo-10gen-server' 

if [ "$TYPE" == "$MONGOD_DATABASE" ]; then
	installAndConfigureMongoVolume
	configureMongoKey
	getMyRSIp
	if [ ! -d "$MONGOD_DATABASE_DBPATH" ]; then
		mkdir -p $MONGOD_DATABASE_DBPATH
	fi
	if [ ! -d "$MONGOD_DATABASE_LOGPATH_DIR" ]; then
		mkdir -p $MONGOD_DATABASE_LOGPATH_DIR
	fi

	echo '#mongod.conf
dbpath='$MONGOD_DATABASE_DBPATH'
logpath='$MONGOD_DATABASE_LOGPATH'
port='$MONGOD_DATABASE_PORT'
bind_ip='$myip',127.0.0.1
fork='$MONGOD_DATABASE_FORK'
replSet='$RPLSET'
shardsvr='$MONGOD_DATABASE_SHARDSVR'
logappend='$MONGOD_DATABASE_LOGAPPEND'
smallfiles='$MONGOD_DATABASE_SMALL_FILES'
oplogSize='$MONGOD_DATABASE_OP_LOGSIZE'
auth='$MONGO_AUTH'
keyFile='$MONGO_KEY''  > /etc/mongod.conf

logMessageToFile "INFO"  "myrsip=:$myrsip  MONGOD_DATABASE_ADMIN:$MONGOD_DATABASE_ADMIN  myip:$myip  MONGOD_DATABASE_PORT:$MONGOD_DATABASE_PORT "
mongod -f /etc/mongod.conf 

if [ "$?" -eq "0" ]; then
waitTillProcessIsUp "mongod"

if [ "$SERVER_NO" == "01" ]; then
	mongo --eval 'rs.initiate();' >> /var/log/cloud-install.log
	sleep $MONGO_INITIATE_UPTIME
	myrsprimaryip=$(mongo $MONGOD_DATABASE_ADMIN --quiet --eval 'rs.status().members.forEach( function(doc) { if (doc.stateStr == "PRIMARY") {print (doc.name) } ;})')
	while [ "$myrsprimaryip" != "$myip:$MONGOD_DATABASE_PORT" ]
	do
	logMessageToFile "ERROR"  "Initiating failed... Retry ..."
	mongo --eval 'rs.initiate();' >> /var/log/cloud-install.log
	sleep $MONGO_INITIATE_UPTIME
	myrsprimaryip=$(mongo $MONGOD_DATABASE_ADMIN --quiet --eval 'rs.status().members.forEach( function(doc) { if (doc.stateStr == "PRIMARY") {print (doc.name) } ;})')
	done
	
	mongo $MONGOD_DATABASE_ADMIN --eval 'db.addUser( { user: "'$MONGOD_DATABASE_ADMIN_USER'",
                  pwd: "'$MONGOD_DATABASE_ADMIN_PASS'",
                  roles: [ "userAdminAnyDatabase",
                           "clusterAdmin",
                           "readAnyDatabase",
                           "dbAdminAnyDatabase",
                           "readWriteAnyDatabase" 
                         ] 
                } 
               );'  >> /var/log/cloud-install.log
else
	primaryip=$(mongo $myrsip:$MONGOD_DATABASE_PORT/$MONGOD_DATABASE_ADMIN -u $MONGOD_DATABASE_ADMIN_USER -p $MONGOD_DATABASE_ADMIN_PASS --quiet --eval 'rs.status().members.forEach( function(doc) { if (doc.stateStr == "PRIMARY") {print (doc.name) } ;})')
	while [ "$primaryip" != "$myrsip:$MONGOD_DATABASE_PORT" ]
	do
	logMessageToFile "INFO"  "Waiting for primary $myrsip to come up in mongo... Retry ..."
	sleep 10
	primaryip=$(mongo $myrsip:$MONGOD_DATABASE_PORT/$MONGOD_DATABASE_ADMIN -u $MONGOD_DATABASE_ADMIN_USER -p $MONGOD_DATABASE_ADMIN_PASS --quiet --eval 'rs.status().members.forEach( function(doc) { if (doc.stateStr == "PRIMARY") {print (doc.name) } ;})')
	done
	logMessageToFile "INFO"  "mongo $primaryip/$MONGOD_DATABASE_ADMIN -u $MONGOD_DATABASE_ADMIN_USER -p $MONGOD_DATABASE_ADMIN_PASS --eval 'rs.add('$myip':'$MONGOD_DATABASE_PORT');'"
	mongo $primaryip/$MONGOD_DATABASE_ADMIN -u $MONGOD_DATABASE_ADMIN_USER -p $MONGOD_DATABASE_ADMIN_PASS --eval 'rs.add("'$myip':'$MONGOD_DATABASE_PORT'");'  >> /var/log/cloud-install.log
	logMessageToFile "INFO"  "Successfully added this node to replica set..."
fi
else
logMessageToFile "ERROR"  "Please check config for mongo! Service could not be started using this config!"
fi
elif [ "$TYPE" == "$MONGOD_CONFIG" ]; then
	configureMongoKey
	if [ ! -d "$MONGOD_CONFIG_DBPATH" ]; then
		mkdir -p $MONGOD_CONFIG_DBPATH
	fi
	if [ ! -d "$MONGOD_CONFIG_LOGPATH_DIR" ]; then
		mkdir -p $MONGOD_CONFIG_LOGPATH_DIR
	fi

	echo '#mongodcfg.conf
dbpath='$MONGOD_CONFIG_DBPATH'
fork='$MONGOD_CONFIG_FORK'
logpath='$MONGOD_CONFIG_LOGPATH'
logappend='$MONGOD_CONFIG_LOGAPPEND'
port='$MONGOD_CONFIG_PORT'
bind_ip='$myip',127.0.0.1
configsvr='$MONGOD_CONFIG_CONFIGSVR'
smallfiles='$MONGOD_CONFIG_SMALLFILES'
auth='$MONGO_AUTH'
keyFile='$MONGO_KEY'' > /etc/mongodcfg.conf
	mongod -f /etc/mongodcfg.conf 
	if [ "$?" -eq "0" ]; then
	waitTillProcessIsUp "mongod"
	if [ "$SERVER_NO" == "01" ]; then
		mongo  localhost:$MONGOD_CONFIG_PORT/$MONGOD_CONFIG_ADMIN --eval 'db.addUser( { user: "'$MONGOD_DATABASE_ADMIN_USER'",
                  pwd: "'$MONGOD_DATABASE_ADMIN_PASS'",
                  roles: [ "userAdminAnyDatabase",
                           "clusterAdmin",
                           "readAnyDatabase",
                           "dbAdminAnyDatabase",
                           "readWriteAnyDatabase" 
                         ] 
                } 
               );' >> /var/log/cloud-install.log
	fi
	else
	logMessageToFile "ERROR"  "Please check config for mongocfg! Service could not be started using this config!"
	fi
fi


cd $PWD_DIR
rm -f nova_instances.tmp

formExecutionTime
logMessageToFile "INFO"  "Mongo was installed and configured successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"
