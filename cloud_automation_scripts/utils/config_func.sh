#!/bin/bash

function logMessageToFile(){
	echo '[ '$1' ] - ['$(date "+%Y-%m-%d %H:%M:%S")'] - '$2 >> $LOG_FILE
}

function logMessageToConsole(){
	echo '[ '$1' ] - ['$(date "+%Y-%m-%d %H:%M:%S")'] - '$2
}

function configreApplicationLogsDir(){
mkdir -p /mnt/ky/logs
ln -s /mnt/ky/logs /opt/ky/logs 
}

function configureSpecialRolesJson(){
logMessageToFile "INFO"  'configureSpecialRolesJson'
sed 's/\"parentId\":.*/\"parentId\": \"'$SPECIAL_ROLES_PARENT_ID'\",/' -i specialRoles.json
}

function downloadFromSwift(){
local container=$1
local file=$2
local output=$3
logMessageToFile "INFO" "Download from swift container: $container, file: $file to path: $output"

if [ -z "$container" -o -z "$file" -o -z "$output" ]; then
	logMessageToFile "ERROR" "Wrong input parameters to function: 1=$1, 2=$2, 3=$3"
	return 1
else
	swift download $container $file --output $output
fi

if [ ! -f "$output" ]; then
	logMessageToFile "ERROR" "Could not download from swift container: $container file: $file to path: $output"
fi
}

##########Function for addind kydev user##########
function addKydevUser(){
logMessageToFile "INFO"  'addKydevUser'
if ! grep -q kaiyuan /etc/group ; then 
	groupadd kaiyuan
fi
useradd -s /bin/bash -g kaiyuan $KYDEV_USER
echo $KYDEV_PASSWD | passwd $KYDEV_USER --stdin
id -u $KYDEV_USER
if [ "$?" -ne "0" ]; then
	logMessageToFile "ERROR" "user $KYDEV_USER has not been added."
else
	logMessageToFile "INFO" "User $KYDEV_USER has been succesfully added."
fi
}

function checkRPMWasInstalled(){
logMessageToFile "INFO"  'checkRPMWasInstalled'
RPM_TO_INSTALL=$1
RPM_INSTALLED=$(rpm -qa | grep $RPM_TO_INSTALL)
if [ -z "$RPM_INSTALLED" ]; then
	logMessageToFile "ERROR" "rpm $RPM_TO_INSTALL has not been installed."
else
	logMessageToFile "INFO" "Rpm $RPM_TO_INSTALL has been installed with version: $RPM_INSTALLED"
fi
}

function installRPM(){
logMessageToFile "INFO"  'installRPM'
RPM_TO_INSTALL=$1
logMessageToFile "INFO"  "Installing rpm $RPM_TO_INSTALL ..."
local INSTALL_LOG=$(yum install -y --disablerepo=* --enablerepo=LocalRepo $RPM_TO_INSTALL)
checkRPMWasInstalled $RPM_TO_INSTALL
local INSTALLED=$(rpm -qa | grep $RPM_TO_INSTALL)
if [ -z "$INSTALLED" ]; then
	logMessageToFile "WARNING"  "Installing rpm $RPM_TO_INSTALL failed from LocalRepo... Retrying from other repos..."
	logMessageToFile "WARNING" "$INSTALL_LOG"
	INSTALL_LOG=$(yum install -y $RPM_TO_INSTALL)
	checkRPMWasInstalled $RPM_TO_INSTALL
	INSTALLED=$(rpm -qa | grep $RPM_TO_INSTALL)
	if [ -z "$INSTALLED" ]; then
		logMessageToFile "ERROR" "$INSTALL_LOG"
	fi
fi

}

##########Function for returning sed compatible strings with . and / parsed##########
function getParsedTextForSed(){
replaced=$(echo $1 | sed 's/\./\\./g')
replaced=$(echo $replaced | sed 's/\//\\\//g')
echo $replaced
}

##########Function to remove the ask for password when devops user issues sudo command##########
function removeDevopsUserSudoPassword(){
logMessageToFile "INFO"  'removeDevopsUserSudoPassword'
sed "s/^# %wheel.*NOPASSWD: ALL/%wheel        ALL=(ALL)       NOPASSWD: ALL/" -i /etc/sudoers
}

##########Function for finding current host ip's in OpenStack environment##########
function findMyIP() {
logMessageToFile "INFO"  'findMyIP'
	myip=$(ifconfig | grep inet  | grep Bcast | grep Mask  | awk '{print $2}' | awk -F":" 'BEGIN {count=0;} END {if ( count == DEFAULT_ETH ) print $2 ; count++; }')
}

function setNotRequireTTYforDevops(){
logMessageToFile "INFO" "setNotRequireTTYforDevops"
sed -i '/Defaults.*requiretty/a Defaults: devops !requiretty' /etc/sudoers
}

function setUlimit(){
logMessageToFile "INFO"  'setUlimit'
echo 'fs.file-max = 4096' >> /etc/sysctl.conf 
echo "
* soft nofile 4096
* hard nofile 4096" >> /etc/security/limits.conf
sysctl -p
}

##########Check and configure LocalRepository##########
function configureLocalRepo(){
if [ ! -f /etc/yum.repos.d/localrepo.repo ];then
logMessageToFile "INFO"  'Configuring local repository ...' 
echo '[LocalRepo]
name=KY-Local-Repo
baseurl=http://'$LOCAL_REPO'/rpmrepo
enabled=1
gpgcheck=0' > /etc/yum.repos.d/localrepo.repo
chmod 644 /etc/yum.repos.d/localrepo.repo
sleep 1
fi
logMessageToFile "INFO"  'Cleaning repositories ...' 
yum clean all > /dev/null
}
#########InstallZabbix-Agent#########
function startZabbix(){
logMessageToFile "INFO"  "startZabbix"
service zabbix-agent start
}

function installZabbix(){
logMessageToFile "INFO"  "installZabbix"
installRPM zabbix-agent
}

function installZabbixSender(){
logMessageToFile "INFO"  "installZabbixSender"
installRPM zabbix-sender
}

function configureZabbix(){
logMessageToFile "INFO"  "configureZabbix"
sed -i "s/^Server=127.0.0.1/Server="$ZABBIX_SERVER"/"  /etc/zabbix/zabbix_agentd.conf
sed -i "s/^ServerActive=127.0.0.1/ServerActive="$ZABBIX_SERVER"/"  /etc/zabbix/zabbix_agentd.conf
sed -i "s/^Hostname=Zabbix server/Hostname="$(hostname)"/"  /etc/zabbix/zabbix_agentd.conf
}

function installAndConfigureZabbix(){
logMessageToFile "INFO"  "installAndConfigureZabbix"
installZabbix
configureZabbix
}

function configureZabbixOnWebUI(){
logMessageToFile "INFO"  "configureZabbixOnWebUI"
configureZabbix
sed -i 's/^# UserParameter=/UserParameter=apache[*],\/etc\/zabbix\/zapache.sh \\\$1/'  /etc/zabbix/zabbix_agentd.conf
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_ZAPACHE" "/etc/zabbix/zapache.sh"
chown zabbix:zabbix /etc/zabbix/zapache.sh
chmod 755 /etc/zabbix/zapache.sh
}

function installAndConfigureZabbixOnWebUI(){
logMessageToFile "INFO"  "installAndConfigureZabbixOnWebUI"
installZabbix
configureZabbixOnWebUI
}

function disableZabbixHosts(){
HOST_TO_DISABLE=$1
UPDATE_HOST="host.update"
AUTH_METHOD="user.authenticate"
GET_HOST="host.get"

AUTH_REPONSE=$(wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$AUTH_METHOD\",\"params\": {\"user\": \"$ZABBIX_USER\",\"password\": \"$ZABBIX_PASS\"},\"auth\": null,\"id\": 0}")
AUTH_TOKEN=$( echo $AUTH_REPONSE | awk '{split($0,array,":"); split(array[3],array1,"\"")} END{print array1[2]}')

HOST_RESPONSE=$(wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$GET_HOST\",\"params\": {\"output\": \"hostids\",\"filter\": {\"host\":\"$HOST_TO_DISABLE\"}},\"auth\": \"$AUTH_TOKEN\",\"id\": 1}")
HOST_ID=$( echo $HOST_RESPONSE | awk '{split ($0,array,"\"")} END{print array[10]}')


wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$UPDATE_HOST\",\"params\": {\"hostid\": \"$HOST_ID\",\"status\": \"1\"},\"auth\": \"$AUTH_TOKEN\",\"id\": 1}" > /dev/null
}

function removeZabbixHosts(){
HOST_TO_REMOVE=$1
UPDATE_HOST="host.delete"
AUTH_METHOD="user.authenticate"
GET_HOST="host.get"

AUTH_REPONSE=$(wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$AUTH_METHOD\",\"params\": {\"user\": \"$ZABBIX_USER\",\"password\": \"$ZABBIX_PASS\"},\"auth\": null,\"id\": 0}")
AUTH_TOKEN=$( echo $AUTH_REPONSE | awk '{split($0,array,":"); split(array[3],array1,"\"")} END{print array1[2]}')

HOST_RESPONSE=$(wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$GET_HOST\",\"params\": {\"output\": \"hostids\",\"filter\": {\"host\":\"$HOST_TO_REMOVE\"}},\"auth\": \"$AUTH_TOKEN\",\"id\": 1}")
HOST_ID=$( echo $HOST_RESPONSE | awk '{split ($0,array,"\"")} END{print array[10]}')


wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$UPDATE_HOST\",\"params\": {\"hostid\": \"$HOST_ID\",\"status\": \"1\"},\"auth\": \"$AUTH_TOKEN\",\"id\": 1}" > /dev/null
}

##########Setting hostname to be persistent##########
function setHostname(){
sed 's/^HOSTNAME=.*/HOSTNAME='`hostname`'/' -i /etc/sysconfig/network
}

##########Adding hostname in hosts##########
function configureHostname(){
if grep -q `hostname` /etc/hosts; then
		logMessageToFile "INFO"  "Host is already configured!"
	else
		logMessageToFile "INFO"  "Configuring host ..."
		echo $myip " " `hostname` >> /etc/hosts
fi
if grep `hostname` /etc/hosts >/dev/null; then
logMessageToFile "INFO"  "Successfully configure host property"
else
logMessageToFile "INFO" "Could not set host property in hosts file !"
exit 1;
fi
}

