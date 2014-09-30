#!/bin/bash

SERVICE=$1
. config.conf

##########Check of input parameters##########
# if [ -z "$1" ]; then
	# echo "Usage: ./configure_core-instance.sh core-SERVICE "
	# exit 1;
# fi

##########Check and configure `nova` command##########
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

##########Saving current directory path##########
PWD_DIR=$(pwd)

##########Save nova available instances in temporary file##########
nova list > nova_instances.tmp

##########If no input parameter use hostname as service##########
if [ -z "$1" ]; then
	SERVICE=`hostname | awk -F"-" '{print $2}'`
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

##########Functions searching for 1(2) core instances to connect##########
function find1stip (){
echo $(grep -i "ACTIVE" $PWD_DIR/nova_instances.tmp | grep -i RUNNING | grep -i $1  | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>2) exit }')
}
function find2ndip (){
echo $(grep -i "ACTIVE" $PWD_DIR/nova_instances.tmp | grep -i RUNNING | grep -i $1  | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==1 ) print $1 ; count++; if(count>2) exit }')
}
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

##########Functions which are adding one config line (core-service) to core.properties file##########
function addCoreUserInstanceToConfig {
if [ -z "$user_ip2" ]; then
	echo 'component.user = ["'$user_ip1':'$PORT_USER'"]' >> core.properties
	elif [ -z "$user_ip1" ]; then
		echo "Could not find api instance! Service not configured!"
		exit 1:
	else
		echo 'component.user = ["'$user_ip1':'$PORT_USER'","'$user_ip2':'$PORT_USER'"]' >> core.properties
fi
}
function addCoreCompanyInstanceToConfig {
if [ -z "$company_ip2" ]; then
	echo 'component.company = ["'$company_ip1':'$PORT_COMPANY'"]' >> core.properties
	elif [ -z "$company_ip1" ]; then
		echo "Could not find api instance! Service not configured!"
		exit 1:
	else
		echo 'component.company = ["'$company_ip1':'$PORT_COMPANY'","'$company_ip2':'$PORT_COMPANY'"]' >> core.properties
	fi
}
function addCoreBankingInstanceToConfig {
if [ -z "$banking_ip2" ]; then
	echo 'component.banking = ["'$banking_ip1':'$PORT_BANKING'"]' >> core.properties
	elif [ -z "$banking_ip1" ]; then
		echo "Could not find api instance! Service not configured!"
		exit 1:
	else
		echo 'component.banking = ["'$banking_ip1':'$PORT_BANKING'","'$banking_ip2':'$PORT_BANKING'"]' >> core.properties
	fi
}
function addCoreMessagingInstanceToConfig {
if [ -z "$messaging_ip2" ]; then
	echo 'component.messaging = ["'$messaging_ip1':'$PORT_MESSAGING'"]' >> core.properties
	elif [ -z "$messaging_ip1" ]; then
		echo "Could not find api instance! Service not configured!"
		exit 1:
	else
		echo 'component.messaging = ["'$messaging_ip1':'$PORT_MESSAGING'","'$messaging_ip2':'$PORT_MESSAGING'"]' >> core.properties
	fi
}

function addCoreFileInstanceToConfig {
if [ -z "$file_ip2" ]; then
	echo 'component.file = ["'$file_ip1':'$PORT_FILE'"]' >> core.properties
	elif [ -z "$file_ip1" ]; then
		echo "Could not find api instance! Service not configured!"
		exit 1:
	else
		echo 'component.file = ["'$file_ip1':'$PORT_FILE'","'$file_ip2':'$PORT_FILE'"]' >> core.properties
	fi
}

function addCoreEngineInstanceToConfig {
if [ -z "$engine_ip2" ]; then
	echo 'component.engine = ["'$engine_ip1':'$PORT_ENGINE'"]' >> core.properties
	elif [ -z "$engine_ip1" ]; then
		echo "Could not find api instance! Service not configured!"
		exit 1:
	else
		echo 'component.engine = ["'$engine_ip1':'$PORT_ENGINE'","'$engine_ip2':'$PORT_ENGINE'"]' >> core.properties
	fi
}

##########Cleaning old packages##########
echo 'Removing old api-'$SERVICE' package ...'
yum --disablerepo="*" --enablerepo="LocalRepo" remove -y "api-"$SERVICE
sleep 1

##########Installing new service##########
echo 'Instaling service api-'$SERVICE' ...'
yum --disablerepo="*" --enablerepo="LocalRepo" install -y "api-"$SERVICE
rm -f /opt/ky/api-$SERVICE/$SERVICE-*/conf/core.properties 
echo 'Configuring service api-'$SERVICE' ...'
cd /opt/ky/api-$SERVICE/$SERVICE-*/conf/

##########Configuring new service##########
if [[ "$SERVICE" == "user" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	service api-user start
elif [[ "$SERVICE" == "banking" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreCompanyInstanceToConfig
	addCoreBankingInstanceToConfig
	addCoreMessagingInstanceToConfig
	addCoreFileInstanceToConfig
	addCoreEngineInstanceToConfig
	service api-banking start
elif [[ "$SERVICE" == "company" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreCompanyInstanceToConfig
	addCoreBankingInstanceToConfig
	addCoreMessagingInstanceToConfig
	addCoreFileInstanceToConfig
	service api-company start
elif [[ "$SERVICE" == "search" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreCompanyInstanceToConfig
	addCoreBankingInstanceToConfig
	addCoreMessagingInstanceToConfig
	addCoreFileInstanceToConfig
	echo 'ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> core.properties
	service api-search start

elif [[ "$SERVICE" == "support" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	addCoreCompanyInstanceToConfig
	addCoreBankingInstanceToConfig
	addCoreMessagingInstanceToConfig
	addCoreFileInstanceToConfig
	addCoreEngineInstanceToConfig
	service api-support start
elif [[ "$SERVICE" == "auth" ]]; then
	findAvailablesIpsForCores
	addCoreUserInstanceToConfig
	service api-auth start
fi
rm -f nova_instances.tmp
cd $PWD_DIR
echo "Done..."
