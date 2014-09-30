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

function configureAndStartRedisSentinel(){
logMessageToFile "INFO"  'configureAndStartRedisSentinel'
cd $REDIS_HOME

while [ -z "$REDIS_SECOND_INSTANCE" ]; do
logMessageToFile "INFO"  'Waiting for second instance to be up so we can configure sentinel ...'
REDIS_SECOND_INSTANCE=$(nova list | grep $REDIS_SERVER_GENERIC | grep -v $REDIS_MASTER_IP | grep -i active  | grep -i RUNNING | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>0) exit }' | tr -d ' ')
sleep 10
done
logMessageToFile "INFO"  "configuring sentinel rescue on: $REDIS_SECOND_INSTANCE"
echo 'daemonize yes
logfile /var/log/sentinel_2'$REDIS_PORT'.log
port '$REDIS_SENTINEL_PORT'

sentinel monitor mymaster '$REDIS_MASTER_IP' '$REDIS_PORT' 1
sentinel down-after-milliseconds mymaster 60000
sentinel failover-timeout mymaster 180000
sentinel parallel-syncs mymaster 1

sentinel monitor resque '$REDIS_SECOND_INSTANCE' '$REDIS_PORT' 4
sentinel down-after-milliseconds resque 10000
sentinel failover-timeout resque 180000
sentinel parallel-syncs resque 5' > /etc/redis/sentinel.conf

logMessageToFile "INFO"  "starting sentinel ..."
src/redis-sentinel /etc/redis/sentinel.conf
}


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

installAndConfigureRedis
startRedis 
configureAndStartRedisSentinel

installAndConfigureZabbix
configureRedisMonitoring
startZabbix



cd $PWD_DIR

formExecutionTime
logMessageToFile "INFO"  "Instance was installed and configured successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"