function configureLogsCollector(){
logMessageToFile "INFO" "configureLogsCollector"
if [ ! -f "/tmp/log_backup.py" ]; then
	logMessageToFile "WARNING" "log_backup.py not found in expected location: /tmp/log_backup.py. We will not configure it."
	return 1
fi

if [ ! -d "/root/scripts" ]; then
	mkdir /root/scripts
fi
cp -rf /tmp/log_backup.py /root/scripts
rm -rf /tmp/log_backup.py
chmod 755 /root/scripts/log_backup.py
echo "
1 0 * * * root /root/scripts/log_backup.py" >> /etc/crontab
}

function injectLogsCollector(){
logMessageToConsole "INFO" "injectLogsCollector $1"
ENVIRONMENT=$1
if [ ! -f "../../utils/$ENVIRONMENT/log_backup.py" ]; then
	logMessageToConsole "WARNING" "Logs collector scripts located: ../../utils/$ENVIRONMENT/log_backup.py does not exists."
else
	CONFIG_PARAMS_TO_PASS="$CONFIG_PARAMS_TO_PASS --file /tmp/log_backup.py=../../utils/$ENVIRONMENT/log_backup.py"
fi
}

function loadConfigParamsLocally(){
logMessageToConsole "INFO" "loadConfigParamsLocally $1"
ENVIRONMENT=$1
CONFIG_PARAMS_FILE="../utils/$ENVIRONMENT/config_params.sh"
CONFIG_FUNC_FILE="../utils/config_func.sh"
if [ ! -f "$CONFIG_PARAMS_FILE" ]; then
	CONFIG_PARAMS_FILE="../../utils/$ENVIRONMENT/config_params.sh"
	CONFIG_FUNC_FILE="../../utils/config_func.sh"
	if [ ! -f "$CONFIG_PARAMS_FILE" ]; then
	echo "Environment $ENVIRONMENT config param file not found..."
	exit 1
	fi
fi
if [ ! -f "$CONFIG_FUNC_FILE" ]; then
	echo "Config func file: $CONFIG_FUNC_FILE not found... Impossible to go on... Exiting..."
	exit 1
fi
. $CONFIG_PARAMS_FILE

CONFIG_PARAMS_TO_PASS=" --file /tmp/config_params.sh=$CONFIG_PARAMS_FILE --file /tmp/config_func.sh=$CONFIG_FUNC_FILE"
}

function createOrGetInstanceVolume(){
INSTANCE_NAME=$1
VOLUME_SIZE=$2
VOLUME_ID=$(nova volume-list | grep $INSTANCE_NAME | grep available | awk -F'|' '{print  $2}' | tr -d ' ')
if [ ! -z "$VOLUME_ID" ]; then
	echo "Volume already exists! Instance will be created with the existing volume: $VOLUME_ID"
else
echo "Creating a volume of $VOLUME_SIZE GB with name:" $INSTANCE_NAME"_volume"
VOLUME_ID=$(nova volume-create $VOLUME_SIZE --display-name $INSTANCE_NAME'_volume'  | grep ' id ' | awk -F'|' '{print $3}' | tr -d ' ')
fi
if [ -z "$VOLUME_ID" ]; then
	echo "[ERROR] - Volume could not be created... exiting scripts..."
	exit 1
fi
}

function exitIfNotSuccess(){
if [ ! "$1" -eq 0 ]; then
	echo "[ ERROR ] - There was an error.. exiting..."
	exit 1
fi
}

##########Function to ping instance##########
function pingIP(){
INSTANCE=$1
i=1
logMessageToFile "INFO"  "Pinging instance: $INSTANCE" 
while [ $i -le $(($WAIT_FOR_PING_REPLY*$((60/$PING_RETRY_INTERVAL)))) ]
do
	ping -q -c 1 $INSTANCE > /dev/null
	if [ "$?" -eq "0" ]; then
		return 0
	fi
	((i++))
	logMessageToFile "INFO"  "No ping response... Retry..." 
	sleep $PING_RETRY_INTERVAL
done
return 1
}


##########Function to ping created instance using ssh on cloud admin node##########
function checkInstanceCreatedSuccssfully(){
local INSTANCE=$1
if [ -z "$INSTANCE" ]; then
return 2
fi
i=1
RUNNING_IP=$(ifconfig | grep inet  | grep Bcast | grep Mask  | awk '{print $2}' | awk -F":" 'BEGIN {count=0;} END {if ( count == DEFAULT_ETH ) print $2 ; count++; }' | tr -d ' ')
if [ "$RUNNING_IP" == "$CLOUD_ADMIN_SERVER_LOCAL_IP" ]; then
while [ $i -le $(($WAIT_FOR_PING_REPLY*$((60/$PING_RETRY_INTERVAL)))) ]
do

	ping -q -c 1 $INSTANCE > /dev/null
	if [ "$?" -eq "0" ]; then
		return 0
	fi
	((i++))
	sleep $PING_RETRY_INTERVAL
done
else
while [ $i -le $(($WAIT_FOR_PING_REPLY*$((60/$PING_RETRY_INTERVAL)))) ]
do

	ssh devops@$CLOUD_ADMIN_SERVER 'ping -q -c 1 '$INSTANCE > /dev/null
	if [ "$?" -eq "0" ]; then
		return 0
	fi
	((i++))
	sleep $PING_RETRY_INTERVAL
done
fi
return 1
}

##########Function to ping created HA instance##########
function checkHAInstanceCreatedSuccssfully(){
local INSTANCE=$1
if [ -z "$INSTANCE" ]; then
return 2
fi
i=1

while [ $i -le $(($WAIT_FOR_PING_REPLY*$((60/$PING_RETRY_INTERVAL)))) ]
do

	ping -q -c 1 $INSTANCE > /dev/null
	if [ "$?" -eq "0" ]; then
		return 0
	fi
	((i++))
	sleep $PING_RETRY_INTERVAL
done
return 1
}

##########Functions searching for hostname for an ip##########
function findHostByIp(){
grep $1 $PWD_DIR/nova_instances.tmp  | awk -F'|' '{print tolower($3)}' | tr -d ' '
}

##########Functions searching for ip for instances to connect (redis, solr,rabbitmq)##########
function findip(){
_IP=$(grep -i "ACTIVE" $PWD_DIR/nova_instances.tmp | grep -i RUNNING | grep -i $1 | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>0) exit }' | tr -d ' ')
if [ ! -z "$_IP" ]; then
	pingIP $_IP
	if [ "$?" == "0"  ]; then
		echo $_IP
	else
		echo ""
fi
else
	echo ""
fi
}

##########Functions searching for 1st(2nd) core instances to connect##########
function find1stip(){
_IP=$(grep -i "ACTIVE" $PWD_DIR/nova_instances.tmp | grep -i RUNNING | grep -i $1  | grep $RPLSET | grep $RPM_VERSION | grep -vi `hostname` | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>0) exit }' | tr -d ' ')
if [ ! -z "$_IP" ]; then
	pingIP $_IP
	if [ "$?" == "0"  ]; then
		echo $_IP
	else
		echo ""
fi
else
	echo ""
fi
}

function find2ndip(){
_IP=$(grep -i "ACTIVE" $PWD_DIR/nova_instances.tmp | grep -i RUNNING | grep -i $1  | grep $RPLSET | grep $RPM_VERSION | grep -vi `hostname` | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==1 ) print $1 ; count++; if(count>1) exit }' | tr -d ' ')
if [ ! -z "$_IP" ]; then
	pingIP $_IP
	if [ "$?" == "0"  ]; then
		echo $_IP
	else
		echo ""
fi
else
	echo ""
fi
}

function findAvailablesIpsForCores(){
	logMessageToFile "INFO"  "Entering findAvailablesIpsForCores function..."
	user_ip1=$(find1stip $CORE_USER_GENERIC)
	user_ip2=$(find2ndip $CORE_USER_GENERIC)
	company_ip1=$(find1stip $CORE_COMPANY_GENERIC)
	company_ip2=$(find2ndip $CORE_COMPANY_GENERIC)
	banking_ip1=$(find1stip $CORE_BANKING_GENERIC)
	banking_ip2=$(find2ndip $CORE_BANKING_GENERIC)
	engine_ip1=$(find1stip $CORE_ENGINE_GENERIC)
	engine_ip2=$(find2ndip $CORE_ENGINE_GENERIC)
	messaging_ip1=$(find1stip $CORE_MESSAGING_GENERIC)
	messaging_ip2=$(find2ndip $CORE_MESSAGING_GENERIC)
	file_ip1=$(find1stip $CORE_FILE_GENERIC)
	file_ip2=$(find2ndip $CORE_FILE_GENERIC)
	encryption_ip1=$(find1stip $CORE_ENCRYPTION_GENERIC)
	encryption_ip2=$(find2ndip $CORE_ENCRYPTION_GENERIC)
	transaction_ip1=$(find1stip $CORE_TRANSACTION_GENERIC)
	transaction_ip2=$(find2ndip $CORE_TRANSACTION_GENERIC)
	backend_ip1=$(find1stip $CORE_BACKEND_GENERIC)
	backend_ip2=$(find2ndip $CORE_BACKEND_GENERIC)
	logMessageToFile "INFO"  "Extrancted following ips: user_ip1:$user_ip1 company_ip1:$company_ip1 banking_ip1:$banking_ip1 engine_ip1:$engine_ip1 messaging_ip1:$messaging_ip1 file_ip1:$file_ip1 encryption_ip1:$encryption_ip1 transaction_ip1:$transaction_ip1 backend_ip1:$backend_ip1"
	logMessageToFile "INFO"  "Extrancted following ips: user_ip2:$user_ip2 company_ip2:$company_ip2 banking_ip2:$banking_ip2 engine_ip2:$engine_ip2 messaging_ip2:$messaging_ip2 file_ip2:$file_ip2 encryption_ip2:$encryption_ip2 transaction_ip2:$transaction_ip2 backend_ip2:$backend_ip2"
} 

