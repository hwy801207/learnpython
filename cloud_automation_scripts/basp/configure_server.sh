#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

. parameters
. functions

configureLocalRepo

if [ -z "$1" ]; then
	echo "Please enter basp-build no. ex. $0 0.2.402"
	exit 1
fi

BUILD_NO=$1

##########Saving current path##########
PWD=`pwd`

##########Removing old version of service and cleaning repository##########
uninstallService "basp-api"

##########Installing last RPM buld of service##########
installService "basp-api-$BUILD_NO"
if [ "$?" == "4" ]; then
exit 4
fi

##########Configuring##########
logMessageToConsole "INFO" 'Configuring service basp-api'
cd /opt/ky/basp-api/*api-*/conf/

##########Configuring db file##########
if [ ! -z "$ORACLE_CONN_STRING" ]; then
echo 'ky.basp.common.oracle.connection.string=jdbc:oracle:thin:@'$ORACLE_CONN_STRING > db.properties
else
echo 'ky.basp.common.oracle.connection.string=jdbc:oracle:thin:@'$ORACLE_SERVER':'$ORACLE_PORT':XE' > db.properties
fi

echo 'ky.basp.common.oracle.username='$ORACLE_USERNAME'
ky.basp.common.oracle.password='$ORACLE_PASSWORD'' >> db.properties

##########Configuring service##########
echo '
ky.basp.common.platformapi.basp.host='$API_BASP_PROTOCOL''$API_BASP_HOST':'$API_BASP_PORT'
ky.basp.common.keystore.path='$KEYSTORE'
ky.basp.common.keystore.pass='$KEYSTORE_PASS'
ky.basp.common.truesstore.path='$TRUSTSTORE'
ky.basp.common.platformapi.banking.settlement.results.route='$SETTLEMENT_ROUTE'
ky.basp.common.platformapi.banking.billing.results.route='$BILLING_ROUTE'

ky.basp.common.ext.rabbitmq.server.hosts='$RABBITMQ_EXT_SERVER':'$RABBITMQ_EXT_PORT'
ky.basp.common.ext.rabbitmq.username='$RABBITMQ_EXT_USER'
ky.basp.common.ext.rabbitmq.password='$RABBITMQ_EXT_PASSWD'
ky.basp.common.ext.rabbitmq.poll.timeout=15000
ky.basp.common.ext.rabbitmq.recovery.automatic=true
ky.basp.common.ext.rabbitmq.recovery.topology=false
ky.basp.common.ext.rabbitmq.recovery.interval=5000
ky.basp.common.ext.rabbitmq.ssl='$RABBITMQ_EXT_SSL'
ky.basp.common.ext.rabbitmq.ssl.cert.path='$RABBITMQ_KEYSTORE'
ky.basp.common.ext.rabbitmq.ssl.cert.pass='$RABBITMQ_KEYSTORE_PASS'
ky.basp.common.ext.rabbitmq.ssl.trust.path='$RABBITMQ_TRUSTSTORE'
ky.basp.common.ext.rabbitmq.ssl.trust.pass='$RABBITMQ_TRUSTSTORE_PASS'

ky.core.common.rabbitmq.server.hosts='$RABBITMQ_SERVER':'$RABBITMQ_PORT'
ky.core.common.rabbitmq.username='$RABBITMQ_USER'
ky.core.common.rabbitmq.password='$RABBITMQ_PASSWD'

ky.core.common.rabbitmq.poll.timeout=-1
ky.core.common.rabbitmq.recovery.automatic=true
ky.core.common.rabbitmq.recovery.topology=true
ky.core.common.rabbitmq.recovery.interval=60000
ky.core.common.rabbitmq.recovery.push.interval=2000
ky.core.common.rabbitmq.recovery.count=2
ky.core.common.rabbitmq.recovery.sleep=300000

' > instance.properties

configureHOSTS

cd $PWD
echo "Done..."