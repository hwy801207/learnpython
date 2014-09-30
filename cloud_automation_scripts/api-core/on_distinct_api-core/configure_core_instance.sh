#!/bin/bash

SERVICE=$1
. config.conf

##########Check of input parameters##########
# if [ -z "$1" ]; then
	# echo "Usage: ./configure_core-instance.sh core-SERVICE "
	# exit 1;
# fi

##########Check and configure `nova` command ##########
if  which nova >/dev/null  2>&1 ; then
		echo 'Nova is installed';
	else
		if  which pip &>/dev/null 2>&1; then
			echo 'Python-pip is installed... Installing novaclient ...';
			pip install python-novaclient
		else
			echo "Installing python-pip and novaclient ..."
			yum install -y python-pip	
			pip install python-novaclient
		fi
fi


##########Check and configure LocalRepository##########
if [ ! -f /etc/yum.repos.d/localrepo.repo ];then
echo 'Configuring local repository ...'
echo '[LocalRepo]
name=KY-Local-Repo
baseurl=http://'$LOCAL_REPO'/rpmrepo
enabled=1
gpgcheck=0' > /etc/yum.repos.d/localrepo.repo
chmod 644 /etc/yum.repos.d/localrepo.repo
sleep 1
echo 'Cleaning repositories ...'
yum clean all
fi

##########If no input parameter use hostname as service##########
if [ -z "$1" ]; then
	SERVICE=`hostname | awk -F"-" '{print $2}'`
fi

##########Saving current directory path##########
PWD_DIR=$(pwd)

##########Save nova available instances in temporary file##########
nova list > nova_instances.tmp

