#! /bin/bash
STARTTIME=$(date +%s)

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" ]; then
echo "Please enter build no and environment. ex. 
			./add_cloud_instances.sh 1058 stage 
			./add_cloud_instances.sh 1058 prod
			"
exit 1
fi
RPM_VERSION=$1
ENVIRONMENT=$2

. ../../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

configureLocalRepo
logMessageToConsole "INFO" "Checking for package existance..."
swift list rpmrepo > swiftlist_rpmrepo.tmp
existsInRepo=$(yum --disablerepo="*" --enablerepo="LocalRepo" --showduplicates list kyweb | grep $KYWEB_MAJOR_VERSION$RPM_VERSION )
existsInSwift=$(grep kyweb swiftlist_rpmrepo.tmp | grep $KYWEB_MAJOR_VERSION$RPM_VERSION )
if [ -z "$existsInRepo" ]; then
	if [ -z "$existsInSwift" ]; then
		logMessageToConsole "ERROR" "This rpm: $KYWEB_MAJOR_VERSION$RPM_VERSION does not exists in china repo and swift! Please upload it to swift and then download it to china repo"
	else
		logMessageToConsole "ERROR" "This rpm: $KYWEB_MAJOR_VERSION$RPM_VERSION does not exists in china repo but is available in swift! Please download it to china repo"
	fi
	rm -f swiftlist_rpmrepo.tmp
	exit 1
fi

rm -f swiftlist_rpmrepo.tmp

AVAILABILITY_ZONE_1=$(getAZName 1)
AVAILABILITY_ZONE_2=$(getAZName 2)

##########webui creating process##########
logMessageToConsole "INFO" "Creating webui instances"
./createinstance.sh "$WEBUI_GENERIC-"$RPM_VERSION'-01' $AVAILABILITY_ZONE_1 $ENVIRONMENT
exitIfNotSuccess "$?"
./createinstance.sh "$WEBUI_GENERIC-"$RPM_VERSION'-02' $AVAILABILITY_ZONE_2 $ENVIRONMENT
exitIfNotSuccess "$?"

formExecutionTime
logMessageToConsole "INFO" "Add cloud instances execution time $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"