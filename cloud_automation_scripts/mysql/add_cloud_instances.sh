#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" ]; then
echo "Please enter replica set and environment ex. 
		./add_cloud_instances.sh 01 stage 
		./add_cloud_instances.sh 01 prod
		"
exit 1
fi
RS=$1
ENVIRONMENT=$2

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

AVAILABILITY_ZONE_1=$(getAZName 1)
AVAILABILITY_ZONE_2=$(getAZName 2)

##########mysql creating process##########
logMessageToConsole "INFO" "Creating mysql instances"
./createinstance.sh "$MYSQL_SERVER_GENERIC-rs"$RS'-01' $AVAILABILITY_ZONE_1 $ENVIRONMENT $MYSQL_STATIC_IP1
exitIfNotSuccess "$?"
./createinstance.sh "$MYSQL_SERVER_GENERIC-rs"$RS'-02' $AVAILABILITY_ZONE_2 $ENVIRONMENT $MYSQL_STATIC_IP2
exitIfNotSuccess "$?"

formExecutionTime
logMessageToConsole "INFO" "Add cloud instances execution time $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"