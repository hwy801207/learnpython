#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter instance name, availability-zone and environment ex: 
		./createInstance.sh lb-web-01 availability-zone1 stage 
		./createInstance.sh lb-web-01 availability-zone1 prod
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

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

##########We need to have group of instances no specified##########
nova list  >  novalist.tmp
INSTANCE_ALREADY_EXISTS=$(grep $INSTANCE novalist.tmp)

if [ ! -z "$INSTANCE_ALREADY_EXISTS" ]; then
	logMessageToConsole "INFO" "At least one instance with that name exist... Please delete first or change instances name"
	rm -f novalist.tmp
	exit 1
fi

rm -f novalist.tmp

bootInstance "$INSTANCE" "$LBWEB_FLAVOR" "$AVAILABILITY_ZONE" "$LBWEB_IMAGE" "$LBWEB_SECURITY_GROUP" "$LBWEB_NET_ID$IP_STRING" "$KEY_NAME" "install_lbweb.sh" "$CONFIG_PARAMS_TO_PASS"
exit "$?"