#!/bin/bash

SERVICE=$1
STARTTIME=$(date +%s)

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

# PARAMETERS FILE
SWIFT_MONGO_KEY='mongo_key'
SWIFT_UTILS_CONTAINER='script_utils'


. /tmp/config_params.sh
. /tmp/config_func.sh

rm -f  /tmp/config_params.sh /tmp/config_func.sh

addKydevUser
setUlimit
setHostname
configureLocalRepo
removeDevopsUserSudoPassword
configreApplicationLogsDir
setNotRequireTTYforDevops

##########If no input parameter use hostname as service##########
if [ -z "$1" ]; then
	SERVICE=$(hostname)
fi
TYPE=$(echo $SERVICE | awk -F'-' '{print $1}')
RPM_VERSION=$(echo $SERVICE | awk -F'-' '{print $3}')
SERVICE=$(echo $SERVICE | awk -F'-' '{print $2}')

##########Getting curent host ip##########
 findMyIP

##########If current ip not found exit##########
if [ -z "$myip" ]; then
	logMessageToFile "ERROR"  "Could not get your ip for the specified host $(hostname)... $SERVICE not installed! "
	exit 1;
fi

configureHostname


function insertOtherInstanceIP(){
logMessageToFile "INFO" "insertOtherInstanceIP"
local comp=$1
local port=$2
local ip=$3

INSTANCE_GROUP_NO=$(echo $(hostname) | awk -F'-' '{print $5}')
if [ "$INSTANCE_GROUP_NO" == "02" ]; then
	if [ -z "$comp" -o -z "$port" -o -z "$ip" ]; then
		logMessageToFile "ERROR" "None of component=$comp port=$port ip=$ip can be empty"
		exit 1
	fi
	sed -i "2s/^/component\.$comp\.other=$ip:$port\n/"  instance.properties
fi
}


##########Saving current directory path##########
PWD_DIR=$(pwd)

##########Save nova available instances in temporary file##########
nova list > nova_instances.tmp

installAndConfigureJAVA
RPLSET=$(echo `hostname` | awk -F'-' '{print $4}')

if [ $TYPE == "core" ]; then

##########Installing new service##########
installRPM 'mongo-10gen'
installRPM 'mongo-10gen-server'
installRPM "deploy-core-$SERVICE-$PLATFORM_MAJOR_VERSION$RPM_VERSION"

##########Configuring new service##########
logMessageToFile "INFO"  "Configuring service deploy-core-$SERVICE-$PLATFORM_MAJOR_VERSION$RPM_VERSION"
rm -f /opt/ky/core-$SERVICE/deploy-core-$SERVICE-*/conf/db.properties
cd /opt/ky/core-$SERVICE/deploy-core-$SERVICE-*/conf/
configCoreFile

logMessageToFile "INFO"  'Configuring service mongo-10gen mongo-10gen-server' 
#Handling mongo key
if [ ! -d "$MONGO_KEY_DIR" ]; then
	mkdir -p $MONGO_KEY_DIR
fi
swift download $SWIFT_UTILS_CONTAINER $SWIFT_MONGO_KEY --output $MONGO_KEY

##########Setting permissions for key file##########
chmod 700 $MONGO_KEY
chown -R mongod:mongod $MONGO_KEY_DIR

##########Configuring mongos database##########
mkdir -p $MONGOS_LOGPATH_DIR
chown -R mongod:mongod $MONGOS_LOGPATH_DIR
getConfigDBS
getDatabaseDBS
echo '#mongos.conf
configdb='$MONGOS_CONFIGDB'   
port='$MONGOS_PORT'
fork='$MONGOS_FORK'
logappend='$MONGOS_LOGAPPEND'
logpath='$MONGOS_LOGPATH'
bind_ip='$myip',127.0.0.1
keyFile='$MONGO_KEY'' > /etc/mongos.conf

mongos -f /etc/mongos.conf
if [ "$?" -eq "0" ]; then
waitTillProcessIsUp "mongos"

else
logMessageToFile "ERROR"  "Please check config for mongos! Service could not be started using this config!"
fi

