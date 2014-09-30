#!/bin/bash

STARTTIME=$(date +%s)
SERVICE=$1

#DB configuration
MYSQL_SERVER='10.10.10.12'
MYSQL_PORT='3306'
MYSQL_USERNAME='platform'
MYSQL_PASSWORD='platform'
MYSQL_DB_NAME='che001'

MONGO_SERVER='10.10.10.32'
MONGO_PORT='27020'
MONGO_USERNAME='platform'
MONGO_PASSWORD='platform'
MONGO_DB_NAME='che001'

# PARAMETERS FILE
SWIFT_PARAM_FILE='config_params.sh'
SWIFT_FUNC_FILE='config_func.sh'
SWIFT_UTILS_CONTAINER='script_utils'

#OpenStack config
export OS_TENANT_NAME=admin
export OS_USERNAME=kycloud
export OS_PASSWORD=kycloud
export OS_AUTH_URL="http://192.168.150.98:5000/v2.0/"
export OS_AUTH_STRATEGY=keystone


##########Setting hostname to be persistent##########
echo `hostname` > /etc/hostname

##########Check and configure `nova` and `swift` commands ##########
if  which nova >/dev/null  2>&1 ; then
		echo 'Nova is installed' 
	else
		if  which pip &>/dev/null 2>&1; then
			echo 'Python-pip is installed... Installing novaclient ...' 
			pip install python-novaclient
		else
			echo "Installing python-pip and novaclient ..." 
			yum install -y python-pip	
			pip install python-novaclient
		fi
fi
if  which swift >/dev/null  2>&1 ; then
		echo 'Swift is installed' 
	else
		echo 'Installing swiftclient ...' 
		pip install python-swiftclient
fi

swift download $SWIFT_UTILS_CONTAINER $SWIFT_PARAM_FILE $SWIFT_FUNC_FILE
. $SWIFT_PARAM_FILE
. $SWIFT_FUNC_FILE

configureLocalRepo

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
	logMessageToFile "INFO"  "Could not get your ip for the specified host $(hostname)... $SERVICE not installed! "
	exit 1;
fi

##########Adding hostname in hosts##########
configureHostname

##########Saving current directory path##########
PWD_DIR=$(pwd)

##########Save nova available instances in temporary file##########
nova list > nova_instances.tmp

if [ $TYPE == "core" ]; then

##########Cleaning old packages##########
logMessageToFile "INFO"  'Removing old core-'$SERVICE' package ...' 
yum --disablerepo="*" --enablerepo="LocalRepo" remove -y "deploy-core-"$SERVICE
sleep 1
logMessageToFile "INFO"  'Cleaning repositories ...' 
yum clean all
sleep 1

##########Installing new service##########
logMessageToFile "INFO"  'Instaling service core-'$SERVICE' ...'
yum --disablerepo="*" --enablerepo="LocalRepo" install -y "deploy-core-"$SERVICE
rm -f /opt/ky/core-$SERVICE/deploy-core-$SERVICE-*/conf/db.properties

##########Configuring new service##########
logMessageToFile "INFO"  'Configuring service core-'$SERVICE' ...' 
cd /opt/ky/core-$SERVICE/deploy-core-$SERVICE-*/conf/
configCoreFile

##########Creating db file##########
echo '
ky.core.common.mysql.connection.string=jdbc:mysql://'$MYSQL_SERVER':'$MYSQL_PORT'/'$MYSQL_DB_NAME'
ky.core.common.mysql.username='$MYSQL_USERNAME'
ky.core.common.mysql.password='$MYSQL_PASSWORD'

ky.core.common.mongo.host.address='$MONGO_SERVER'
ky.core.common.mongo.host.port='$MONGO_PORT'
ky.core.common.mongo.db.name='$MONGO_DB_NAME'
ky.core.common.mongo.db.username='$MONGO_USERNAME'
ky.core.common.mongo.db.password='$MONGO_PASSWORD'' > db.properties