##########Function to extract ip of core instances to connect##########
function retry(){
i=1
logMessageToFile "INFO"  "Entering retry function"
while [ $i -le $(($RETRY_TIMEOUT*$((60/$NOVA_RETRY_INTERVAL)))) ]
do
	nova list > $PWD_DIR/nova_instances.tmp
	ip=$(find1stip $1)
	if [ ! -z "$ip" ]; then
		break
	fi
	logMessageToFile "WARN"  "No valid ip for $1 was found ... Retrying ..."
	sleep $NOVA_RETRY_INTERVAL
	((i++))
done
echo $ip
}

function retryFindIp(){
i=1
logMessageToFile "INFO"  "Entering retryFindIp function"
while [ $i -le $(($RETRY_TIMEOUT*$((60/$NOVA_RETRY_INTERVAL)))) ]
do
	nova list > $PWD_DIR/nova_instances.tmp
	ip=$(findip $1)
	if [ ! -z "$ip" ]; then
		break
	fi
	logMessageToFile "WARN"  "No valid ip for $1 was found ... Retrying ..."
	sleep $NOVA_RETRY_INTERVAL
	((i++))
done
echo $ip
}

function findAvailableSolr {
logMessageToFile "INFO"  'findAvailableSolr'
SOLR_SERVER=$(findip "$SOLR_SERVER_GENERIC-01")
if [ -z "$SOLR_SERVER" ]; then
	SOLR_SERVER=$(retryFindIp $SOLR_SERVER_GENERIC)
fi
}

function insertHealthCheckScript(){
logMessageToFile "INFO"  'insertHealthCheckScript'
PORT=$1
if [ ! -d "/root/scripts" ]; then
mkdir /root/scripts
fi
echo '
#!/bin/bash

PORT=$1
HEALTH_CHECK=$(curl -X GET  http://localhost:$PORT/health/full)
if [ -f "/tmp/healthCheck.txt" ]; then
rm -rf /tmp/healthCheck.txt
fi
for component in User Banking Company Tx Solr Backend Messaging Engine File ; do
COMPONENT_EXISTS=$(echo $HEALTH_CHECK | grep $component);
if [ ! -z "$COMPONENT_EXISTS" ]; then
echo $(hostname) health_${component,,} $(echo $HEALTH_CHECK |  gawk -v awk_variable=${component} '\''match($0,awk_variable){print substr($0,RSTART+awk_variable+length(awk_variable)+12,3)}'\'') >> /tmp/healthCheck.txt
fi
done

/usr/bin/zabbix_sender -z '$ZABBIX_SERVER' -p '$ZABBIX_PORT' -i /tmp/healthCheck.txt
' > /root/scripts/healthCheckScript.sh
chmod 755 /root/scripts/healthCheckScript.sh
echo "
*/1 * * * * root /root/scripts/healthCheckScript.sh $PORT" >> /etc/crontab
}

function findAvailableRabbitmq {
logMessageToFile "INFO"  "findAvailableRabbitmq $1 $2"
local rabbit_generic=$1
RABBITMQ_SERVER=$(findip $rabbit_generic$2)
if [ -z "$RABBITMQ_SERVER" ]; then
	RABBITMQ_SERVER=$(retryFindIp $rabbit_generic$2)
fi
}

function findAvailableMysql {
logMessageToFile "INFO"  'findAvailableMysql'
MYSQL_SERVER=$(findip $MYSQL_SERVER_GENERIC)
if [ -z "$MYSQL_SERVER" ]; then
	MYSQL_SERVER=$(retryFindIp $MYSQL_SERVER_GENERIC)
fi
}

function findAvailableMongo {
logMessageToFile "INFO"  'findAvailableMongo'
MONGOS_SERVER='localhost'
}

function configureSwiftParameters(){
logMessageToFile "INFO" "configureSwiftParameters"
echo '
ky.binary.common.swift.endpoint='$OS_AUTH_URL'
ky.binary.common.swift.username='$OS_USERNAME'
ky.binary.common.swift.password='$OS_PASSWORD'
ky.binary.common.swift.tenant.name='$OS_TENANT_NAME >> core.properties
}

function getCertFilesForBasp(){
logMessageToFile "INFO"  'getCertFilesForBasp'
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_BANKING_CERTIFICATE" "$BASP_KEYSTORE"
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_TRUSTED_CAROOT_CERTIFICATE" "$BASP_TRUSTSTORE"
}

function configureBASPParameters(){
logMessageToFile "INFO"  'configureBASPParameters'
getCertFilesForBasp
echo '
'$BASP_PUBLIC_IP' '$BASP_HOSTNAME >> /etc/hosts
echo '
ky.core.common.external.basp.url=https://'$BASP_HOSTNAME':'$BASP_PORT'
ky.core.common.external.basp.settlementpayments.route=settlementpayments
ky.core.common.external.basp.billing.route=billing
ky.core.common.keystore.path='$BASP_KEYSTORE'
ky.core.common.keystore.pass='$BASP_KEYSTORE_PASS'
ky.core.common.truesstore.path='$BASP_TRUSTSTORE'
ky.core.common.truesstore.pass='$BASP_TRUSTSTORE_PASS'' > basp.properties

}

function configureScheduler(){
logMessageToFile "INFO"  'configureScheduler'
SCHEDULER=$1
MINUTE_OF_DAY=$2
HOUR_OF_DAY=$3

cd /opt/ky/core-*/scheduler-$SCHEDULER-bee*/conf
configCoreFile
sed -i "s/localhost/$myip/"  instance.properties
cd /opt/ky/core-*/scheduler-$SCHEDULER-bee*/bin
SCHEDULER_RUN_PATH=`pwd`"/run.sh"
chmod 755 $SCHEDULER_RUN_PATH
################small hack for schedulers to run only on 1st instance################
INSTANCE_NO=$(echo `hostname` | awk -F'-' '{print $5}')
if [ "$INSTANCE_NO" -eq 1 ]; then
echo "
$MINUTE_OF_DAY $HOUR_OF_DAY * * * root $SCHEDULER_RUN_PATH" >> /etc/crontab
fi
################small hack for schedulers to run only on 1st instance################
}

function configuringBillingBee(){
logMessageToFile "INFO"  'configuringBillingBee'
configureScheduler 'billing' '0' "$SCHEDULERS_HOUR_OF_DAY"
}

function configuringSettlerBee(){
logMessageToFile "INFO"  'configuringSettlerBee'
configureScheduler 'settler' '0' "$SCHEDULERS_HOUR_OF_DAY"
}

function configuringConfirmedBee(){
logMessageToFile "INFO"  'configuringConfirmedBee'
configureScheduler 'confirmed' '0' "$SCHEDULERS_HOUR_OF_DAY"
}

function configureBankingSchedulers(){
logMessageToFile "INFO"  'configureBankingSchedulers'
CURRENT_DIR=`pwd`
configuringBillingBee
configuringSettlerBee
configuringConfirmedBee
cd $CURRENT_DIR
}

function configuringUserUnlockBee(){
logMessageToFile "INFO"  'configuringUserUnlock'
configureScheduler 'userunlock' '0'
}

function configureUserSchedulers(){
logMessageToFile "INFO"  'configureUserSchedulers'
CURRENT_DIR=`pwd`
configuringUserUnlockBee
cd $CURRENT_DIR
}

function configuringCancelBee(){
logMessageToFile "INFO"  'configuringCancelBee'
configureScheduler 'cancel' '0' "$SCHEDULERS_HOUR_OF_DAY"
}

function configuringTransactionBee(){
logMessageToFile "INFO"  'configuringTransactionBee'
configureScheduler 'transactions' '0' "$SCHEDULERS_HOUR_OF_DAY"
}

function configureTransactionSchedulers(){
logMessageToFile "INFO"  'configureTransactionSchedulers'
CURRENT_DIR=`pwd`
configuringCancelBee
configuringTransactionBee
cd $CURRENT_DIR
}

function configureRedisParameters(){
echo "ky.-.common.redis.sentinels=$REDIS_STATIC_IP1:$REDIS_SENTINEL_PORT;$REDIS_STATIC_IP2:$REDIS_SENTINEL_PORT;$REDIS_STATIC_IP3:$REDIS_SENTINEL_PORT">> core.properties
}

function configureRabbitMQParameters(){
logMessageToFile "INFO" "configureRabbitMQParameters"
findAvailableRabbitmq "$RABBITMQ_SERVER_GENERIC" "-01"
rabbit1=$RABBITMQ_SERVER
findAvailableRabbitmq "$RABBITMQ_SERVER_GENERIC" "-02"
rabbit2=$RABBITMQ_SERVER
echo '
ky.core.common.rabbitmq.server.hosts='$rabbit1':'$RABBITMQ_PORT'|'$rabbit2':'$RABBITMQ_PORT'
ky.core.common.rabbitmq.username='$RABBITMQ_USER'
ky.core.common.rabbitmq.password='$RABBITMQ_PASSWD'' >> core.properties
chown kaiyuan:kaiyuan core.properties
}

function configureRabbitMQGenericParameters(){
logMessageToFile "INFO" "configureRabbitMQGenericParameters"
echo "
ky.core.common.rabbitmq.poll.timeout=-1
ky.core.common.rabbitmq.recovery.automatic=true
ky.core.common.rabbitmq.recovery.topology=true
ky.core.common.rabbitmq.recovery.interval=60000
ky.core.common.rabbitmq.recovery.push.interval=2000
ky.core.common.rabbitmq.recovery.count=3
ky.core.common.rabbitmq.recovery.sleep=900000
" >> core.properties
}

function configureExtRabbitMQParameters(){
logMessageToFile "INFO" "configureExtRabbitMQParameters"
findAvailableRabbitmq "$RABBITMQ_SERVER_GENERIC" "-01"
rabbit1=$RABBITMQ_SERVER
findAvailableRabbitmq "$RABBITMQ_SERVER_GENERIC" "-02"
rabbit2=$RABBITMQ_SERVER
echo '
ky.core.common.ext.rabbitmq.server.hosts='$rabbit1':'$RABBITMQ_PORT'|'$rabbit2':'$RABBITMQ_PORT'
ky.core.common.ext.rabbitmq.username='$RABBITMQ_USER'
ky.core.common.ext.rabbitmq.password='$RABBITMQ_PASSWD'
' >> core.properties
}

function configureSolrParameters(){
findAvailableSolr
echo '
ky.-.common.solr.search.url=http://'$SOLR_SERVER:$SOLR_PORT'/solr' >> core.properties
}

##########Function which is adding one config line (core-service) at an execution to core.properties file##########
function addComponentToCore {
logMessageToFile "INFO"  "Entering function addComponentToCore with values:1=$1; 2=$2; 3=$3; 4=$4"
SERV=$1
PORT=$2
IP1=$3
IP2=$4

SERV_ALIAS="$SERV"
if [ "$SERV" == "tx" ]; then
	SERV_ALIAS="transaction"
fi

SERVICE=$(echo `hostname` | awk -F'-' '{print $2}')

if [ -z "$IP2" ]; then
	if [ -z "$IP1" ]; then
		if [ "$SERVICE" == "$SERV_ALIAS" ]; then
			echo 'component.'$SERV' = ["'$myip':'$PORT'"]' >> core.properties
		else
			IP1=$(retry 'core-'$SERV_ALIAS)
			if [ -z "$IP1" ]; then
				echo "Could not find core-user instance! Service not configured!" >> core.properties
				exit 1;
			else
				echo 'component.'$SERV' = ["'$IP1':'$PORT'"]' >> core.properties
			fi
		fi
	else
		if [ "$IP1" != "$myip" -a "$SERVICE" == "$SERV_ALIAS" ]; then
			echo 'component.'$SERV' = ["'$IP1':'$PORT'","'$myip':'$PORT'"]' >> core.properties
		else
			echo 'component.'$SERV' = ["'$IP1':'$PORT'"]' >> core.properties
		fi
	fi
else
	echo 'component.'$SERV' = ["'$IP1':'$PORT'","'$IP2':'$PORT'"]' >> core.properties
fi
}

function configCoreFile(){
logMessageToFile "INFO" "configCoreFile"
findAvailablesIpsForCores
if [ ! -f 'core.properties' ]; then
	logMessageToFile "WARN"  'core.properties was not found !!!'
	return 1
fi

mv core.properties core.properties.tmp
configureRedisParameters


if grep -q 'component.user' 'core.properties.tmp'; then
	addComponentToCore "user" $PORT_USER $user_ip1 $user_ip2
fi
if grep -q 'component.messaging' 'core.properties.tmp'; then
	addComponentToCore "messaging" $PORT_MESSAGING $messaging_ip1 $messaging_ip2
fi
if grep -q 'component.company' 'core.properties.tmp'; then
	addComponentToCore "company" $PORT_COMPANY $company_ip1 $company_ip2
fi
if grep -q 'component.banking' 'core.properties.tmp'; then
	addComponentToCore "banking" $PORT_BANKING $banking_ip1 $banking_ip2
fi
if grep -q 'component.file' 'core.properties.tmp'; then
	addComponentToCore "file" $PORT_FILE $file_ip1 $file_ip2
fi
if grep -q 'component.tx' 'core.properties.tmp'; then
	addComponentToCore "tx" $PORT_TRANSACTION $transaction_ip1 $transaction_ip2
fi
if grep -q 'component.engine' 'core.properties.tmp'; then
	addComponentToCore "engine" $PORT_ENGINE $engine_ip1 $engine_ip2
fi
if grep -q 'component.encryption' 'core.properties.tmp'; then
	addComponentToCore "encryption" $PORT_ENCRYPTION $encryption_ip1 $encryption_ip2
fi
if grep -q 'component.backend' 'core.properties.tmp'; then
	addComponentToCore "backend" $PORT_BACKEND $backend_ip1 $backend_ip2
fi
rm -f 'core.properties.tmp'
chown kaiyuan:kaiyuan core.properties
}


##########Creating db file##########
function addConfigToDbFile(){
logMessageToFile "INFO"  "addConfigToDbFile with values: 1=$1; 2=$2; 3=$3; 4=$4; 5=$5"
local host_type=$1
local host=$2
local dbname=$3
local user=$4
local pass=$5

if [ "$host_type" == "mongo" ]; then
echo 'ky.core.common.mongo.host.address='$host'
ky.core.common.mongo.host.port='$MONGOS_PORT'
ky.core.common.mongo.db.name='$dbname'
ky.core.common.mongo.db.username='$user'
ky.core.common.mongo.db.password='$pass'' >> db.properties
else
echo 'ky.core.common.mysql.connection.string=jdbc:mysql://'$host':'$MYSQL_PORT'/'$dbname'
ky.core.common.mysql.username='$user'
ky.core.common.mysql.password='$pass'' >> db.properties
fi
}

##########Function to extract ip first database node ex. mongod-database-rs0-01##########
function getMyRSIp(){
myrsip=$(grep "$MONGOD_DATABASE-$RPLSET-01" $PWD_DIR/nova_instances.tmp | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>1) exit }' | tr -d ' ')

logMessageToFile "INFO"  "getMyRSIp: myrsip=$myrsip"
}

