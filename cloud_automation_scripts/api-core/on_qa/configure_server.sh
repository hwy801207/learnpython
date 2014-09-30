#!/bin/bash

SERVICE=$1

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########Check for proper input parameters##########
if [[ -z "$1" ]]; then
	echo "Usage: ./configure_server.sh SERVICE (api-user/core-user)"
	exit 1;
fi

if [ ! -z "$2" ]; then
	BUILD_NO='-0.0.'$2
fi

. parameters
configureLocalRepo

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
echo '
ky.-.common.redis.host='$REDIS_HOST'
ky.-.common.redis.port='$REDIS_PORT'' >> core.properties
}

function configCoreFile(){
configureRedisParameters

if [ ! -f 'core.properties' ]; then
	return 1
fi

sed 's/component.user.*/component.user = ["localhost:'$PORT_USER'"]/' -i core.properties
sed 's/component.messaging.*/component.messaging =["localhost:'$PORT_MESSAGING'"]/' -i core.properties
sed 's/component.banking.*/component.banking = ["localhost:'$PORT_BANKING'"]/' -i core.properties
sed 's/component.company.*/component.company = ["localhost:'$PORT_COMPANY'"]/' -i core.properties
sed 's/component.file.*/component.file =["localhost:'$PORT_FILE'"]/' -i core.properties
sed 's/component.engine.*/component.engine =["localhost:'$PORT_ENGINE'"]/' -i core.properties
sed 's/component.tx.*/component.tx = ["localhost:'$PORT_TRANSACTION'"]/' -i core.properties
sed 's/component.backend.*/component.backend = ["localhost:'$PORT_BACKEND'"]/' -i core.properties

}


##########Core services##########
if [[ $SERVICE =~ "core"* ]]; then

echo "########################## START install of deploy-core-$SUBSERVICE$BUILD_NO ##########################"

##########Removing old version of service and cleaning repository##########
uninstallService "deploy-core-"$SUBSERVICE

##########Installing last RPM buld of service##########
installService "deploy-core-"$SUBSERVICE$BUILD_NO
if [ "$?" == "4" ]; then
exit 1
fi

echo 'Configuring service core-'$SUBSERVICE' ...'
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
	
	sed -i "s/^component\.user\.this=.*/component\.user\.this=localhost:$PORT_USER/"  instance.properties 
elif [[ "$SUBSERVICE" == "banking" ]]; then
	sed -i "s/^component\.banking\.this=.*/component\.banking\.this=localhost:$PORT_BANKING/"  instance.properties
	configureBASPParameters
	configureRabbitMQParameters
elif [[ "$SUBSERVICE" == "company" ]]; then
	sed -i "s/^component\.company\.this=.*/component\.company\.this=localhost:$PORT_COMPANY/"  instance.properties 
	echo '
ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> instance.properties

elif [[ "$SUBSERVICE" == "engine" ]]; then
	sed -i "s/^component\.engine\.this=.*/component\.engine\.this=localhost:$PORT_ENGINE/"  instance.properties 
	echo '
ky.core.common.task.queue.name='$(hostname)'' >> instance.properties
	configureRabbitMQParameters
	configureExtRabbitMQParameters
	configureSwiftParameters
		
elif [[ "$SUBSERVICE" == "file" ]]; then
	sed -i "s/^component\.file\.this=.*/component\.file\.this=localhost:$PORT_FILE/"  instance.properties 
	configureSwiftParameters
elif [[ "$SUBSERVICE" == "messaging" ]]; then
	configureRedisParameters
	sed -i "s/^component\.messaging\.this=.*/component\.messaging\.this=localhost:$PORT_MESSAGING/"  instance.properties 
		echo '
ky.core.common.confirmation.id.user.name = true' >> core.properties
	echo $BASE_URL > url.properties
	echo "$MAIL_PROPERTIES" > mail.properties
	configureRabbitMQParameters
elif [[ "$SUBSERVICE" == "encryption" ]]; then
	sed -i "s/^component\.encryption\.this=.*/component\.encryption\.this=localhost:$PORT_ENCRYPTION/"  instance.properties 
	sed -i "s/^enc\.service\.private\.key\.file=.*/enc\.service\.private\.key\.file=$PRIVATE_KEY_FILE/"  instance.properties 
elif [[ "$SUBSERVICE" == "transaction" ]]; then
	sed -i "s/^component\.tx\.this=.*/component\.tx\.this=localhost:$PORT_TRANSACTION/"  instance.properties 
	configureRabbitMQParameters
	configureExtRabbitMQParameters
elif [[ "$SUBSERVICE" == "backend" ]]; then
	sed -i "s/^component\.backend\.this=.*/component\.backend\.this=localhost:$PORT_BACKEND/"  instance.properties 
fi

elif [[ $SERVICE =~ "api"* ]]; then

echo "########################## START install of $SERVICE$BUILD_NO ##########################"

##########Removing old version of service and cleaning repository##########
uninstallService "api-"$SUBSERVICE

##########Installing last RPM buld of service##########
installService $SERVICE$BUILD_NO
if [ "$?" == "4" ]; then
exit 1
fi

echo 'Configuring service '$SERVICE' ...'
cd /opt/ky/$SERVICE/$SUBSERVICE-*/conf/

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
fi
fi

cd $PWD
echo "########################## DONE ##########################"