if [[ "$SERVICE" == "user" ]]; then
	sed -i "s/^component\.user\.this=.*/component\.user\.this=$myip:$PORT_USER/"  instance.properties 
	service core-user start		
elif [[ "$SERVICE" == "banking" ]]; then
	sed -i "s/^component\.banking\.this=.*/component\.banking\.this=$myip:$PORT_BANKING/"  instance.properties 
	service core-banking start
elif [[ "$SERVICE" == "company" ]]; then
	sed -i "s/^component\.company\.this=.*/component\.company\.this=$myip:$PORT_COMPANY/"  instance.properties 
	echo 'ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> instance.properties
	service core-company start
elif [[ "$SERVICE" == "engine" ]]; then
	sed -i "s/^component\.engine\.this=.*/component\.engine\.this=$myip:$PORT_ENGINE/"  instance.properties 
	echo '
ky.core.common.rabbitmq.server.port='$RABBITMQ_PORT'
ky.core.common.rabbitmq.server.host='$RABBITMQ_SERVER'' >> instance.properties
	service core-engine start
elif [[ "$SERVICE" == "file" ]]; then
	sed -i "s/^component\.file\.this=.*/component\.file\.this=$myip:$PORT_FILE/"  instance.properties 
	service core-file start
elif [[ "$SERVICE" == "messaging" ]]; then
	echo 'ky.core.common.user.register.confirm=false' >> core.properties
	sed -i "s/^component\.messaging\.this=.*/component\.messaging\.this=$myip:$PORT_MESSAGING/"  instance.properties 
	service core-messaging start
elif [[ "$SERVICE" == "encryption" ]]; then
	sed -i "s/^component\.encryptionservice\.this=.*/component\.encryptionservice\.this=$myip:$PORT_ENCRYPTION/"  instance.properties 
	sed -i "s/^enc\.service\.private\.key\.file=.*/enc\.service\.private\.key\.file=$PRIVATE_KEY_FILE/"  instance.properties 
	service core-encryption start
elif [[ "$SERVICE" == "transaction" ]]; then
	sed -i "s/^component\.tx\.this=.*/component\.tx\.this=$myip:$PORT_TRANSACTION/"  instance.properties 
	service core-transaction start
fi

elif [ $TYPE == "api" ]; then

##########Cleaning old packages##########
logMessageToFile "INFO"  'Removing old api-'$SERVICE' package ...'
yum --disablerepo="*" --enablerepo="LocalRepo" remove -y "api-"$SERVICE
sleep 1

##########Installing new service##########
logMessageToFile "INFO"  'Instaling service api-'$SERVICE' ...'
yum --disablerepo="*" --enablerepo="LocalRepo" install -y "api-"$SERVICE

##########Configuring new service##########
logMessageToFile "INFO"  'Configuring service api-'$SERVICE' ...'
cd /opt/ky/api-$SERVICE/$SERVICE-*/conf/
configCoreFileForAPI

if [[ "$SERVICE" == "user" ]]; then
	service api-user start
elif [[ "$SERVICE" == "banking" ]]; then
	service api-banking start
elif [[ "$SERVICE" == "company" ]]; then
	service api-company start
elif [[ "$SERVICE" == "search" ]]; then
	echo 'ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> core.properties
	service api-search start
elif [[ "$SERVICE" == "support" ]]; then
	service api-support start
elif [[ "$SERVICE" == "auth" ]]; then
	service api-auth start
elif [[ "$SERVICE" == "transaction" ]]; then
	service api-transaction start
fi
fi

cd $PWD_DIR
rm -f nova_instances.tmp

ENDTIME=$(date +%s)
ELAPSED_TIME=$(($ENDTIME - $STARTTIME))
HOURS_PASSED=$(($ELAPSED_TIME/$((60*60))))
MINUTES_PASSED=$(($(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))))/60))
SECONDS_PASSED=$(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))-$(($MINUTES_PASSED*60))))

logMessageToFile "INFO"  "Instance was installed and configured successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"