##########Function to extract all config nodes ips in MONGOS_CONFIGDB string ex: MONGOS_CONFIGDB=ip1:port,ip2,port ##########
function getConfigDBS(){
	configdb1=$(grep $MONGOD_CONFIG $PWD_DIR/nova_instances.tmp | grep $RPLSET | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>2) exit }' | tr -d ' ')
	configdb2=$(grep $MONGOD_CONFIG $PWD_DIR/nova_instances.tmp | grep $RPLSET | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==1 ) print $1 ; count++; if(count>2) exit }' | tr -d ' ')
	configdb3=$(grep $MONGOD_CONFIG $PWD_DIR/nova_instances.tmp | grep $RPLSET | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==2 ) print $1 ; count++; if(count>2) exit }' | tr -d ' ')
	if [ ! -z "$configdb1" ]; then
	pingIP $configdb1
	if [ "$?" != "0"  ]; then
		configdb1=""
	fi
	fi
	if [ ! -z "$configdb2" ]; then
	pingIP $configdb2
	if [ "$?" != "0"  ]; then
		configdb2=""
	fi
	fi
	if [ ! -z "$configdb3" ]; then
	pingIP $configdb3
	if [ "$?" != "0"  ]; then
		configdb3=""
	fi
	fi
	
	if [ ! -z "$configdb1" ]; then
		MONGOS_CONFIGDB=$configdb1':'$MONGOD_CONFIG_PORT
	fi
	if [ ! -z "$configdb2" ]; then
		if [ ! -z "$MONGOS_CONFIGDB" ]; then
			MONGOS_CONFIGDB=$MONGOS_CONFIGDB','$configdb2':'$MONGOD_CONFIG_PORT
		else
			MONGOS_CONFIGDB=$configdb2':'$MONGOD_CONFIG_PORT
		fi
	fi
	if [ ! -z "$configdb3" ]; then
		if [ ! -z "$MONGOS_CONFIGDB" ]; then
			MONGOS_CONFIGDB=$MONGOS_CONFIGDB','$configdb3':'$MONGOD_CONFIG_PORT
		else
			MONGOS_CONFIGDB=$configdb3':'$MONGOD_CONFIG_PORT
		fi
	fi
	logMessageToFile "INFO"  "MONGOS_CONFIGDB: $MONGOS_CONFIGDB"
	if [ -z "$MONGOS_CONFIGDB" ]; then
	sleep 5
	logMessageToFile "INFO"  "Waiting for mongo config dbs to be created in nova ..."
	nova list > $PWD_DIR/nova_instances.tmp
	getConfigDBS
	fi
	}

##########Function to extract all database nodes ips in MONGOS_DATABASE_DBS string ex: MONGOS_DATABASE_DBS=ip1:port,ip2,port ##########
function getDatabaseDBS(){
	databasedb1=$(grep $MONGOD_DATABASE $PWD_DIR/nova_instances.tmp | grep $RPLSET | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>0) exit }' | tr -d ' ')
	databasedb2=$(grep $MONGOD_DATABASE $PWD_DIR/nova_instances.tmp | grep $RPLSET | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==1 ) print $1 ; count++; if(count>1) exit }' | tr -d ' ')
	databasedb3=$(grep $MONGOD_DATABASE $PWD_DIR/nova_instances.tmp | grep $RPLSET | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==2 ) print $1 ; count++; if(count>2) exit }' | tr -d ' ')
	databasedb4=$(grep $MONGOD_DATABASE $PWD_DIR/nova_instances.tmp | grep $RPLSET | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==3 ) print $1 ; count++; if(count>3) exit }' | tr -d ' ')
		if [ ! -z "$databasedb1" ]; then
	pingIP $databasedb1
	if [ "$?" != "0"  ]; then
		databasedb1=""
	fi
	fi
	if [ ! -z "$databasedb2" ]; then
	pingIP $databasedb2
	if [ "$?" != "0"  ]; then
		databasedb2=""
	fi
	fi
	if [ ! -z "$databasedb3" ]; then
	pingIP $databasedb3
	if [ "$?" != "0"  ]; then
		databasedb3=""
	fi
	fi
	if [ ! -z "$databasedb4" ]; then
	pingIP $databasedb4
	if [ "$?" != "0"  ]; then
		databasedb4=""
	fi
	fi
	if [ ! -z "$databasedb1" ]; then
		MONGOS_DATABASE_DBS=$databasedb1':'$MONGOD_DATABASE_PORT
	fi
	if [ ! -z "$databasedb2" ]; then
		if [ ! -z "$MONGOS_DATABASE_DBS" ]; then
			MONGOS_DATABASE_DBS=$MONGOS_DATABASE_DBS','$databasedb2':'$MONGOD_DATABASE_PORT
		else
			MONGOS_DATABASE_DBS=$databasedb2':'$MONGOD_DATABASE_PORT
		fi
	fi
	if [ ! -z "$databasedb3" ]; then
		if [ ! -z "$MONGOS_DATABASE_DBS" ]; then
			MONGOS_DATABASE_DBS=$MONGOS_DATABASE_DBS','$databasedb3':'$MONGOD_DATABASE_PORT
		else
			MONGOS_DATABASE_DBS=$databasedb3':'$MONGOD_DATABASE_PORT
		fi
	fi
	if [ ! -z "$databasedb4" ]; then
		if [ ! -z "$MONGOS_DATABASE_DBS" ]; then
			MONGOS_DATABASE_DBS=$MONGOS_DATABASE_DBS','$databasedb4':'$MONGOD_DATABASE_PORT
		else
			MONGOS_DATABASE_DBS=$databasedb4':'$MONGOD_DATABASE_PORT
		fi
	fi
	logMessageToFile "INFO"  "MONGOS_DATABASE_DBS: $MONGOS_DATABASE_DBS"
	if [ -z "$MONGOS_DATABASE_DBS" ]; then
	sleep 5
	logMessageToFile "INFO"  "Waiting for mongodatabase dbs to be created in nova ..." 
	nova list > $PWD_DIR/nova_instances.tmp
	getDatabaseDBS
	fi	
	}
	
