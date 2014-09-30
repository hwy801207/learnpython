#! /bin/bash
STARTTIME=$(date +%s)

if [ -z "$1" -o -z "$2" ]; then
echo "Please enter replica set and environment ex: 
		./add_mongo_cloud_instances.sh 01 stage 
		./add_mongo_cloud_instances.sh 01 prod
		"
exit 1
fi
REPLICA_SET=$1
ENVIRONMENT=$2

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

AVAILABILITY_ZONE_1=$(getAZName 1)
AVAILABILITY_ZONE_2=$(getAZName 2)
AVAILABILITY_ZONE_3=$(getAZName 3)
AVAILABILITY_ZONE_4=$(getAZName 4)

##########$MONGOD_DATABASE creating process##########
logMessageToConsole "INFO" "Creating $MONGOD_DATABASE instances"
./createinstance.sh "$MONGOD_DATABASE-rs$REPLICA_SET-01" $AVAILABILITY_ZONE_1 $ENVIRONMENT $MONGOD_STATIC_IP1
exitIfNotSuccess "$?"
./createinstance.sh "$MONGOD_DATABASE-rs$REPLICA_SET-02" $AVAILABILITY_ZONE_2 $ENVIRONMENT $MONGOD_STATIC_IP2
exitIfNotSuccess "$?"
./createinstance.sh "$MONGOD_DATABASE-rs$REPLICA_SET-03" $AVAILABILITY_ZONE_3 $ENVIRONMENT $MONGOD_STATIC_IP3
exitIfNotSuccess "$?"
./createinstance.sh "$MONGOD_DATABASE-rs$REPLICA_SET-04" $AVAILABILITY_ZONE_4 $ENVIRONMENT $MONGOD_STATIC_IP4
exitIfNotSuccess "$?"

##########$MONGOD_CONFIG creating process##########
logMessageToConsole "INFO" "Creating mongo-config instances"
./createinstance.sh " $MONGOD_CONFIG-rs$REPLICA_SET-01" $AVAILABILITY_ZONE_1 $ENVIRONMENT $MONGOC_STATIC_IP1
exitIfNotSuccess "$?"
./createinstance.sh " $MONGOD_CONFIG-rs$REPLICA_SET-02" $AVAILABILITY_ZONE_2 $ENVIRONMENT $MONGOC_STATIC_IP2
exitIfNotSuccess "$?"
./createinstance.sh " $MONGOD_CONFIG-rs$REPLICA_SET-03" $AVAILABILITY_ZONE_3 $ENVIRONMENT $MONGOC_STATIC_IP3
exitIfNotSuccess "$?"


formExecutionTime
logMessageToConsole "INFO" "Add cloud instances execution time $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"