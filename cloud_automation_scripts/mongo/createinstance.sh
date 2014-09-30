#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter instance name, availability zone and environment ex: 
		./createinstance.sh mongod-database-rs01-01 availability-zone1 stage
		./createinstance.sh mongod-config-rs01-01 availability-zone1 stage
		./createinstance.sh mongod-database-rs01-01 availability-zone1 prod
		./createinstance.sh mongod-config-rs01-01 availability-zone1 prod 
	"
exit 1
fi
INSTANCE=$1
AVAILABILITY_ZONE=$2
ENVIRONMENT=$3
INSTANCE_TYPE=$(echo $INSTANCE | awk -F'-' '{print $2}' | tr -d ' ')

if [ ! -z "$4" ]; then
		IP_STRING=",v4-fixed-ip=$4"
fi

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

##########We need to have group of instances no specified##########
nova list  >  novalist.tmp
INSTANCE_ALREADY_EXISTS=$(grep $INSTANCE novalist.tmp)

if [ ! -z "$INSTANCE_ALREADY_EXISTS" ]; then
	logMessageToConsole "ERROR" "At least one instance with that name exist... Please delete first or change instances name"
	rm -f novalist.tmp
	exit 1
fi

rm -f novalist.tmp

if [ "$INSTANCE_TYPE" == "database" ]; then
	createOrGetInstanceVolume $INSTANCE $MONGO_VOLUME_SIZE
	bootInstance "$INSTANCE" "$MONGO_FLAVOR" "$AVAILABILITY_ZONE" "$MONGO_IMAGE" "$MONGO_SECURITY_GROUP" "$MONGO_NET_ID$IP_STRING" "$KEY_NAME" "install_mongo.sh" "$CONFIG_PARAMS_TO_PASS" "$VOLUME_ID"
	exit "$?"
elif [ "$INSTANCE_TYPE" == "config" ]; then
	bootInstance "$INSTANCE" "$MONGO_CONFIG_FLAVOR" "$AVAILABILITY_ZONE" "$MONGO_CONFIG_IMAGE" "$MONGO_CONFIG_SECURITY_GROUP" "$MONGO_CONFIG_NET_ID$IP_STRING" "$KEY_NAME" "install_mongo.sh" "$CONFIG_PARAMS_TO_PASS"
	exit "$?"
elif [ "$INSTANCE_TYPE" != "config" -a "$INSTANCE_TYPE" != "database" ]; then
	logMessageToConsole "ERROR" "$INSTANCE_TYPE does not exist as a monogo type instance. Exiting ..."
	exit 1
fi