function waitTillProcessIsUp(){
logMessageToFile "INFO"  "Waiting for process $1 to be up ..."
PROCESS=$(ps -ef | grep -v grep | grep $1)
while [ -z "$PROCESS" ]
do
sleep $MONGO_PROCCES_UPTIME
logMessageToFile "WARN"  "Still waiting for process $1 to be up ..."
PROCESS=$(ps -ef | grep -v grep | grep $1)
done
sleep 30
}


##########Functions which are adding one config line (core-service) to core.properties file##########
function addComponentToApi {
logMessageToFile "INFO"  "Entering function addComponentToApi with values:1=$1; 2=$2; 3=$3; 4=$4"
SERV=$1
PORT=$2
IP1=$3
IP2=$4

if [ -z "$IP2" ]; then
	if [ -z "$IP1" ]; then
		IP1=$(retry 'api-'$SERV)
			if [ -z "$IP1" ]; then
				echo "Could not find core-user instance! Service not configured!" >> core.properties
				exit 1;
			else
				echo 'component.'$SERV' = ["'$IP1':'$PORT'"]' >> core.properties
			fi
		else
			echo 'component.'$SERV' = ["'$IP1':'$PORT'"]' >> core.properties
	fi
else
	echo 'component.'$SERV' = ["'$IP1':'$PORT'","'$IP2':'$PORT'"]' >> core.properties
fi
}


function configCoreFileForAPI(){
mv core.properties core.properties.tmp
configureRedisParameters

findAvailablesIpsForCores

if grep -q 'component.user' 'core.properties.tmp'; then
	addComponentToApi "user" $PORT_USER $user_ip1 $user_ip2
fi
if grep -q 'component.messaging' 'core.properties.tmp'; then
	addComponentToApi "messaging" $PORT_MESSAGING $messaging_ip1 $messaging_ip2
fi
if grep -q 'component.company' 'core.properties.tmp'; then
	addComponentToApi "company" $PORT_COMPANY $company_ip1 $company_ip2
fi
if grep -q 'component.banking' 'core.properties.tmp'; then
	addComponentToApi "banking" $PORT_BANKING $banking_ip1 $banking_ip2
fi
if grep -q 'component.file' 'core.properties.tmp'; then
	addComponentToApi "file" $PORT_FILE $file_ip1 $file_ip2
fi
if grep -q 'component.tx' 'core.properties.tmp'; then
	addComponentToApi "tx" $PORT_TRANSACTION $transaction_ip1 $transaction_ip2
fi
if grep -q 'component.engine' 'core.properties.tmp'; then
	addComponentToApi "engine" $PORT_ENGINE $engine_ip1 $engine_ip2
fi
if grep -q 'component.encryption' 'core.properties.tmp'; then
	addComponentToApi "encryption" $PORT_ENCRYPTION $encryption_ip1 $encryption_ip2
fi
if grep -q 'component.backend' 'core.properties.tmp'; then
	addComponentToApi "backend" $PORT_BACKEND $backend_ip1 $backend_ip2
fi
rm -f 'core.properties.tmp'
chown kaiyuan:kaiyuan core.properties
}

function installJAVA(){
logMessageToFile "INFO"  'installJAVA'
installRPM jdk
}

function configureJAVA(){
logMessageToFile "INFO"  'configureJAVA'
## java ##
alternatives --install /usr/bin/java java /usr/java/latest/jre/bin/java 200000
## javaws ##
alternatives --install /usr/bin/javaws javaws /usr/java/latest/jre/bin/javaws 200000
## Install javac only if you installed JDK (Java Development Kit) package ##
alternatives --install /usr/bin/javac javac /usr/java/latest/bin/javac 200000
alternatives --install /usr/bin/jar jar /usr/java/latest/bin/jar 200000
## export JAVA_HOME JDK/JRE ##
echo 'export JAVA_HOME="/usr/java/latest"' >> /etc/profile
}

function installAndConfigureJAVA(){
installJAVA
configureJAVA
}

function installTomcat(){
logMessageToFile "INFO"  'installTomcat'
mkdir /usr/share/tomcat
cd /usr/share/tomcat
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_TOMCAT_FILE" "/usr/share/tomcat/$SWIFT_TOMCAT_FILE"
tar -xzf $SWIFT_TOMCAT_FILE
rm -f $SWIFT_TOMCAT_FILE
ln -s /usr/share/tomcat/apache-tomcat-* latest
}

function configureTomcat(){
logMessageToFile "INFO"  'configureTomcat'
echo '<tomcat-users>  
<role rolename="manager-gui"/>  
<user username="tomcat" password="devops2013" roles="manager-gui"/>  
</tomcat-users>' > $TOMCAT_HOME/conf/tomcat-users.xml

echo '#!/bin/bash  
# description: Tomcat Start Stop Restart  
# processname: tomcat  
# chkconfig: 234 20 80  
export JAVA_OPTS="-Dfile.encoding=UTF-8 \
  -Dcatalina.logbase=/var/log/tomcat \
  -Dnet.sf.ehcache.skipUpdateCheck=true \
  -XX:+DoEscapeAnalysis \
  -XX:+UseConcMarkSweepGC \
  -XX:+CMSClassUnloadingEnabled \
  -XX:+UseParNewGC \
  -XX:MaxPermSize=128m \
  -Xms512m -Xmx512m"
export PATH=$JAVA_HOME/bin:$PATH
CATALINA_HOME='$TOMCAT_HOME'/bin  
SHUTDOWN_WAIT=20

case $1 in  
start)  
/bin/su tomcat $CATALINA_HOME/startup.sh  
;;   
stop)     
/bin/su tomcat $CATALINA_HOME/shutdown.sh  
;;   
restart)  
/bin/su tomcat $CATALINA_HOME/shutdown.sh  
/bin/su tomcat $CATALINA_HOME/startup.sh  
;;   
esac      
exit 0' > /etc/init.d/tomcat
chmod 755 /etc/init.d/tomcat
chkconfig --add tomcat  
chkconfig --level 234 tomcat on
groupadd tomcat
useradd -g tomcat -d $TOMCAT_HOME tomcat 
chown -RHf tomcat:tomcat $TOMCAT_HOME
chown -Rf tomcat:tomcat $TOMCAT_HOME
}

function startTomcat(){
logMessageToFile "INFO"  'Starting tomcat...'
service tomcat start
}

function installAndConfigureTomcat(){
installTomcat
configureTomcat
} >> $LOG_FILE

function installSolr(){
logMessageToFile "INFO"  'installSolr'
installAndConfigureJAVA
installAndConfigureTomcat
mkdir /usr/local/solr
cd /usr/local/solr
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_SOLR_FILE" "/usr/local/solr/$SWIFT_SOLR_FILE"
tar -xzf $SWIFT_SOLR_FILE
rm -f $SWIFT_SOLR_FILE
ln -s /usr/local/solr/solr-* latest
installAndConfigureSolrVolume
chown -Rf tomcat:tomcat latest
}

function configureSolr(){
logMessageToFile "INFO"  'configureSolr'
if [ ! -d "$TOMCAT_HOME/conf/Catalina/localhost" ]; then
mkdir -p $TOMCAT_HOME/conf/Catalina/localhost
fi
echo '<?xml version="1.0" encoding="utf-8"?>
<Context docBase="'$SOLR_HOME'/example/webapps/solr.war" debug="0" crossContext="true">
<Environment name="solr/home" type="java.lang.String" value="'$SOLR_HOME'/example/solr" override="true"/>
</Context>' > $TOMCAT_HOME/conf/Catalina/localhost/solr.xml
cp $SOLR_HOME/example/lib/ext/* $TOMCAT_HOME/lib
cp $SOLR_HOME/example/resources/log4j.properties $TOMCAT_HOME/lib
sed 's/^solr\.log.*/solr\.log='$(getParsedTextForSed $SOLR_HOME)'\/example\/logs\//' -i $TOMCAT_HOME/lib/log4j.properties
PWD_DIR=`pwd`
cd $PWD_DIR
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_DIC_FILE" "$PWD_DIR/$SWIFT_DIC_FILE"
tar -xzf $SWIFT_DIC_FILE
cp -rf dic $TOMCAT_HOME/lib
cp -rf dic /
chown -R tomcat:tomcat /dic
rm -rf dic $SWIFT_DIC_FILE
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_SOLR_WAR_FILE" "$PWD_DIR/$SWIFT_SOLR_WAR_FILE"
cp -rf $SWIFT_SOLR_WAR_FILE $SOLR_HOME/example/webapps
rm -rf $SWIFT_SOLR_WAR_FILE
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_SCHEMA_FILE" "$PWD_DIR/$SWIFT_SCHEMA_FILE"
cp -rf $SWIFT_SCHEMA_FILE $SOLR_HOME/example/solr/collection1/conf
rm -rf $SWIFT_SCHEMA_FILE
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_DIC_WORDS_FILE" "$PWD_DIR/$SWIFT_DIC_WORDS_FILE"
tar -xzf $SWIFT_DIC_WORDS_FILE
cp -rf dic $SOLR_HOME/example/solr/collection1/conf
rm -rf dic $SWIFT_DIC_WORDS_FILE
chown -RHf tomcat:tomcat $TOMCAT_HOME
chown -RHf tomcat:tomcat $SOLR_HOME
}

function installAndConfigureSolr(){
logMessageToFile "INFO" "installAndConfigureSolr"
installSolr
configureSolr
}

