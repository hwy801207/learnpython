#! /bin/bash
STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" ]; then
echo "Please enter environment. ex. 
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

##########SOLR creating process##########
logMessageToConsole "INFO" "Creating solr instances"
./createinstance.sh "$SOLR_SERVER_GENERIC-01" $AVAILABILITY_ZONE_1 $ENVIRONMENT $SOLR_STATIC_IP1
exitIfNotSuccess "$?"
./createinstance.sh "$SOLR_SERVER_GENERIC-02" $AVAILABILITY_ZONE_2 $ENVIRONMENT $SOLR_STATIC_IP2
exitIfNotSuccess "$?"

formExecutionTime
logMessageToConsole "INFO" "Add cloud instances execution time $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"