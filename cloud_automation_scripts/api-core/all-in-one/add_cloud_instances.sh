#! /bin/bash
STARTTIME=$(date +%s)

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########We need to have group of instances no specified##########
if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter rpm version, instances group and environment ex. 
		./add_cloud_instances.sh 5091 01 stage  
		./add_cloud_instances.sh 5091 01 prod
		"
exit 1
fi

RPM_VERSION=$1
INSTANCES_NO=$2
ENVIRONMENT=$3
REPLICA_SET="01"



. ../../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

configureLocalRepo
logMessageToConsole "INFO" "Checking for package existance..."


swift list rpmrepo > swiftlist_rpmrepo.tmp
for i in api-user api-auth api-banking api-company api-search api-support api-transaction api-backend api-basp deploy-core-file deploy-core-user deploy-core-messaging deploy-core-banking deploy-core-company deploy-core-engine deploy-core-encryption deploy-core-transaction deploy-core-backend
do
	existsInRepo=$(yum --disablerepo="*" --enablerepo="LocalRepo" --showduplicates list $i | grep $PLATFORM_MAJOR_VERSION$RPM_VERSION)
	existsInSwift=$(grep $i swiftlist_rpmrepo.tmp | grep $PLATFORM_MAJOR_VERSION$RPM_VERSION)
	if [ -z "$existsInRepo" ]; then
		if [ -z "$existsInSwift" ]; then
			logMessageToConsole "ERROR" "This rpm: $i-$PLATFORM_MAJOR_VERSION$RPM_VERSION does not exists in china repo and swift! Please upload it to swift and then download it to china repo"
		else
			logMessageToConsole "ERROR" "This rpm: $i-$PLATFORM_MAJOR_VERSION$RPM_VERSION does not exists in china repo but is available in swift! Please download it to china repo"
		fi
		rm -f swiftlist_rpmrepo.tmp
		exit 1
	fi
done
rm -f swiftlist_rpmrepo.tmp

function createInstance(){
local instance_name=$1
local availability_zone=$2
local envrionment=$3
./createinstance.sh $instance_name $availability_zone $envrionment
if [ "$?" -eq 1 ]; then
	exit 1
fi
}

AVAILABILITY_ZONE=$(getAZName "$INSTANCES_NO")

##########Cores creating process##########
logMessageToConsole "INFO" "Creating cores-$INSTANCES_NO"
createInstance "$CORE_FILE_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_USER_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_MESSAGING_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_BANKING_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_COMPANY_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_ENGINE_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_ENCRYPTION_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_TRANSACTION_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$CORE_BACKEND_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"


##########Apis creating process##########
logMessageToConsole "INFO" "Creating apis-$INSTANCES_NO"
createInstance "$API_AUTH_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_USER_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_BANKING_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_COMPANY_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_SEARCH_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_SUPPORT_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_TRANSACTION_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_BACKEND_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"
createInstance "$API_BASP_GENERIC-$RPM_VERSION-rs$REPLICA_SET-$INSTANCES_NO" "$AVAILABILITY_ZONE" "$ENVIRONMENT"

 ./healthcheck.sh $RPM_VERSION

formExecutionTime
logMessageToConsole "INFO" "Add cloud instances execution time $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"