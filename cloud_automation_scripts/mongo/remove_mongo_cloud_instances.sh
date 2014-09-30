#! /bin/bash

if [ -z "$1" -o -z "$2" ]; then
	echo "Please enter rs no and environment ex: 
	./remove_mongo_cloud_instances.sh 01 stage 
	./remove_mongo_cloud_instances.sh 01 prod
	"
	exit 1
fi
REPLICA_SET=$1
ENVIRONMENT=$2

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

nova list > novalist_.tmp

function findMongoInstance(){
GENERIC=$1
INSTANCES_NO=$2
grep "$GENERIC-rs$REPLICA_SET-$INSTANCES_NO" novalist_.tmp | awk -F"|" '{print $2}'
}

function deleteInstance(){
INSTANCE_ID=$1
if [ ! -z "$INSTANCE_ID" ]; then
	INSTANCE_NAME=$(grep $INSTANCE_ID novalist_.tmp |  awk -F'|' '{print $3}' | tr -d ' ')
	logMessageToConsole "INFO" "Deleting instance: $INSTANCE_NAME"
	nova delete  $INSTANCE_ID
	removeZabbixHosts "$INSTANCE_NAME"
fi
}


logMessageToConsole "INFO" "Deleting all $MONGOD_DATABASE-rs$REPLICA_SET and $MONGOD_CONFIG-rs$REPLICA_SET  instances"

MONGOD_01=$(findMongoInstance "$MONGOD_DATABASE" "01")
MONGOD_02=$(findMongoInstance "$MONGOD_DATABASE" "02")
MONGOD_03=$(findMongoInstance "$MONGOD_DATABASE" "03")
MONGOD_04=$(findMongoInstance "$MONGOD_DATABASE" "04")

MONGOC_01=$(findMongoInstance "$MONGOD_CONFIG" "01")
MONGOC_02=$(findMongoInstance "$MONGOD_CONFIG" "02")
MONGOC_03=$(findMongoInstance "$MONGOD_CONFIG" "03")

deleteInstance "$MONGOD_01"
deleteInstance "$MONGOD_02"
deleteInstance "$MONGOD_03"
deleteInstance "$MONGOD_04"

deleteInstance "$MONGOC_01"
deleteInstance "$MONGOC_02"
deleteInstance "$MONGOC_03"

rm -f novalist_.tmp

logMessageToConsole "INFO" 'Please wait ...'
sleep 10

nova list 
