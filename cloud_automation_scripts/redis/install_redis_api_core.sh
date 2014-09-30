#!/bin/bash

SERVICE=$1
STARTTIME=$(date +%s)

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

# PARAMETERS FILE
SWIFT_FUNC_FILE='config_func.sh'
SWIFT_UTILS_CONTAINER='script_utils'

. /tmp/config_params.sh
. /tmp/config_func.sh

rm -f  /tmp/config_params.sh /tmp/config_func.sh

function configureMyRedis(){
setHostname
addKydevUser
removeDevopsUserSudoPassword

CONFIG_PARAMS_TO_PASS=" --file /tmp/config_params.sh=/tmp/config_params.sh"

##########If no input parameter use hostname as service##########
if [ -z "$1" ]; then
	SERVICE=$(hostname)
fi
TYPE=$(echo $SERVICE | awk -F'-' '{print $1}')
SERVICE=$(echo $SERVICE | awk -F'-' '{print $2}')

##########Getting curent host ip##########
 findMyIP

##########If current ip not found exit##########
if [ -z "$myip" ]; then
	logMessageToFile "ERROR"  "Could not get your ip for the specified host $(hostname)... $SERVICE not installed! "
	exit 1;
fi

configureHostname
configureLocalRepo

##########Saving current directory path##########
PWD_DIR=$(pwd)

if  which wget >/dev/null  2>&1 ; then
		echo 'wget is installed' 
	else
		echo 'Installing wget ...' 
		yum install -y wget
fi

installAndConfigureRedis
startRedis $REDIS_PORT_API_CORE
installAndConfigureZabbix
startZabbix

cd $PWD_DIR

formExecutionTime
logMessageToFile "INFO"  "Instance was installed and configured successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"
}

function checkForRedisMasterToBeOnMasterIp(){
	PONG=$( (echo 'ping'; sleep 2) | telnet $REDIS_MASTER_IP_API_CORE $REDIS_PORT_API_CORE | grep '+PONG')
	ROLE_MASTER=$( ( echo 'info replication'; sleep 2) | telnet $REDIS_MASTER_IP_API_CORE $REDIS_PORT_API_CORE | grep 'role:master')
	sleep 5
}


function monitorAndHandleVIP(){
	logMessageToFile "INFO"  "Starting to monitor VIP on master ip: $REDIS_MASTER_IP_API_CORE"
	i=1
	while [ $i -le 10 ]; do
	checkForRedisMasterToBeOnMasterIp
	while [ ! -z "$PONG" -a ! -z "$ROLE_MASTER" ]; do
	checkForRedisMasterToBeOnMasterIp
	i=1
	done
	((i++))
	done
	logMessageToFile "INFO"  "PONG=$PONG ; ROLE_MASTER=$ROLE_MASTER"
	if [ -z "$ROLE_MASTER" ]; then
		logMessageToFile "WARN"  "Master has changed in redis sentinel. Reconfiguring VIP..."
		MASTER_ID=$(nova list | grep $REDIS_MASTER_IP_API_CORE | awk -F'|' '{ print $2}' | tr -d ' ')
		MASTER_NAME=$(nova list | grep $MASTER_ID | awk -F'|' '{ print $3}' | tr -d ' ')
		logMessageToFile "INFO"  "Old MASTER_ID is: $MASTER_ID"
		MASTER_INTERFACE=$(nova interface-list $MASTER_ID | grep $REDIS_MASTER_IP_API_CORE | awk -F'|' '{ print $3}' | tr -d ' ')
		logMessageToFile "INFO"  "Old MASTER_INTERFACE is: $MASTER_INTERFACE ... detaching..."
		nova interface-detach $MASTER_NAME $MASTER_INTERFACE
		ATTACH_TO=$(nova list | grep $REDIS_SERVER_GENERIC_API_CORE | grep -v $MASTER_ID | awk -F'|' ' { print $3}' )
		logMessageToFile "INFO"  "Attaching master ip: $REDIS_MASTER_IP_API_CORE to instance $ATTACH_TO ... "
		nova interface-attach $ATTACH_TO --net-id $REDIS_NET_ID  --fixed-ip $REDIS_MASTER_IP_API_CORE
		PORT_ID=$(nova interface-list $ATTACH_TO | grep $REDIS_MASTER_IP_API_CORE | awk -F'|' '{print $3}' | tr -d ' ')
		neutron port-update $PORT_ID --security-group $REDIS_SECURITY_GROUP
		# logMessageToFile "INFO"  "Distroying old master redis ..."
		# nova delete $MASTER_ID
		# sleep 10
		# logMessageToFile "INFO"  "Creating new redis machine ..."
		# cd /var/lib/cloud/instances/i-*
		# USER_DATA=$(pwd)/user-data.txt
		# createInstance $MASTER_NAME
	else
		logMessageToFile "INFO"  "Exiting because redis did not respoded to ping  in the last 20 seconds ..."
	fi
}


function configureAndStartRedisSentinel(){
logMessageToFile "INFO"  'configureAndStartRedisSentinel'
cd $REDIS_HOME

while [ -z "$REDIS_SECOND_INSTANCE" ]; do
logMessageToFile "INFO"  'Waiting for second instance to be up so we can configure sentinel ...'
REDIS_SECOND_INSTANCE=$(nova list | grep $REDIS_SERVER_GENERIC_API_CORE | grep -v $REDIS_MASTER_IP_API_CORE | grep -i active  | grep -i RUNNING | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>0) exit }' | tr -d ' ')
sleep 10
done
logMessageToFile "INFO"  "configuring sentinel rescue on: $REDIS_SECOND_INSTANCE"
echo 'daemonize yes
logfile /var/log/sentinel_2'$REDIS_PORT_API_CORE'.log

sentinel monitor mymaster '$REDIS_MASTER_IP_API_CORE' '$REDIS_PORT_API_CORE ' 1
sentinel down-after-milliseconds mymaster 60000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

sentinel monitor resque '$REDIS_SECOND_INSTANCE' 6380 4
sentinel down-after-milliseconds resque 10000
sentinel failover-timeout resque 180000
sentinel parallel-syncs resque 5' > /etc/redis/sentinel.conf

logMessageToFile "INFO"  "starting sentinel ..."
src/redis-sentinel /etc/redis/sentinel.conf
}

function main(){
	configureMyRedis
	configureAndStartRedisSentinel
	MASTER_ME=$( ( echo 'info replication'; sleep 1) | telnet localhost $REDIS_PORT_API_CORE | grep 'role:master')
	if [ -z "$MASTER_ME" ]; then
		monitorAndHandleVIP
	fi
	logMessageToFile "INFO"  "Done with the monitoring and the script... "
}

###########main function###########
main