findAvailableMysql
findAvailableMongo

##########Configuring new service##########
if [[ "$SERVICE" == "user" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_USER_MONGO_DBNAME $CORE_USER_MONGO_USER $CORE_USER_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_USER_MYSQL_DBNAME $CORE_USER_MYSQL_USER $CORE_USER_MYSQL_PASS
	configureUserSchedulers
	sed -i "s/^component\.user\.this=.*/component\.user\.this=$myip:$PORT_USER/"  instance.properties
	insertOtherInstanceIP "user" "$PORT_USER" "$user_ip1"
	chown kaiyuan:kaiyuan instance.properties
	service core-user start		
elif [[ "$SERVICE" == "banking" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_BANKING_MONGO_DBNAME $CORE_BANKING_MONGO_USER $CORE_BANKING_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_BANKING_MYSQL_DBNAME $CORE_BANKING_MYSQL_USER $CORE_BANKING_MYSQL_PASS
	sed -i "s/^component\.banking\.this=.*/component\.banking\.this=$myip:$PORT_BANKING/"  instance.properties
	insertOtherInstanceIP "banking" "$PORT_BANKING" "$banking_ip1"
	chown kaiyuan:kaiyuan instance.properties
	configureBASPParameters
	configureBankingSchedulers
	configureRabbitMQParameters
	configureRabbitMQGenericParameters
	service core-banking start
elif [[ "$SERVICE" == "company" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_COMPANY_MONGO_DBNAME $CORE_COMPANY_MONGO_USER $CORE_COMPANY_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_COMPANY_MYSQL_DBNAME $CORE_COMPANY_MYSQL_USER $CORE_COMPANY_MYSQL_PASS
	sed -i "s/^component\.company\.this=.*/component\.company\.this=$myip:$PORT_COMPANY/"  instance.properties
	insertOtherInstanceIP "company" "$PORT_COMPANY" "$company_ip1"
	configureSpecialRolesJson
	chown kaiyuan:kaiyuan instance.properties
	configureSolrParameters
	service core-company start
elif [[ "$SERVICE" == "engine" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_ENGINE_MONGO_DBNAME $CORE_ENGINE_MONGO_USER $CORE_ENGINE_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_ENGINE_MYSQL_DBNAME $CORE_ENGINE_MYSQL_USER $CORE_ENGINE_MYSQL_PASS
	sed -i "s/^component\.engine\.this=.*/component\.engine\.this=$myip:$PORT_ENGINE/"  instance.properties
	insertOtherInstanceIP "engine" "$PORT_ENGINE" "$engine_ip1"
	chown kaiyuan:kaiyuan instance.properties
	configureRabbitMQParameters
	configureRabbitMQGenericParameters
	configureExtRabbitMQParameters
	configureSwiftParameters
	service core-engine start
elif [[ "$SERVICE" == "file" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_FILE_MONGO_DBNAME $CORE_FILE_MONGO_USER $CORE_FILE_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_FILE_MYSQL_DBNAME $CORE_FILE_MYSQL_USER $CORE_FILE_MYSQL_PASS
	sed -i "s/^component\.file\.this=.*/component\.file\.this=$myip:$PORT_FILE/"  instance.properties
	insertOtherInstanceIP "file" "$PORT_FILE" "$file_ip1"
	chown kaiyuan:kaiyuan instance.properties
	configureSwiftParameters
	service core-file start
elif [[ "$SERVICE" == "messaging" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_MESSAGING_MONGO_DBNAME $CORE_MESSAGING_MONGO_USER $CORE_MESSAGING_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_MESSAGING_MYSQL_DBNAME $CORE_MESSAGING_MYSQL_USER $CORE_MESSAGING_MYSQL_PASS
	echo $BASE_URL > url.properties
	echo "$MAIL_PROPERTIES" > mail.properties
	sed -i "s/^component\.messaging\.this=.*/component\.messaging\.this=$myip:$PORT_MESSAGING/"  instance.properties
	insertOtherInstanceIP "messaging" "$PORT_MESSAGING" "$messaging_ip1"
	chown kaiyuan:kaiyuan instance.properties mail.properties url.properties
#	echo '
#ky.core.common.confirmation.id.user.name = true' >> core.properties
	configureRabbitMQParameters
	configureRabbitMQGenericParameters
	service core-messaging start
elif [[ "$SERVICE" == "encryption" ]]; then
	sed -i "s/^component\.encryption\.this=.*/component\.encryption\.this=$myip:$PORT_ENCRYPTION/"  instance.properties
	insertOtherInstanceIP "encryption" "$PORT_ENCRYPTION" "$encryption_ip1"
	sed -i "s/^enc\.service\.private\.key\.file=.*/enc\.service\.private\.key\.file=$PRIVATE_KEY_FILE/"  instance.properties
	chown kaiyuan:kaiyuan instance.properties
	service core-encryption start
elif [[ "$SERVICE" == "transaction" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_TRANSACTION_MONGO_DBNAME $CORE_TRANSACTION_MONGO_USER $CORE_TRANSACTION_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_TRANSACTION_MYSQL_DBNAME $CORE_TRANSACTION_MYSQL_USER $CORE_TRANSACTION_MYSQL_PASS
	sed -i "s/^component\.tx\.this=.*/component\.tx\.this=$myip:$PORT_TRANSACTION/"  instance.properties
	insertOtherInstanceIP "tx" "$PORT_TRANSACTION" "$transaction_ip1"
	chown kaiyuan:kaiyuan instance.properties
	configureTransactionSchedulers
	configureRabbitMQParameters
	configureExtRabbitMQParameters
	configureRabbitMQGenericParameters
	service core-transaction start
elif [[ "$SERVICE" == "backend" ]]; then
	addConfigToDbFile "mongo" $MONGOS_SERVER $CORE_BACKEND_MONGO_DBNAME $CORE_BACKEND_MONGO_USER $CORE_BACKEND_MONGO_PASS
	addConfigToDbFile "mysql" $MYSQL_SERVER $CORE_BACKEND_MYSQL_DBNAME $CORE_BACKEND_MYSQL_USER $CORE_BACKEND_MYSQL_PASS
	sed -i "s/^component\.backend\.this=.*/component\.backend\.this=$myip:$PORT_BACKEND/"  instance.properties
	insertOtherInstanceIP "backend" "$PORT_BACKEND" "$backend_ip1"
	chown kaiyuan:kaiyuan instance.properties
	service core-backend start
fi

elif [ $TYPE == "api" ]; then

##########Installing new service##########
installRPM "api-$SERVICE-$PLATFORM_MAJOR_VERSION$RPM_VERSION"
installZabbixSender

##########Configuring new service##########
logMessageToFile "INFO"  "Configuring api-$SERVICE-$PLATFORM_MAJOR_VERSION$RPM_VERSION"
cd /opt/ky/api-$SERVICE/*$SERVICE-*/conf/
configCoreFileForAPI

##########Configuring new service##########
if [[ "$SERVICE" == "user" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_USER
	service api-user start
elif [[ "$SERVICE" == "banking" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_BANKING
	service api-banking start
elif [[ "$SERVICE" == "company" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_COMPANY
	service api-company start
elif [[ "$SERVICE" == "search" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_SEARCH
	configureSolrParameters
	service api-search start
elif [[ "$SERVICE" == "support" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_SUPPORT
	configureSwiftParameters
	service api-support start
elif [[ "$SERVICE" == "auth" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_AUTH
	configureSwiftParameters
	service api-auth start
elif [[ "$SERVICE" == "transaction" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_TRANSACTION
	service api-transaction start
elif [[ "$SERVICE" == "backend" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_BACKEND
	service api-backend start
elif [[ "$SERVICE" == "basp" ]]; then
	insertHealthCheckScript $PORT_HTTP_API_BASP
	service api-basp start
fi
fi

cd $PWD_DIR
rm -f nova_instances.tmp

installAndConfigureZabbix
startZabbix

configureLogsCollector

formExecutionTime

logMessageToFile "INFO"  "Instance was installed and configured successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"
