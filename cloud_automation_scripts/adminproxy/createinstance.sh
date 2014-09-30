#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter instance name, availability zone and environment ex: 
		./createinstance.sh admin-proxy-01 availability-zone-1 stage 
		./createinstance.sh admin-proxy-01 availability-zone-1 prod
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

bootInstance "$INSTANCE" "$ADMIN_PROXY_FLAVOR" "$AVAILABILITY_ZONE" "$ADMIN_PROXY_IMAGE" "$ADMIN_PROXY_SECURITY_GROUP" "$ADMIN_PROXY_NET_ID$IP_STRING" "$KEY_NAME" "install_adminproxy.sh" "$CONFIG_PARAMS_TO_PASS"
exit "$?"