function installRedis(){
logMessageToFile "INFO"  'installRedis'
mkdir /usr/local/redis
cd /usr/local/redis
logMessageToFile "DEBUG" "Downloading redis archive from: $REDIS_URL"
wget $REDIS_URL
tar xzf $REDIS_GZIP
rm -f $REDIS_GZIP
ln -s /usr/local/redis/redis* latest
cd $REDIS_HOME
yum install -y gcc-c++ jemalloc-devel
checkRPMWasInstalled gcc-c++
checkRPMWasInstalled jemalloc-devel
logMessageToFile "DEBUG" "Compiling redis..."
make
}

function configureMasterSlaveRedis(){
logMessageToFile "INFO"  "configureMasterSlaveRedis"

findMyIP
if [ "$REDIS_MASTER_IP" == "$myip" ]; then
	logMessageToFile "INFO" "I am the master"
else
	logMessageToFile "INFO" "I am a slave"
	sed 's/^# slaveof .*/slaveof '$REDIS_MASTER_IP' '$REDIS_PORT'/' -i /etc/redis/$REDIS_PORT.conf
fi
}

function configureRedis(){
logMessageToFile "INFO"  "configureRedis"
mkdir /etc/redis
mkdir /var/redis
cd $REDIS_HOME
cp src/redis-server /usr/local/bin
cp src/redis-cli /usr/local/bin
cp utils/redis_init_script /etc/init.d/redis_$REDIS_PORT
sed -i '2i # chkconfig: 234 95 20' /etc/init.d/redis_$REDIS_PORT
sed -i '3i # description:  Redis is a persistent key-value database' /etc/init.d/redis_$REDIS_PORT
sed -i '4i # processname: redis' /etc/init.d/redis_$REDIS_PORT
sed 's/^REDISPORT=.*/REDISPORT='$REDIS_PORT'/' -i /etc/init.d/redis_$REDIS_PORT
cp redis.conf /etc/redis/$REDIS_PORT.conf
mkdir /var/redis/$REDIS_PORT
sed 's/^daemonize .*/daemonize yes/' -i /etc/redis/$REDIS_PORT.conf
sed 's/^pidfile .*/pidfile \/var\/run\/redis_'$REDIS_PORT'\.pid/' -i /etc/redis/$REDIS_PORT.conf
sed 's/^port .*/port '$REDIS_PORT'/' -i /etc/redis/$REDIS_PORT.conf
sed 's/^loglevel .*/loglevel notice/' -i /etc/redis/$REDIS_PORT.conf
sed 's/^logfile .*/logfile \/var\/log\/redis_'$REDIS_PORT'\.log/' -i /etc/redis/$REDIS_PORT.conf
sed 's/^dir .*/dir \/var\/redis\/'$REDIS_PORT'/' -i /etc/redis/$REDIS_PORT.conf
chkconfig --add redis_$REDIS_PORT  
chkconfig --level 234 redis_$REDIS_PORT on
configureMasterSlaveRedis
}


function startRedis(){
logMessageToFile "INFO"  "Starting redis on port $REDIS_PORT..."
service redis_$REDIS_PORT start
}

function installAndConfigureRedis(){
logMessageToFile "INFO" "installAndConfigureRedis"
installRedis
configureRedis
}

function configureRedisMonitoring(){
logMessageToFile "INFO" "configureRedisMonitoring"
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_REDIS_MONITORING_PYTHON" "/etc/zabbix/zbx_redis_stats.py"
chmod +x /etc/zabbix/zbx_redis_stats.py
echo "
UserParameter=redis.discovery,/etc/zabbix/zbx_redis_stats.py localhost list_key_space_db
UserParameter=redis[*], /etc/zabbix/zbx_redis_stats.py \$1 \$2 \$3
" >> /etc/zabbix/zabbix_agentd.conf

}

function installWebui(){
logMessageToFile "INFO"  'installWebUI'
RPM_VERSION=$(echo `hostname` | awk -F'-' '{print $2}')
installRPM "kyweb-"$KYWEB_MAJOR_VERSION$RPM_VERSION
} 

function getAndroidPackage(){
logMessageToFile "INFO"  'getAndroidPackage'
mkdir /opt/kyweb/public/update
cd /opt/kyweb/public/update
swift download $SWIFT_ANDROID_CONTAINER
} 

function installAndConfigureWebui()
{
logMessageToFile "INFO"  'installAndConfigureWebui'
installWebui
getAndroidPackage
}

function installMainProxy(){
logMessageToFile "INFO"  "installMainProxy"
CURRENT_DIR=`pwd`
adduser haproxy
cd /usr/local
if [ ! -d 'haproxy' ]; then
mkdir haproxy
fi
cd haproxy
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_HAPROXY_FILE" "/usr/local/haproxy/$SWIFT_HAPROXY_FILE"

if [ ! -f "$SWIFT_HAPROXY_FILE" ]; then
logMessageToFile "ERROR" "Haproxy file $SWIFT_HAPROXY_FILE not found in swift $SWIFT_UTILS_CONTAINER container. Aborting install"
exit 1
fi

tar xzf $SWIFT_HAPROXY_FILE
rm -rf $SWIFT_HAPROXY_FILE
ln -s /usr/local/haproxy/haproxy* latest
cd latest
make install
cp haproxy /usr/sbin/haproxy
installAndConfigureZabbix
startZabbix
cd $CURRENT_DIR
}

function configureHAProxyMonitoringScript(){
logMessageToFile "INFO"  "configureHAProxyMonitoringScript"
installZabbixSender
PWD_DIR=`pwd`
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_ZABBIX_HAPROXY_ZIP" "$PWD_DIR/$SWIFT_ZABBIX_HAPROXY_ZIP"
tar -xvf $SWIFT_ZABBIX_HAPROXY_ZIP
rm -rf $SWIFT_ZABBIX_HAPROXY_ZIP
tmp_dir=$(echo $SWIFT_ZABBIX_HAPROXY_ZIP | awk -F'.' '{print $1}')
cd $tmp_dir*/haproxy
cp haproxy-poller.py /usr/local/bin/
chmod 755 /usr/local/bin/haproxy-poller.py
cp haproxy-poller.ini /usr/local/etc/
echo "
*/1 * * * * root  /usr/local/bin/haproxy-poller.py /usr/local/etc/haproxy-poller.ini http://127.0.0.1:81/haproxyStats $ZABBIX_SERVER $ZABBIX_PORT
" >> /etc/crontab
}

function configureMainProxy(){
logMessageToFile "INFO"  "configureMainProxy"
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_HAPROXY_CERTIFICATE" "/etc/ssl/certs/server_key.pem"
configureHAProxyMonitoringScript
echo "api_auth,auth:lb_api_auth
api_user,user:lb_api_user
api_banking,banking:lb_api_banking
api_backend,backend:lb_api_backend
api_company,company:lb_api_company
api_transaction,transaction:lb_api_transaction
api_search,search:lb_api_search
api_support,support:lb_api_support
secure_port,FRONTEND:haproxy" > /usr/local/etc/haproxy-poller.ini

if [ ! -d "/etc/haproxy" ]; then
mkdir /etc/haproxy
fi
echo "global
        log 127.0.0.1   local0
        log 127.0.0.1   local1 notice
        maxconn 4096
        user haproxy
        group haproxy
        daemon

defaults
        log     global
        mode    http

        option  httplog
        option  dontlognull
        option forwardfor
        option http-server-close

        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms

frontend redirect_80
		bind :80
		redirect scheme https if !{ ssl_fc }

frontend haproxyStats
		bind 127.0.0.1:81
		stats enable
		stats uri /haproxyStats

frontend secure_port
        bind *:443 ssl crt /etc/ssl/certs/server_key.pem force-sslv3 ciphers AES:ALL:!ADH:!EXP:!LOW:!RC2:!3DES:!SEED:!aNULL:!eNULL:!RC4:+HIGH:+MEDIUM
        reqadd X-Forwarded-Proto:\ https

        # Define hosts
        acl host_auth hdr(host) -i api-auth."$MAIN_PROXY_DOMAIN"
        acl host_user hdr(host) -i api-user."$MAIN_PROXY_DOMAIN"
        acl host_banking hdr(host) -i api-banking."$MAIN_PROXY_DOMAIN"
        acl host_backend hdr(host) -i api-backend."$MAIN_PROXY_DOMAIN"
        acl host_company hdr(host) -i api-company."$MAIN_PROXY_DOMAIN"
        acl host_transaction hdr(host) -i api-transaction."$MAIN_PROXY_DOMAIN"
        acl host_search hdr(host) -i api-search."$MAIN_PROXY_DOMAIN"
        acl host_support hdr(host) -i api-support."$MAIN_PROXY_DOMAIN"

        ## figure out which one to use
        use_backend api_auth if host_auth
        use_backend api_user if host_user
        use_backend api_banking if host_banking
        use_backend api_backend if host_backend
        use_backend api_company if host_company
        use_backend api_transaction if host_transaction
        use_backend api_search if host_search
        use_backend api_support if host_support
        
        default_backend api_auth

backend api_auth
        server auth "$AUTH_LB_IP":80 cookie A check

backend api_user
        server user "$USER_LB_IP":80 cookie A check

backend api_banking
        server banking "$BANKING_LB_IP":80 cookie A check

backend api_backend
        server backend "$BACKEND_LB_IP":80 cookie A check

backend api_company
        server company "$COMPANY_LB_IP":80 cookie A check

backend api_transaction
        server transaction "$TRANSACTION_LB_IP":80 cookie A check

backend api_search
        server search "$SEARCH_LB_IP":80 cookie A check

backend api_support
        server support "$SUPPORT_LB_IP":80 cookie A check
" > /etc/haproxy/haproxy.cfg
}

