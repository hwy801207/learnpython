#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter instance name, availability zone and environment. ex: 
		./createinstance.sh solr-01 availability-zone1 stage 
		./createinstance.sh solr-01 availability-zone1 prod
		"
exit 1
fi

if [ ! -z "$4" ]; then
IP_STRING=",v4-fixed-ip=$4"
fi


##########Constants##########
INSTANCE=$1
AVAILABILITY_ZONE=$2
INSTANCE_TYPE=$(echo $INSTANCE | awk -F'-' '{print $1}')
ENVIRONMENT=$3

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

createOrGetInstanceVolume $INSTANCE $SOLR_VOLUME_SIZE
bootInstance "$INSTANCE" "$SOLR_FLAVOR" "$AVAILABILITY_ZONE" "$SOLR_IMAGE" "$SOLR_SECURITY_GROUP" "$SOLR_NET_ID$IP_STRING" "$KEY_NAME" "install_solr.sh" "$CONFIG_PARAMS_TO_PASS" "$VOLUME_ID"
exit "$?"