##########Functions searching for 1st(2nd) core instances to connect##########
function find1stip (){
echo $(grep -i "ACTIVE" $PWD_DIR/nova_instances.tmp | grep -i RUNNING | grep -i $1  | grep -vi `hostname` | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>2) exit }')
}
function find2ndip (){
echo $(grep -i "ACTIVE" $PWD_DIR/nova_instances.tmp | grep -i RUNNING | grep -i $1  | grep -vi `hostname` | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==1 ) print $1 ; count++; if(count>2) exit }')
}
##########Function to extract ip of core instances to connect##########
function findAvailablesIpsForCores {
	user_ip1=$(find1stip $CORE_USER)
	user_ip2=$(find2ndip $CORE_USER)
	company_ip1=$(find1stip $CORE_COMPANY)
	company_ip2=$(find2ndip $CORE_COMPANY)
	banking_ip1=$(find1stip $CORE_BANKING)
	banking_ip2=$(find2ndip $CORE_BANKING)
	engine_ip1=$(find1stip $CORE_ENGINE)
	engine_ip2=$(find2ndip $CORE_ENGINE)
	messaging_ip1=$(find1stip $CORE_MESSAGING)
	messaging_ip2=$(find2ndip $CORE_MESSAGING)
	file_ip1=$(find1stip $CORE_FILE)
	file_ip2=$(find2ndip $CORE_FILE)
	encryption_ip1=$(find1stip $CORE_ENCRYPTION)
	encryption_ip2=$(find2ndip $CORE_ENCRYPTION)
} 
##########Function for finding current host ip's in OpenStack environment##########
function findMyIP {
	myip=$(nova list | grep -i `hostname` | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{ print $1; exit }')
} 
##########Functions which are adding one config line (core-service) to core.properties file##########
function addCoreUserInstanceToConfig {
if [ -z "$user_ip2" ]; then
	if [ -z "$user_ip1" ]; then
		if [ $SERVICE == "user" ]; then
			echo 'component.user = ["'$myip':'$PORT_USER'"]' >> core.properties
		else
			echo "Could not find core-user instance! Service not configured!"
			exit 1;
		fi
	else
		echo 'component.user = ["'$user_ip1':'$PORT_USER'"]' >> core.properties
	fi
else
	echo 'component.user = ["'$user_ip1':'$PORT_USER'","'$user_ip2':'$PORT_USER'"]' >> core.properties
fi
}
function addCoreCompanyInstanceToConfig {
if [ -z "$company_ip2" ]; then
	if [ -z "$company_ip1" ]; then
		if [ $SERVICE == "company" ]; then
			echo 'component.company = ["'$myip':'$PORT_COMPANY'"]' >> core.properties
		else
			echo "Could not find core-company instance! Service not configured!"
			exit 1;
		fi
	else
		echo 'component.company = ["'$company_ip1':'$PORT_COMPANY'"]' >> core.properties
	fi
else
	echo 'component.company = ["'$company_ip1':'$PORT_COMPANY'","'$company_ip2':'$PORT_COMPANY'"]' >> core.properties
fi
}
function addCoreBankingInstanceToConfig {
if [ -z "$banking_ip2" ]; then
	if [ -z "$banking_ip1" ]; then
		if [ $SERVICE == "banking" ]; then
			echo 'component.banking = ["'$myip':'$PORT_BANKING'"]' >> core.properties
		else
			echo "Could not find core-banking instance! Service not configured!"
			exit 1;
		fi
	else
		echo 'component.banking = ["'$banking_ip1':'$PORT_BANKING'"]' >> core.properties
	fi
else
	echo 'component.banking = ["'$banking_ip1':'$PORT_BANKING'","'$banking_ip2':'$PORT_BANKING'"]' >> core.properties
fi
}
function addCoreMessagingInstanceToConfig {
if [ -z "$messaging_ip2" ]; then
	if [ -z "$messaging_ip1" ]; then
		if [ $SERVICE == "messaging" ]; then
			echo 'component.messaging = ["'$myip':'$PORT_MESSAGING'"]' >> core.properties
		else
			echo "Could not find core-messaging instance! Service not configured!"
			exit 1;
		fi
	else
		echo 'component.messaging = ["'$messaging_ip1':'$PORT_MESSAGING'"]' >> core.properties
	fi
else
	echo 'component.messaging = ["'$messaging_ip1':'$PORT_MESSAGING'","'$messaging_ip2':'$PORT_MESSAGING'"]' >> core.properties
fi
}

function addCoreFileInstanceToConfig {
if [ -z "$file_ip2" ]; then
	if [ -z "$file_ip1" ]; then
		if [ $SERVICE == "file" ]; then
			echo 'component.file = ["'$myip':'$PORT_FILE'"]' >> core.properties
		else
			echo "Could not find core-file instance! Service not configured!"
			exit 1;
		fi
	else
		echo 'component.file = ["'$file_ip1':'$PORT_FILE'"]' >> core.properties
	fi
else
	echo 'component.file = ["'$file_ip1':'$PORT_FILE'","'$file_ip2':'$PORT_FILE'"]' >> core.properties
fi
}
function addCoreEngineInstanceToConfig {
if [ -z "$engine_ip2" ]; then
	if [ -z "$engine_ip1" ]; then
		if [ $SERVICE == "engine" ]; then
			echo 'component.file = ["'$myip':'$PORT_ENGINE'"]' >> core.properties
		else
			echo "Could not find core-engine instance! Service not configured!"
			exit 1;
		fi
	else
		echo 'component.engine = ["'$engine_ip1':'$PORT_ENGINE'"]' >> core.properties
	fi
else
	echo 'component.engine = ["'$engine_ip1':'$PORT_ENGINE'","'$engine_ip2':'$PORT_ENGINE'"]' >> core.properties
fi
}

##########Getting curent host ip##########
 findMyIP

##########If host or current ip not found exit##########
if [ -z "$myip" ]; then
	echo "Could not get your ip for the specified host $(hostname)... $SERVICE not installed! "
	exit 1;
fi
if [ -z "$(hostname)" ]; then
	echo "Could not get your hostname... $SERVICE not installed! "
	exit 1;
fi

##########Adding hostname in hosts##########
if grep -q `hostname` /etc/hosts; then
		echo "Host is already configured!"
	else
		echo "Configuring host ..."
		echo $myip " " `hostname` >> /etc/hosts
fi
if grep `hostname` /etc/hosts >/dev/null; then
echo "Successfully configure host property"
else
echo "Could not set host property in hosts file !"
exit 1;
fi

##########Cleaning old packages##########
echo 'Removing old core-'$SERVICE' package ...'
yum --disablerepo="*" --enablerepo="LocalRepo" remove -y "deploy-core-"$SERVICE
sleep 1
echo 'Cleaning repositories ...'
yum clean all
sleep 1

##########Installing new service##########
echo 'Instaling service core-'$SERVICE' ...'
yum --disablerepo="*" --enablerepo="LocalRepo" install -y "deploy-core-"$SERVICE
rm -f /opt/ky/core-$SERVICE/deploy-core-$SERVICE-*/conf/core.properties  /opt/ky/core-$SERVICE/deploy-core-$SERVICE-*/conf/db.properties
echo 'Configuring service core-'$SERVICE' ...'
cd /opt/ky/core-$SERVICE/deploy-core-$SERVICE-*/conf/

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

##########Configuring new service##########
if [[ "$SERVICE" == "user" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreMessagingInstanceToConfig
	sed -i "s/^component\.user\.this=.*/component\.user\.this=$(hostname):$PORT_USER/"  instance.properties 
	service core-user start		
elif [[ "$SERVICE" == "banking" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreBankingInstanceToConfig
	addCoreMessagingInstanceToConfig
	sed -i "s/^component\.banking\.this=.*/component\.banking\.this=$(hostname):$PORT_BANKING/"  instance.properties 
	service core-banking start
elif [[ "$SERVICE" == "company" ]]; then
	sed -i "s/^component\.company\.this=.*/component\.company\.this=$(hostname):$PORT_COMPANY/"  instance.properties 
	echo '
ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> instance.properties
	service core-company start
elif [[ "$SERVICE" == "engine" ]]; then
	findAvailablesIpsForCores
	addCoreCompanyInstanceToConfig
sed -i "s/^component\.engine\.this=.*/component\.engine\.this=$(hostname):$PORT_ENGINE/"  instance.properties 
echo '
ky.core.common.rabbitmq.server.port='$RABBITMQ_PORT'
ky.core.common.rabbitmq.server.host='$RABBITMQ_SERVER'' >> instance.properties
	service core-engine start
elif [[ "$SERVICE" == "file" ]]; then
	sed -i "s/^component\.file\.this=.*/component\.file\.this=$(hostname):$PORT_FILE/"  instance.properties 
elif [[ "$SERVICE" == "messaging" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreMessagingInstanceToConfig
echo '
	ky.core.common.user.register.confirm=false' >>core.properties
sed -i "s/^component\.messaging\.this=.*/component\.messaging\.this=$(hostname):$PORT_MESSAGING/"  instance.properties 
	service core-messaging start
elif [[ "$SERVICE" == "encryption" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreMessagingInstanceToConfig
	sed -i "s/^component\.encryptionservice\.this=.*/component\.encryptionservice\.this=$(hostname):$PORT_ENCRYPTION/"  instance.properties 
	sed -i "s/^enc\.service\.private\.key\.file=.*/enc\.service\.private\.key\.file=$PRIVATE_KEY_FILE/"  instance.properties 
	service core-encryption start
fi

cd $PWD_DIR
echo "Done..."