function configureBaspProxy(){
logMessageToFile "INFO"  "configureBaspProxy"
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_API_BASP_CERTIFICATE" "/etc/ssl/certs/api-basp.pem"
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_RABBITMQ_CERTIFICATE" "/etc/ssl/certs/rabbitmq.pem"
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_TRUSTED_CAROOT_CERTIFICATE_PEM" "/etc/ssl/certs/trustedRootCA.pem"
configureHAProxyMonitoringScript
echo "rabbitmq_backend,rabbitmq:lb_rabbitmq
api_basp_backend,basp:lb_api_basp
secure_port,FRONTEND:haproxy" > /usr/local/etc/haproxy-poller.ini

if [ ! -d "/etc/haproxy" ]; then
mkdir /etc/haproxy
fi
echo "global
        log 127.0.0.1   local0
        log 127.0.0.1   local1 notice
        maxconn 4096
        user haproxy
        group haproxy
        daemon

defaults
        log     global
        mode    http

        option  httplog
        option  dontlognull
        timeout connect 50000ms
        timeout client 50000ms
        timeout server 50000ms

frontend redirect_80
        bind :80
        redirect scheme https if !{ ssl_fc }

frontend haproxyStats
        bind 127.0.0.1:81
        stats enable
        stats uri /haproxyStats

frontend secure_port_rabbitmq
        mode tcp
        bind *:5672  ssl crt /etc/ssl/certs/rabbitmq.pem ca-file /etc/ssl/certs/trustedRootCA.pem verify required force-sslv3 ciphers AES:ALL:!ADH:!EXP:!LOW:!RC2:!3DES:!SEED:!aNULL:!eNULL:!RC4:+HIGH:+MEDIUM
        timeout client 1d
        option tcpka
        option tcplog
        acl host_rabbitmq hdr(host) -i rabbitmq."$MAIN_PROXY_DOMAIN"
        use_backend rabbitmq_backend if { ssl_fc_has_crt } host_rabbitmq
        default_backend rabbitmq_backend

frontend secure_port
        bind *:443 ssl crt /etc/ssl/certs/api-basp.pem ca-file /etc/ssl/certs/trustedRootCA.pem verify required force-sslv3 ciphers AES:ALL:!ADH:!EXP:!LOW:!RC2:!3DES:!SEED:!aNULL:!eNULL:!RC4:+HIGH:+MEDIUM
        reqadd X-Forwarded-Proto:\ https
        option forwardfor
        acl host_basp hdr(host) -i api-basp."$MAIN_PROXY_DOMAIN"
        use_backend api_basp_backend if { ssl_fc_has_crt } host_basp
        default_backend api_basp_backend

backend rabbitmq_backend
		mode tcp
		timeout server 1d
        server rabbitmq "$RABBITMQ_LB_IP":5672 check inter 5000 downinter 500

backend api_basp_backend
        server basp "$BASP_LB_IP":80 cookie A check" > /etc/haproxy/haproxy.cfg
}

function configureAdminProxy(){
logMessageToFile "INFO"  "configureAdminProxy"
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_HAPROXY_CERTIFICATE" "/etc/ssl/certs/server_key.pem"
if [ ! -d "/etc/haproxy/errorfiles" ]; then
mkdir -p /etc/haproxy/errorfiles
fi
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_MAINTENANCE_PAGE" "/etc/haproxy/errorfiles/maintenance.http"

configureHAProxyMonitoringScript
echo "rabbimq_console_backend,rabbitmq:rabbimq_console
solr_console_backend,solr:solr_console
zabbix_backend,zabbix:zabbix
secure_port,FRONTEND:haproxy" > /usr/local/etc/haproxy-poller.ini

echo "global
        log 127.0.0.1   local0
        log 127.0.0.1   local1 notice
        maxconn 4096
        user haproxy
        group haproxy
        daemon

defaults
        log     global
        mode    http

        option  httplog
        option  dontlognull
        timeout connect 50000ms
        timeout client 50000ms
        timeout server 50000ms
        errorfile 502 /etc/haproxy/errorfiles/maintenance.http

frontend redirect_80
        bind :80
        redirect scheme https if !{ ssl_fc }

frontend haproxyStats
        bind 127.0.0.1:81
        stats enable
        stats uri /haproxyStats

frontend secure_port
        bind *:443 ssl crt /etc/ssl/certs/server_key.pem force-sslv3 ciphers AES:ALL:!ADH:!EXP:!LOW:!RC2:!3DES:!SEED:!aNULL:!eNULL:!RC4:+HIGH:+MEDIUM
        reqadd X-Forwarded-Proto:\ https

        # Define hosts
        option forwardfor
        acl host_zabbix hdr(host) -i zabbix."$MAIN_PROXY_DOMAIN"
        acl host_rabbitmq hdr(host) -i rabbitmq-console."$MAIN_PROXY_DOMAIN"
        acl host_solr hdr(host) -i solr-console."$MAIN_PROXY_DOMAIN"
		acl is_internal_error status eq 503
        rspideny . if is_internal_error

        use_backend zabbix_backend if host_zabbix
        use_backend rabbimq_console_backend if host_rabbitmq
        use_backend solr_console_backend if host_solr

        default_backend zabbix_backend

backend zabbix_backend
        server zabbix "$ZABBIX_SERVER":80 cookie A check
backend rabbimq_console_backend
		server rabbitmq "$RABBIMQ_CONSOLE":15672 cookie A check
backend solr_console_backend
		server solr "$SOLR_CONSOLE":8080 cookie A check" > /etc/haproxy/haproxy.cfg
}

function configureWebHaProxy(){
logMessageToFile "INFO"  "configureWebHaProxy"
downloadFromSwift "$SWIFT_CERTIFICATES_CONTAINER" "$SWIFT_HAPROXY_CERTIFICATE" "/etc/ssl/certs/server_key.pem"
if [ ! -d "/etc/haproxy/errorfiles" ]; then
mkdir -p /etc/haproxy/errorfiles
fi
downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_MAINTENANCE_PAGE" "/etc/haproxy/errorfiles/maintenance.http"
configureHAProxyMonitoringScript
echo "web_ui,webui:lb_webui
secure_port,FRONTEND:haproxy" > /usr/local/etc/haproxy-poller.ini

echo "global
        log 127.0.0.1   local0
        log 127.0.0.1   local1 notice
        maxconn 4096
        user haproxy
        group haproxy
        daemon

defaults
        log     global
        mode    http

        option  httplog
        option  dontlognull
        option forwardfor
        option http-server-close

        timeout connect 5000ms
        timeout client 50000ms
        timeout server 50000ms
        errorfile 502 /etc/haproxy/errorfiles/maintenance.http

frontend redirect_80
		bind :80
		redirect scheme https if !{ ssl_fc }

frontend haproxyStats
		bind 127.0.0.1:81
		stats enable
		stats uri /haproxyStats

frontend secure_port
        bind *:443 ssl crt /etc/ssl/certs/server_key.pem force-sslv3 ciphers AES:ALL:!ADH:!EXP:!LOW:!RC2:!3DES:!SEED:!aNULL:!eNULL:!RC4:+HIGH:+MEDIUM
        reqadd X-Forwarded-Proto:\ https
        acl is_internal_error status eq 503
        rspideny . if is_internal_error
        default_backend web_ui

backend web_ui
        server webui "$WEBUI_LB_IP":80 cookie A check" > /etc/haproxy/haproxy.cfg
}

function installAndConfigureMainProxy(){
logMessageToFile "INFO"  "installAndConfigureMainProxy"
installMainProxy
configureMainProxy
}

function installAndConfigureBaspProxy(){
logMessageToFile "INFO"  "installAndConfigureBaspProxy"
installMainProxy
configureBaspProxy
}

function installAndConfigureAdminProxy(){
logMessageToFile "INFO"  "installAndConfigureAdminProxy"
installMainProxy
configureAdminProxy
}

function installAndConfigureWebHaProxy(){
logMessageToFile "INFO"  "installAndConfigureWebHaProxy"
installMainProxy
configureWebHaProxy
}

function startHAProxy(){
logMessageToFile "INFO"  "startHAProxy"
haproxy -f /etc/haproxy/haproxy.cfg
}

function startApache(){
logMessageToFile "INFO"  'Starting apache...'
service httpd start
}

function installRabbitMQ(){
logMessageToFile "INFO"  'installRabbitMQ'
installRPM $RABBITMQ_ERLANG_RPM
installRPM $RABBITMQ_ERLANG_COMPAT_RPM
installRPM $RABBITMQ_RPM
}

function setRabbitMQHAPolicy(){
	rabbitmqctl set_policy ha-all "^(?!amq\.).*" '{"ha-mode":"all"}'
}

function setRabbiMQErlangCookie(){
echo "QVLTHWHTIQXBVGOWATMU" > /var/lib/rabbitmq/.erlang.cookie
}

function configureRabbitMQ(){
logMessageToFile "INFO"  "configureRabbitMQ $1"
chkconfig --add rabbitmq-server  
chkconfig --level 234 rabbitmq-server on
echo 'NODENAME=rabbit@'$(hostname)'
NODE_PORT='$RABBITMQ_PORT > /etc/rabbitmq/rabbitmq-env.conf
findAvailableRabbitmq "$RABBITMQ_SERVER_GENERIC" "-01"
rabbit1=$RABBITMQ_SERVER
rabbit1_host=$(findHostByIp $rabbit1)
findAvailableRabbitmq "$RABBITMQ_SERVER_GENERIC" "-02"
rabbit2=$RABBITMQ_SERVER
rabbit2_host=$(findHostByIp $rabbit2)
echo "$rabbit1 $rabbit1_host
$rabbit2 $rabbit2_host" >> /etc/hosts
echo "
[{rabbit,
  [{cluster_nodes, {['rabbit@"$rabbit1_host"', 'rabbit@"$rabbit2_host"'], disc}}]}]." > /etc/rabbitmq/rabbitmq.config
setRabbitMQHAPolicy
setRabbiMQErlangCookie
echo "/var/log/rabbitmq/*.log {
        daily
        missingok
        rotate 20
        compress
        delaycompress
        notifempty
        sharedscripts
        postrotate
            /sbin/service rabbitmq-server rotate-logs > /dev/null
        endscript
}" > /etc/logrotate.d/rabbitmq-server
}

function startRabbitMQ(){
logMessageToFile "INFO"  'Starting rabbitmq...'
service rabbitmq-server start
}

function enablerabbitMQManagementPlugin(){
logMessageToFile "INFO" "enablerabbitMQManagementPlugin"
rabbitmq-plugins enable rabbitmq_management
}

function addRabbitMQUser(){
logMessageToFile "INFO" "addRabbitMQUser"
rabbitmqctl add_user $RABBITMQ_USER $RABBITMQ_PASSWD
rabbitmqctl set_user_tags $RABBITMQ_USER administrator
rabbitmqctl set_permissions -p / $RABBITMQ_USER ".*" ".*" ".*"
}

