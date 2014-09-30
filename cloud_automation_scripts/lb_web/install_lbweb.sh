#!/bin/bash

STARTTIME=$(date +%s)

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

# PARAMETERS FILE
SWIFT_UTILS_CONTAINER='script_utils'

. /tmp/config_params.sh
. /tmp/config_func.sh

rm -f  /tmp/config_params.sh /tmp/config_func.sh

UNHEALTHY_TIME=20 		#seconds
HEALTH_FREQUENCY=5 		#DEFAULT 5 seconds ; must be under 60 seconds

#Ethernet inferface


MASTER_NAME=$(nova list | grep $LB_WEB_FLOATING_IP_1 | awk -F'|' '{print $3}')
MASTER_IP=$(nova list | grep $MASTER_NAME | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>0) exit }' | tr -d ' ')

function configure(){

setHostname
configureLocalRepo
addKydevUser
removeDevopsUserSudoPassword

findMyIP
configureHostname

installAndConfigureWebHaProxy
startHAProxy
installAndConfigureZabbix
startZabbix

formExecutionTime
logMessageToFile "INFO"  "Instance was installed and configured successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"
}

function diassociateFloatingIp(){
logMessageToFile "INFO"  'diassociateFloatingIp'
INSTANCE=$1
nova remove-floating-ip $INSTANCE $LB_WEB_FLOATING_IP_1 
} >> $LOG_FILE 2>&1

function associateFloatingIp(){
logMessageToFile "INFO"  'associateFloatingIp'
INSTANCE=$1
nova add-floating-ip $INSTANCE $LB_WEB_FLOATING_IP_1
} >> $LOG_FILE 2>&1

function pingFloatingIP(){
i=1
while [ $i -le $(($UNHEALTHY_TIME/$HEALTH_FREQUENCY)) ]
do
	sleep $HEALTH_FREQUENCY
	((i++))
	ping -q -c 1 $LB_WEB_FLOATING_IP_1 > /dev/null
	if [ "$?" -eq "0" ]; then
		return 0
	fi
done
return 1
}

function findAvailabilityZone(){
AVAILABILITY_ZONE=''
MASTER_AZ=$(nova show $MASTER_NAME | grep availability_zone | awk -F'|' '{ print $3}' | tr -d ' ')
AVAILABILITY_ZONE=$(nova availability-zone-list | grep available | grep $MASTER_AZ | awk -F'|' '{ print $2}' | tr -d ' ')
if [ -z "$AVAILABILITY_ZONE" ]; then
	AVAILABILITY_ZONE=$(nova availability-zone-list | grep available | awk -F'|' '{if(count==0)print $2; count++; }' | tr -d ' ')
fi
}

function createInstance(){
logMessageToFile "INFO"  "Creating instance: $1"
((RETRY_INDEX++))
INSTANCE_ID=`nova boot $1 --flavor $LBWEB_FLAVOR --image $LBWEB_IMAGE --security-groups $LBWEB_SECURITY_GROUP --user-data $USER_DATA --key-name $KEY_NAME --nic net-id=$LBWEB_NET_ID --availability-zone $AVAILABILITY_ZONE | grep " id " | awk -F'|' '{print $3}'`

INSTANCE_IS_RUNNING=""
ERROR=""
j=1

while [ -z "$INSTANCE_IS_RUNNING" -a -z "$ERROR" -a "$j" -le "$(($TIMEOUT*6))" ]
do
	nova list > novalist.tmp
	INSTANCE_IS_RUNNING=$(grep $INSTANCE_ID novalist.tmp| grep -i 'active' | grep -i 'running' | awk -F'|' '{print $0}')
	ERROR=$(grep $INSTANCE_ID novalist.tmp| awk -F'|' '{print $0}' | grep -i 'error')
	sleep $SHORT_RETRY_INTERVAL
done

if [ "$ERROR" != "" ]; then
	logMessageToFile "INFO"  "Instance $INSTANCE_ID created in error... Detele and Retry..."
	nova delete $(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $2}')
	sleep $SHORT_RETRY_INTERVAL
	if [ $RETRY_INDEX -le $RETRY ]; then
		createInstance $1
	else
		logMessageToFile "INFO"  "Instance create failed; no more retries.. exiting"
	fi
	

elif [ -z "$INSTANCE_IS_RUNNING" ]; then
	logMessageToFile "INFO"  "Instance $INSTANCE_ID could not reach running state! Deleting..."
	nova delete $(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $2}')
	sleep $SHORT_RETRY_INTERVAL
	if [ $RETRY_INDEX -le $RETRY ]; then
		createInstance $1
	else
		logMessageToFile "ERROR"  "Instance create failed; no more retries.. exiting"
	fi
fi

logMessageToFile "INFO"  "Verifying instance $INSTANCE_ID reply to ping... Please be patient this could take up to $WAIT_FOR_PING_REPLY  minutes"
INSTANCE_IP=$(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>2) exit }' | tr -d ' ')
checkHAInstanceCreatedSuccssfully $INSTANCE_IP

if [ "$?" != "0" ]; then
	TO_BE_DELETED=$TO_BE_DELETED" "$INSTANCE_ID
	if [ $RETRY_INDEX -le $RETRY ]; then
		logMessageToFile "ERROR"  "Instance failed to respond to ping. Recreating ..."
		createInstance $1
	else
		formExecutionTime
		logMessageToFile "INFO"  "Instance $INSTANCE  create failed. Time passed: $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"
	fi
else
	formExecutionTime
	logMessageToFile "INFO"  "Instance $INSTANCE was created successfully at ip: $INSTANCE_IP in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"

fi
if [ ! -z "$TO_BE_DELETED" ]; then
	logMessageToFile "INFO"  "deleting instances: $TO_BE_DELETED"
	nova delete $TO_BE_DELETED
	TO_BE_DELETED=''
fi
rm -f novalist.tmp
}

function startMonitor(){
if [ ! -z "$MASTER_NAME" ]; then
	logMessageToFile "INFO"  "Starting to monitor master: $MASTER_NAME"
	pingFloatingIP
	while [[ "$?" -eq "0" ]]; do
		pingFloatingIP
	done
	logMessageToFile "ERROR"  'Disaster has occured !'
	findAvailabilityZone
	diassociateFloatingIp $MASTER_NAME
	associateFloatingIp $(hostname)
	# MASTER_EXISTS=$(nova list | grep $MASTER_NAME)
	# if [[ ! -z "$MASTER_EXISTS" ]]; then
	# 	nova delete $MASTER_NAME
	# fi
	# cd /var/lib/cloud/instances/i-*
	# USER_DATA=$(pwd)/user-data.txt
	# createInstance $MASTER_NAME
else
	logMessageToFile "INFO"  'No master detected... Assuming I am the master... Getting master floating ip to me'
	associateFloatingIp $(hostname)
fi

logMessageToFile "INFO"  'Done with the script'
}

function main(){
configure	
#startMonitor
}

##########Execute main##########
main