#!/bin/bash

SERVICE=$1

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########Check for proper input parameters##########
if [ -z "$1" -o -z "$2" ]; then
	echo "Usage: ex.
		$0 api-user 0.1.1554
		"
	exit 1;
fi

BUILD_NO="-$2"

. parameters
configureLocalRepo


APACHE_BASP_EXISTED=$(rpm -qa apache-basp)

findMyIP
PLATFORM_HOST="$myip"

##########Saving current path##########
PWD=`pwd`

##########Extracting subservice string##########
SUBSERVICE=$(echo $SERVICE | awk -F'-' {'print $2}')

function configureRabbitMQParameters(){
echo '
ky.core.common.rabbitmq.recovery.automatic=true
ky.core.common.rabbitmq.recovery.manual=true
ky.core.common.rabbitmq.recovery.interval=5000
ky.core.common.rabbitmq.recovery.push.interval=2000
ky.core.common.rabbitmq.recovery.count=3
ky.core.common.rabbitmq.recovery.sleep=15
ky.core.common.rabbitmq.server.hosts='$RABBITMQ_SERVER':'$RABBITMQ_PORT'
ky.core.common.rabbitmq.username='$RABBITMQ_USER'
ky.core.common.rabbitmq.password='$RABBITMQ_PASSWD'' >> core.properties
}

function configureExtRabbitMQParameters(){
echo '
ky.core.common.ext.rabbitmq.server.hosts='$RABBITMQ_EXT_SERVER':'$RABBITMQ_EXT_PORT'
ky.core.common.ext.rabbitmq.username='$RABBITMQ_EXT_USER'
ky.core.common.ext.rabbitmq.password='$RABBITMQ_EXT_PASSWD'' >> core.properties
}


function configureSwiftParameters(){
	echo '
ky.binary.common.swift.endpoint='$SWIFT_ENDPOINT'
ky.binary.common.swift.username='$SWIFT_USERNAME'
ky.binary.common.swift.password='$SWIFT_PASS'
ky.binary.common.swift.tenant.name='$SWIFT_TENANT'' >> core.properties
}

function configureRedisParameters(){
echo "
ky.-.common.redis.sentinels=$REDIS_HOST_1:$REDIS_SENTINEL_PORT;$REDIS_HOST_2:$REDIS_SENTINEL_PORT;$REDIS_HOST_3:$REDIS_SENTINEL_PORT" >> core.properties
}

function configCoreFile(){
configureRedisParameters



if [ ! -f 'core.properties' ]; then
	return 1
fi

sed 's/component.user.*/component.user = ["'$PLATFORM_HOST':'$PORT_USER'"]/' -i core.properties
sed 's/component.messaging.*/component.messaging =["'$PLATFORM_HOST':'$PORT_MESSAGING'"]/' -i core.properties
sed 's/component.banking.*/component.banking = ["'$PLATFORM_HOST':'$PORT_BANKING'"]/' -i core.properties
sed 's/component.company.*/component.company = ["'$PLATFORM_HOST':'$PORT_COMPANY'"]/' -i core.properties
sed 's/component.file.*/component.file =["'$PLATFORM_HOST':'$PORT_FILE'"]/' -i core.properties
sed 's/component.engine.*/component.engine =["'$PLATFORM_HOST':'$PORT_ENGINE'"]/' -i core.properties
sed 's/component.tx.*/component.tx = ["'$PLATFORM_HOST':'$PORT_TRANSACTION'"]/' -i core.properties
sed 's/component.backend.*/component.backend = ["'$PLATFORM_HOST':'$PORT_BACKEND'"]/' -i core.properties
sed 's/component.encryption.*/component.encryption = ["'$PLATFORM_HOST':'$PORT_ENCRYPTION'"]/' -i core.properties

}

function configureScheduler(){
logMessageToConsole "INFO"  'configureScheduler'
SCHEDULER=$1
MINUTE_OF_DAY=$2
HOUR_OF_DAY=$3

cd /opt/ky/core-$SUBSERVICE/scheduler-$SCHEDULER-bee*/conf
configCoreFile
sed -i "s/localhost/$myip/"  instance.properties
cd /opt/ky/core-$SUBSERVICE/scheduler-$SCHEDULER-bee*/bin
SCHEDULER_RUN_PATH=`pwd`"/run.sh"
chmod 755 $SCHEDULER_RUN_PATH
sed '/scheduler-'$SCHEDULER'-bee/d' -i /etc/crontab
sed '/./!d' -i /etc/crontab
echo "$MINUTE_OF_DAY $HOUR_OF_DAY * * * root $SCHEDULER_RUN_PATH" >> /etc/crontab
}

function configuringBillingBee(){
logMessageToConsole "INFO"  'configuringBillingBee'
configureScheduler 'billing' '0' "$SCHEDULERS_HOUR_OF_DAY"
}

function configuringSettlerBee(){
logMessageToConsole "INFO"  'configuringSettlerBee'
configureScheduler 'settler' '10' "$SCHEDULERS_HOUR_OF_DAY"
}

function configuringConfirmedBee(){
logMessageToConsole "INFO"  'configuringConfirmedBee'
configureScheduler 'confirmed' '20' "$SCHEDULERS_HOUR_OF_DAY"
}

function configureBankingSchedulers(){
logMessageToConsole "INFO"  'configureBankingSchedulers'
CURRENT_DIR=`pwd`
configuringBillingBee
configuringSettlerBee
configuringConfirmedBee
cd $CURRENT_DIR
}

function configuringUserUnlockBee(){
logMessageToConsole "INFO"  'configuringUserUnlock'
configureScheduler 'userunlock' '30'
}

function configureUserSchedulers(){
logMessageToConsole "INFO"  'configureUserSchedulers'
CURRENT_DIR=`pwd`
configuringUserUnlockBee
cd $CURRENT_DIR
}

function configuringCancelBee(){
logMessageToConsole "INFO"  'configuringCancelBee'
configureScheduler 'cancel' '40' "$SCHEDULERS_HOUR_OF_DAY"
}

function configuringTransactionBee(){
logMessageToConsole "INFO"  'configuringTransactionBee'
configureScheduler 'transactions' '50' "$SCHEDULERS_HOUR_OF_DAY"
}

function configureTransactionSchedulers(){
logMessageToConsole "INFO"  'configureTransactionSchedulers'
CURRENT_DIR=`pwd`
configuringCancelBee
configuringTransactionBee
cd $CURRENT_DIR
}

##########Core services##########
if [[ $SERVICE =~ "core"* ]]; then

logMessageToConsole "INFO" "########################## START install of deploy-core-$SUBSERVICE$BUILD_NO ##########################"

##########Removing old version of service and cleaning repository##########
uninstallService "deploy-core-$SUBSERVICE"

##########Installing last RPM buld of service##########
installService "deploy-core-"$SUBSERVICE$BUILD_NO
if [ "$?" == "4" ]; then
exit 4
fi

logMessageToConsole "INFO" "Configuring service core-$SUBSERVICE ..."
cd /opt/ky/core-$SUBSERVICE/deploy-core-$SUBSERVICE-*/conf/

##########Configuring db file##########
echo 'ky.core.common.mysql.connection.string=jdbc:mysql://'$MYSQL_SERVER':'$MYSQL_PORT'/'$MYSQL_DB_NAME'
ky.core.common.mysql.username='$MYSQL_USERNAME'
ky.core.common.mysql.password='$MYSQL_PASSWORD'

ky.core.common.mongo.host.address='$MONGO_SERVER'
ky.core.common.mongo.host.port='$MONGO_PORT'
ky.core.common.mongo.db.name='$MONGO_DB_NAME'
ky.core.common.mongo.db.username='$MONGO_USERNAME'
ky.core.common.mongo.db.password='$MONGO_PASSWORD'' > db.properties

configCoreFile
##########Configuring service##########
if [[ "$SUBSERVICE" == "user" ]]; then
	
	sed -i "s/^component\.user\.this=.*/component\.user\.this=$PLATFORM_HOST:$PORT_USER/"  instance.properties 
	configureUserSchedulers
elif [[ "$SUBSERVICE" == "banking" ]]; then
	sed -i "s/^component\.banking\.this=.*/component\.banking\.this=$PLATFORM_HOST:$PORT_BANKING/"  instance.properties
	configureBASPParameters
	configureRabbitMQParameters
	configureBankingSchedulers
elif [[ "$SUBSERVICE" == "company" ]]; then
	sed -i "s/^component\.company\.this=.*/component\.company\.this=$PLATFORM_HOST:$PORT_COMPANY/"  instance.properties 
	echo '
ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> instance.properties

elif [[ "$SUBSERVICE" == "engine" ]]; then
	sed -i "s/^component\.engine\.this=.*/component\.engine\.this=$PLATFORM_HOST:$PORT_ENGINE/"  instance.properties 
echo '
ky.core.common.task.queue.name='$(hostname)'' >> instance.properties
configureRabbitMQParameters
configureExtRabbitMQParameters
configureSwiftParameters
		
elif [[ "$SUBSERVICE" == "file" ]]; then
	sed -i "s/^component\.file\.this=.*/component\.file\.this=$PLATFORM_HOST:$PORT_FILE/"  instance.properties 
	configureSwiftParameters
elif [[ "$SUBSERVICE" == "messaging" ]]; then
	configureRedisParameters
	sed -i "s/^component\.messaging\.this=.*/component\.messaging\.this=$PLATFORM_HOST:$PORT_MESSAGING/"  instance.properties
	configureRabbitMQParameters
	sed 's/base\.url.*/base\.url=http:\/\/'$WEBUI_IP'/' -i url.properties
elif [[ "$SUBSERVICE" == "encryption" ]]; then
	sed -i "s/^component\.encryption\.this=.*/component\.encryption\.this=$PLATFORM_HOST:$PORT_ENCRYPTION/"  instance.properties 
	sed -i "s/^enc\.service\.private\.key\.file=.*/enc\.service\.private\.key\.file=$PRIVATE_KEY_FILE/"  instance.properties 
elif [[ "$SUBSERVICE" == "transaction" ]]; then
	sed -i "s/^component\.tx\.this=.*/component\.tx\.this=$PLATFORM_HOST:$PORT_TRANSACTION/"  instance.properties
	echo "
ky.core.common.ky.core.messaging.sms=false" >> core.properties
	configureRabbitMQParameters
	configureExtRabbitMQParameters
	configureTransactionSchedulers
elif [[ "$SUBSERVICE" == "backend" ]]; then
	sed -i "s/^component\.backend\.this=.*/component\.backend\.this=$PLATFORM_HOST:$PORT_BACKEND/"  instance.properties 
	echo "ky.core.common.Create.normal.virafication.code=false" >> core.properties
fi

elif [[ $SERVICE =~ "api"* ]]; then

logMessageToConsole "INFO" "########################## START install of $SERVICE$BUILD_NO ##########################"

##########Removing old version of service and cleaning repository##########
uninstallService "api-"$SUBSERVICE

##########Installing last RPM buld of service##########
installService $SERVICE$BUILD_NO
if [ "$?" == "4" ]; then
exit 4
fi

logMessageToConsole "INFO" "Configuring service $SERVICE ..."
cd /opt/ky/$SERVICE/*$SUBSERVICE-*/conf/

##########Configuring service##########
if [[ "$SUBSERVICE" == "user" ]]; then
	configCoreFile
	
elif [[ "$SUBSERVICE" == "banking" ]]; then
	configCoreFile
		
elif [[ "$SUBSERVICE" == "company" ]]; then
	configCoreFile

elif [[ "$SUBSERVICE" == "search" ]]; then
	configCoreFile
	echo '
ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> core.properties
		
elif [[ "$SUBSERVICE" == "support" ]]; then
	configCoreFile
	configureSwiftParameters

elif [[ "$SUBSERVICE" == "auth" ]]; then
	configCoreFile
	configureSwiftParameters
elif [[ "$SUBSERVICE" == "transaction" ]]; then
	configCoreFile
elif [[ "$SUBSERVICE" == "backend" ]]; then
	configCoreFile
elif [[ "$SUBSERVICE" == "basp" ]]; then
	configCoreFile
	installAndConfigureApacheBASP $APACHE_BASP_EXISTED
fi
fi

cd $PWD
logMessageToConsole "INFO" "##########################DONE##########################"