function removeRabbitMQGuestUser(){
logMessageToFile "INFO" "removeRabbitMQGuestUser"
rabbitmqctl delete_user guest
}

function stopRabbitMQ(){
logMessageToFile "INFO" "Stopping rabbitmq"
rabbitmqctl stop
}

function installAndConfigureRabbitMQ(){
logMessageToFile "INFO" "installAndConfigureRabbitMQ $1"
installRabbitMQ
configureRabbitMQ 
}

function installMYSQL(){
logMessageToFile "INFO"  'installMYSQL'
wget $MYSQL_URL
yum localinstall -y $MYSQL_RPM
checkRPMWasInstalled $MYSQL_RPM
yum install -y mysql-server
checkRPMWasInstalled mysql-server
}

function configureMYSQL(){
mkdir -p $MYSQL_DBPATH/logs
mkdir -p $MYSQL_DBPATH_DATA
mkdir -p $MYSQL_DBPATH_TMP
mkdir -p $MYSQL_DBPATH_UNDO

logMessageToFile "INFO"  'configureMYSQL'
echo "
[client]
socket=/dbfiles/data/mysql.sock

[mysqld]
#General server parameters
datadir = $MYSQL_DBPATH_DATA
tmpdir= $MYSQL_DBPATH_TMP
port = $MYSQL_PORT
server_id = $(echo $myip | awk -F'.' '{print $4}' | tr -d ' ')
bind_address=$myip
character_set_server='utf8'

# InnoDB specific parameters
innodb_undo_directory= $MYSQL_DBPATH_UNDO
innodb_buffer_pool_size = 2048M
innodb_file_per_table=ON
innodb_flush_log_at_trx_commit=1

# Transaction behavior
autocommit=OFF
transaction-isolation=READ-COMMITTED

# Memory sizes
join_buffer_size = 128M
sort_buffer_size = 8M
read_rnd_buffer_size = 8M

# Miscellaneous parameters
sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES,NO_AUTO_CREATE_USER
default_storage_engine=InnoDB

# Enables binary logging
relay_log=$MYSQL_DBPATH/logs/mysql-relay-bin.log
binlog_format=ROW
log_bin=$MYSQL_DBPATH/logs/binlog.log
sync_binlog=1
# gtid_mode=ON
log_slave_updates=ON
# enforce_gtid_consistency=ON

# Disabling symbolic-links is recommended to prevent assorted security risks
symbolic-links=0
" > /etc/my.cnf
chown -R mysql.mysql $MYSQL_DBPATH
}

function startMYSQL(){
logMessageToFile "INFO"  'Starting mysql...'
service mysqld start
}

function installAndConfigureMYSQL(){
installMYSQL
configureMYSQL
}

function installAndConfigureMongoVolume(){
logMessageToFile "INFO"  "Configuring mongo volume..."
if [ ! -z "$(fdisk -l /dev/vdc)" ]; then
pvcreate /dev/vdc
vgcreate  vg_db_files /dev/vdc
totalpe=$(vgdisplay vg_db_files | grep "Total PE" | awk -F' ' '{print $3}')
lvcreate -n lv_db_files  -l $totalpe vg_db_files
mkfs.ext4 /dev/vg_db_files/lv_db_files
mkdir /dbfiles
mount /dev/vg_db_files/lv_db_files /dbfiles
echo '
/dev/vg_db_files/lv_db_files /dbfiles    ext4    defaults    1 2' >> /etc/fstab
else
logMessageToFile "ERROR"  "No mongo volume /dev/vdc found... Skipping..."
fi
}

function installAndConfigureMysqlVolume(){
logMessageToFile "INFO"  "Configuring mysql volume..."
if [ ! -z "$(fdisk -l /dev/vdc)" ]; then
pvcreate /dev/vdc
vgcreate  vg_db_files /dev/vdc
totalpe=$(vgdisplay vg_db_files | grep "Total PE" | awk -F' ' '{print $3}')
lvcreate -n lv_db_files  -l $totalpe vg_db_files
mkfs.ext4 /dev/vg_db_files/lv_db_files
mkdir /dbfiles
mount /dev/vg_db_files/lv_db_files /dbfiles
echo '
/dev/vg_db_files/lv_db_files /dbfiles    ext4    defaults    1 2' >> /etc/fstab
else
logMessageToFile "ERROR"  "No mysql volume /dev/vdc found... Skipping..."
fi
}

function installAndConfigureSolrVolume(){
logMessageToFile "INFO"  "Configuring solr volume..."
if [ ! -z "$(fdisk -l /dev/vdc)" ]; then
pvcreate /dev/vdc
vgcreate  vg_solr_files /dev/vdc
totalpe=$(vgdisplay vg_solr_files | grep "Total PE" | awk -F' ' '{print $3}')
lvcreate -n lv_solr_files  -l $totalpe vg_solr_files
mkfs.ext4 /dev/vg_solr_files/lv_solr_files
mkdir -p $SOLR_HOME/example/solr/data
mount /dev/vg_solr_files/lv_solr_files $SOLR_HOME/example/solr/data
echo "
/dev/vg_solr_files/lv_solr_files $SOLR_HOME/example/solr/data    ext4    defaults    1 2" >> /etc/fstab
else
logMessageToFile "ERROR"  "No solr volume /dev/vdc found... Skipping..."
fi
}


function configureMongoKey(){
#Handling mongo key
logMessageToFile "INFO"  'configureMongoKey'
if [ ! -d "$MONGO_KEY_DIR" ]; then
	mkdir -p $MONGO_KEY_DIR
fi

downloadFromSwift "$SWIFT_UTILS_CONTAINER" "$SWIFT_MONGO_KEY" "$MONGO_KEY"

##########Setting permissions for key file#########
chmod 700 $MONGO_KEY
chown mongod:mongod $MONGO_KEY
}

function bootInstance(){
logMessageToConsole "INFO" "##########################################Creating instance: $1##########################################"

if [ -z "$8" ]; then
	logMessageToConsole "ERROR" "Usage: bootInstance instancename flavor az image secgroup netid key userdata [volumeid]"
	exit 1
fi

local instancename=$1
local flavor=$2
local az=$3
local image=$4
local secgroup=$5
local netid=$6
local key=$7
local userdata=$8
local configparamstopass=$9
local volumeid=${10}
if [ ! -z "$volumeid" ]; then
	volumestring="--block-device source=volume,id=$volumeid,dest=volume,shutdown=preserve"
fi

logMessageToConsole "DEBUG" "nova boot $instancename $configparamstopass --flavor $flavor --availability-zone $az --image $image --security-groups $secgroup --nic net-id=$netid --key-name $key --user-data $userdata $volumestring"
((RETRY_INDEX++))
INSTANCE_ID=`nova boot $instancename $configparamstopass --flavor $flavor --availability-zone $az --image $image --security-groups $secgroup --nic net-id=$netid --key-name $key --user-data $userdata $volumestring | grep " id " | awk -F'|' '{print $3}'`

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
	logMessageToConsole "ERROR" "Instance $INSTANCE_ID created in error... Detele and Retry..."
	nova delete $(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $2}')
	sleep $SHORT_RETRY_INTERVAL
	if [ $RETRY_INDEX -le $RETRY ]; then
		bootInstance $instancename $flavor $az $image $secgroup $netid $key $userdata $configparamstopass $volumestring
	else
		logMessageToConsole "ERROR" "Instance create failed; no more retries.. exiting"
	fi
	

elif [ -z "$INSTANCE_IS_RUNNING" ]; then
	logMessageToConsole "ERROR" "Instance $INSTANCE_ID could not reach running state! Deleting..."
	nova delete $(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $2}')
	sleep $SHORT_RETRY_INTERVAL
	if [ $RETRY_INDEX -le $RETRY ]; then
		bootInstance $instancename $flavor $az $image $secgroup $netid $key $userdata $configparamstopass $volumestring
	else
		logMessageToConsole "ERROR" "Instance create failed; no more retries.. exiting"
	fi
fi

INSTANCE_IP=$(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>2) exit }' | tr -d ' ')
logMessageToConsole "INFO" "Verifying instance $INSTANCE_ID reply to ping at ip $INSTANCE_IP ... Please be patient this could take up to $WAIT_FOR_PING_REPLY  minutes..."
checkInstanceCreatedSuccssfully $INSTANCE_IP

if [ "$?" != "0" ]; then
	TO_BE_DELETED=$TO_BE_DELETED" "$INSTANCE_ID
	exit 1
	if [ $RETRY_INDEX -le $RETRY ]; then
		logMessageToConsole "ERROR" "Instance failed to respond to ping at $INSTANCE_IP . $INSTANCE_IP may be broken... . Recreating ..."
		bootInstance $instancename $flavor $az $image $secgroup $netid $key $userdata $configparamstopass $volumestring
	else
		formExecutionTime
		logMessageToConsole "ERROR" "Instance $INSTANCE  create failed at $INSTANCE_IP . $INSTANCE_IP may be broken... . Time passed: $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"
	fi
else
	formExecutionTime
	logMessageToConsole "INFO" "Instance $INSTANCE was created successfully at ip: $INSTANCE_IP in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"

fi
if [ ! -z "$TO_BE_DELETED" ]; then
	logMessageToConsole "INFO" "Deleting instances: $TO_BE_DELETED"
	nova delete $TO_BE_DELETED
	TO_BE_DELETED=''
fi
rm -f novalist.tmp
}

function getAZName(){
local az_no=$1
local az_name=''
az_name=$(nova availability-zone-list | grep available | awk -F"|" -v awk_az_no=$az_no '{ if ( NR == awk_az_no ) print $2;}')
if [ -z "$az_name" ]; then
	az_name=$(nova availability-zone-list | grep available | awk -F"|" '{ if ( NR == 1 ) print $2;}')
fi
echo $az_name
}

function formExecutionTime(){
ENDTIME=$(date +%s)
ELAPSED_TIME=$(($ENDTIME - $STARTTIME))
HOURS_PASSED=$(($ELAPSED_TIME/$((60*60))))
MINUTES_PASSED=$(($(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))))/60))
SECONDS_PASSED=$(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))-$(($MINUTES_PASSED*60))))
}