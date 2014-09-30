#!/bin/bash

SERVICE=$1

##########Server confi paramters##########
PRIVATE_KEY_FILE='keys.dat'
PORT_USER=10001
PORT_COMPANY=11001
PORT_BANKING=12001
PORT_MESSAGING=13001
PORT_FILE=14001
PORT_ENCRYPTION=17001
PORT_ENGINE=18001
PORT_TRANSACTION=19001

REDIS_HOST='localhost'
REDIS_PORT=6379

#Ethernet inferface
DEFAULT_ETH=1

##########MYSQL config parameters##########
MYSQL_SERVER='127.0.0.1'
MYSQL_PORT='3306'
MYSQL_USERNAME='platform'
MYSQL_PASSWORD='platform'
MYSQL_DB_NAME='che001'

##########MONGO config parameters##########
MONGO_SERVER='127.0.0.1'
MONGO_PORT='27017'
MONGO_USERNAME='platform'
MONGO_PASSWORD='platform'
MONGO_DB_NAME='che001'

##########SOLR config parameters##########
SOLR_SERVER='localhost'
SOLR_PORT='8090'

##########RABBITMQ config parameters##########
RABBITMQ_SERVER='localhost'
RABBITMQ_PORT='5672'

##########LOCAL REPO config parameters##########
LOCAL_REPO='192.168.150.253'

##########Check for proper input parameters##########
if [[ -z "$1" ]]; then
	echo "Usage: ./configure_server.sh SERVICE (api-user/core-user)"
	exit 1;
fi

##########Saving current path##########
PWD=`pwd`

##########Extracting subservice string##########
SUBSERVICE=$(echo $SERVICE | awk -F'-' {'print $2}')

##########Function for finding current host ip's in OpenStack environment##########
function findMyIP {
	myip=$(ifconfig | grep inet  | grep Bcast | grep Mask  | awk '{print $2}' | awk -F":" 'BEGIN {count=0;} END {if ( count == DEFAULT_ETH ) print $2 ; count++; }')
}

##########Getting curent host ip##########
findMyIP
 
function configCoreFile(){
if [[ $SERVICE =~ "api"* ]]; then
	echo '
ky.api.common.redis.host='$REDIS_HOST'
ky.api.common.redis.port='$REDIS_PORT'' >> core.properties
fi
if [ ! -f 'core.properties' ]; then
	return 1
fi

sed 's/component.user.*/component.user = ["'$myip':'$PORT_USER'"]/' -i core.properties
sed 's/component.messaging.*/component.messaging =["'$myip':'$PORT_MESSAGING'"]/' -i core.properties
sed 's/component.banking.*/component.banking = ["'$myip':'$PORT_BANKING'"]/' -i core.properties
sed 's/component.company.*/component.company = ["'$myip':'$PORT_COMPANY'"]/' -i core.properties
sed 's/component.file.*/component.file =["'$myip':'$PORT_FILE'"]/' -i core.properties
sed 's/component.engine.*/component.engine =["'$myip':'$PORT_ENGINE'"]/' -i core.properties
sed 's/component.tx.*/component.tx = ["'$myip':'$PORT_TRANSACTION'"]/' -i core.properties

}

##########Core services##########
if [[ $SERVICE =~ "core"* ]]; then

##########Removing old version of service and cleaning repository##########
echo 'Removing old core-'$SUBSERVICE' package ...'
service "core-"$SUBSERVICE stop
yum --disablerepo="*" --enablerepo="LocalRepo" remove -y "deploy-core-"$SUBSERVICE
sleep 1
echo 'Cleaning repositories ...'
yum clean all
sleep 1

##########Installing last RPM buld of service##########
echo 'Instaling service core-'$SUBSERVICE' ...'
yum --disablerepo="*" --enablerepo="LocalRepo" install -y "deploy-core-"$SUBSERVICE
echo 'Configuring service core-'$SUBSERVICE' ...'
cd /opt/ky/core-$SUBSERVICE/deploy-core-$SUBSERVICE-*/conf/
configCoreFile

##########Configuring db file##########
echo 'ky.core.common.mysql.connection.string=jdbc:mysql://'$MYSQL_SERVER':'$MYSQL_PORT'/'$MYSQL_DB_NAME'
ky.core.common.mysql.username='$MYSQL_USERNAME'
ky.core.common.mysql.password='$MYSQL_PASSWORD'

ky.core.common.mongo.host.address='$MONGO_SERVER'
ky.core.common.mongo.host.port='$MONGO_PORT'
ky.core.common.mongo.db.name='$MONGO_DB_NAME'
ky.core.common.mongo.db.username='$MONGO_USERNAME'
ky.core.common.mongo.db.password='$MONGO_PASSWORD'' > db.properties


##########Configuring service##########
if [[ "$SUBSERVICE" == "user" ]]; then
	
	sed -i "s/^component\.user\.this=.*/component\.user\.this=$myip:$PORT_USER/"  instance.properties 

elif [[ "$SUBSERVICE" == "banking" ]]; then
sed -i "s/^component\.banking\.this=.*/component\.banking\.this=$myip:$PORT_BANKING/"  instance.properties
	
elif [[ "$SUBSERVICE" == "company" ]]; then
	sed -i "s/^component\.company\.this=.*/component\.company\.this=$myip:$PORT_COMPANY/"  instance.properties 
	echo '
ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> instance.properties

elif [[ "$SUBSERVICE" == "engine" ]]; then
	sed -i "s/^component\.engine\.this=.*/component\.engine\.this=$myip:$PORT_ENGINE/"  instance.properties 
echo '
ky.core.common.rabbitmq.server.port='$RABBITMQ_PORT'
ky.core.common.rabbitmq.server.host='$RABBITMQ_SERVER'' >> instance.properties
		
elif [[ "$SUBSERVICE" == "file" ]]; then
	sed -i "s/^component\.file\.this=.*/component\.file\.this=$myip:$PORT_FILE/"  instance.properties 
elif [[ "$SUBSERVICE" == "messaging" ]]; then
	sed -i "s/^component\.messaging\.this=.*/component\.messaging\.this=$myip:$PORT_MESSAGING/"  instance.properties 
elif [[ "$SUBSERVICE" == "encryption" ]]; then
	sed -i "s/^component\.encryptionservice\.this=.*/component\.encryptionservice\.this=$myip:$PORT_ENCRYPTION/"  instance.properties 
	sed -i "s/^enc\.service\.private\.key\.file=.*/enc\.service\.private\.key\.file=$PRIVATE_KEY_FILE/"  instance.properties 
elif [[ "$SUBSERVICE" == "transaction" ]]; then
	sed -i "s/^component\.tx\.this=.*/component\.tx\.this=$myip:$PORT_TRANSACTION/"  instance.properties 
fi

elif [[ $SERVICE =~ "api"* ]]; then

##########Removing old version of service and cleaning repository##########
echo 'Removing old api-'$SUBSERVICE' package ...'
service "api-"$SUBSERVICE stop
yum --disablerepo="*" --enablerepo="LocalRepo" remove -y "api-"$SUBSERVICE
sleep 1
echo 'Cleaning repositories ...'
yum clean all
sleep 1

##########Installing last RPM buld of service##########
echo 'Instaling service '$SERVICE' ...'
yum --disablerepo="*" --enablerepo="LocalRepo" install -y $SERVICE
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

elif [[ "$SUBSERVICE" == "auth" ]]; then
	configCoreFile
elif [[ "$SUBSERVICE" == "transaction" ]]; then
	configCoreFile
fi
fi

cd $PWD
echo "Done..."