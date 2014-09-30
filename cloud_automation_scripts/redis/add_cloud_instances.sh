#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" ]; then
echo "Please enter redis type and environment. ex:
        ./add_cloud_instances.sh stage
        ./add_cloud_instances.sh prod
        "
exit 1
fi
ENVIRONMENT=$1



. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

AVAILABILITY_ZONE_1=$(getAZName 1)
AVAILABILITY_ZONE_2=$(getAZName 2)
AVAILABILITY_ZONE_3=$(getAZName 3)

function waitTillRedisMasterIpIsUp(){

i=1
RETRY_INTERVAL=5
WAIT_REPLY_MASTER_TO_BE_UP=10

logMessageToConsole "INFO" "Waiting for master ip to be up... This coud take up to $WAIT_REPLY_MASTER_TO_BE_UP minutes"
while [ $i -le $(($WAIT_REPLY_MASTER_TO_BE_UP*$((60/$RETRY_INTERVAL)))) -a -z "$MASTER_IS_UP" ]
do
	MASTER_IS_UP=$(nova list | grep $REDIS_SERVER_GENERIC | grep $REDIS_MASTER_IP)
	((i++))
	logMessageToConsole "INFO" 'Master not up yet ...' 
	sleep $RETRY_INTERVAL
done
}

##########Redis creating process##########
logMessageToConsole "INFO" "Creating redis instances"
./createinstance.sh "$REDIS_SERVER_GENERIC-01" $AVAILABILITY_ZONE_1 $ENVIRONMENT $REDIS_STATIC_IP1
exitIfNotSuccess "$?"
waitTillRedisMasterIpIsUp
./createinstance.sh "$REDIS_SERVER_GENERIC-02" $AVAILABILITY_ZONE_2 $ENVIRONMENT $REDIS_STATIC_IP2
exitIfNotSuccess "$?"
./createinstance.sh "$REDIS_SERVER_GENERIC-03" $AVAILABILITY_ZONE_3 $ENVIRONMENT $REDIS_STATIC_IP3
exitIfNotSuccess "$?"

formExecutionTime
logMessageToConsole "INFO" "Add cloud instances execution time $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"