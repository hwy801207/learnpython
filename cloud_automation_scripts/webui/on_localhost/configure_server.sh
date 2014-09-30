#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

if [ ! -z "$1" ]; then
	BUILD_NO='-0.0.'$1
fi

. parameters

configureLocalRepo

##########Saving current path##########
PWD=`pwd`

##########Removing old version of service and cleaning repository##########
echo 'Removing old kyweb package ...'
yum --disablerepo="*" --enablerepo="LocalRepo"  remove -y kyweb
sleep 1
echo 'Cleaning repositories ...'
yum clean all
sleep 1



function configureWebUI(){
	sed 's/^$machineIP = .*/$machineIP = \"'$MACHINE_IP'\"; /' -i /opt/kyweb/app/config/kyApiURL.php
	sed 's/^$apiLoc = .*/$apiLoc = $api[$protocol][\"'$DEPLOY_SCHEMA'\"]; /' -i  /opt/kyweb/app/config/kyApiURL.php
	sed "s/'kypay' => .*/\'kypay\' => \'"$FLOW_APPLY_KYPAY"\',/" -i  /opt/kyweb/app/config/kyApiURL.php
	sed "s/'che001' => .*/\'che001\' => \'"$FLOW_REGISTER_COMPANY_USER"\', /" -i  /opt/kyweb/app/config/kyApiURL.php
}

##########Installing last RPM buld of service##########
echo 'Instaling service kyweb...'
yum --disablerepo="*" --enablerepo="LocalRepo" install -y 'kyweb'$BUILD_NO
echo 'Configuring service kyweb'

configureWebUI

cd $PWD
echo "Done..."