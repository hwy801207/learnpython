#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter instance name, availability-zone and environment ex: 
		./createinstance.sh core-user-4866-rs01-01 availability-zone1 stage 
		./createinstance.sh core-user-4866-rs01-01 availability-zone1 prod
		"
exit 1
fi

if [ ! -z "$4" ]; then
IP_STRING=",v4-fixed-ip=$4"
fi

##########Constants##########
INSTANCE=$1
AVAILABILITY_ZONE=$2
ENVIRONMENT=$3
INSTANCE_TYPE=$(echo $INSTANCE | awk -F'-' '{print $1}')

. ../../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT
injectLogsCollector $ENVIRONMENT


##########We need to have group of instances no specified##########
nova list  >  novalist.tmp
INSTANCE_ALREADY_EXISTS=$(grep $INSTANCE novalist.tmp)

if [ ! -z "$INSTANCE_ALREADY_EXISTS" ]; then
	echo "At least one instance with that name exist... Please delete first or change instances name"
	rm -f novalist.tmp
	exit 1
fi

rm -f novalist.tmp

if [ "$INSTANCE_TYPE" == "api" ]; then
	bootInstance "$INSTANCE" "$API_FLAVOR" "$AVAILABILITY_ZONE" "$API_IMAGE" "$API_SECURITY_GROUP" "$API_NET_ID$IP_STRING" "$KEY_NAME" "install_api_core.sh" "$CONFIG_PARAMS_TO_PASS"
elif [ "$INSTANCE_TYPE" == "core" ]; then
	bootInstance "$INSTANCE" "$CORE_FLAVOR" "$AVAILABILITY_ZONE" "$CORE_IMAGE" "$CORE_SECURITY_GROUP" "$CORE_NET_ID$IP_STRING" "$KEY_NAME" "install_api_core.sh" "$CONFIG_PARAMS_TO_PASS"
elif [ "$INSTANCE_TYPE" != "core" -a "$INSTANCE_TYPE" != "api" ]; then
	echo "[ERROR] - Please choose api/core"
	exit 1
fi