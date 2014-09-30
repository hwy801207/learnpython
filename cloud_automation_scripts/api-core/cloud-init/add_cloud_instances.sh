#! /bin/bash

##########Prerequisites##########
# 1. Nova is installed
# 2. This script is beeing runned from the cloud admin server 
# 3. The instances are beeing created using cloud admin server key which is added in nova as cloud_admin_ssh_key

STARTTIME=$(date +%s)

##########We need to have group of instances no specified##########
if [ -z "$1" ]; then
echo "Please enter instance"
exit 1
fi
INSTANCES_NO=$1

##########We need to have group of instances no specified##########
nova list  >  novalist.tmp
CORE_INSTANCES_ALREADY_EXISTS=$(grep "core-" novalist.tmp | grep "\-"$INSTANCES_NO )
API_INSTANCES_ALREADY_EXISTS=$(grep "api-" novalist.tmp | grep "\-"$INSTANCES_NO )

if [ ! -z "$CORE_INSTANCES_ALREADY_EXISTS" -o ! -z "$API_INSTANCES_ALREADY_EXISTS" ]; then
	echo "At least one core/api instance with that name exist... Please delete first or change instances no"
	rm -f novalist.tmp
	exit 1
fi

##########Cores creating process##########
echo "Creating cores-"$INSTANCES_NO
./createinstance.sh "core-file-"$INSTANCES_NO
./createinstance.sh "core-user-"$INSTANCES_NO
./createinstance.sh "core-messaging-"$INSTANCES_NO
./createinstance.sh "core-banking-"$INSTANCES_NO
./createinstance.sh "core-company-"$INSTANCES_NO
./createinstance.sh "core-engine-"$INSTANCES_NO
./createinstance.sh "core-encryption-"$INSTANCES_NO
./createinstance.sh "core-transaction-"$INSTANCES_NO


##########Apis creating process##########
echo "Creating apis-"$INSTANCES_NO
./createinstance.sh "api-auth-"$INSTANCES_NO
./createinstance.sh "api-user-"$INSTANCES_NO
./createinstance.sh "api-banking-"$INSTANCES_NO
./createinstance.sh "api-company-"$INSTANCES_NO
./createinstance.sh "api-search-"$INSTANCES_NO
./createinstance.sh "api-support-"$INSTANCES_NO
./createinstance.sh "api-transaction-"$INSTANCES_NO

ENDTIME=$(date +%s)
ELAPSED_TIME=$(($ENDTIME - $STARTTIME))
HOURS_PASSED=$(($ELAPSED_TIME/$((60*60))))
MINUTES_PASSED=$(($(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))))/60))
SECONDS_PASSED=$(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))-$(($MINUTES_PASSED*60))))

echo "Instances were created successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"