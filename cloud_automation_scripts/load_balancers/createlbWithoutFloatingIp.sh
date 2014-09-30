#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ]; then
echo "Please enter environment ex. 
	./createlbWithoutFloatingIp.sh http_company_lb 5bdbf0b9-58b4-412d-b767-d0ae7c80760a HTTPS prod 172.24.0.200
	./createlbWithoutFloatingIp.sh http_company_lb 5bdbf0b9-58b4-412d-b767-d0ae7c80760a HTTP stage 172.24.0.200
	./createlbWithoutFloatingIp.sh http_company_lb 5bdbf0b9-58b4-412d-b767-d0ae7c80760a TCP stage 172.24.0.200
	"
exit 1
fi
LB_NAME=$1
LB_HEALTH_MONITOR=$2
LB_PROTOCOL=$3
ENVIRONMENT=$4
IP=$5

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

. parameters

LB_METHOD='ROUND_ROBIN'

checkNovaAndNeutron

if [ "$LB_PROTOCOL" == 'HTTP' ]; then
	VIP_PORT=80
elif [ "$LB_PROTOCOL" == 'HTTPS' ]; then
	VIP_PORT=443
elif [ "$LB_PROTOCOL" == 'TCP' ]; then
	VIP_PORT=5672
fi

logMessageToConsole "INFO" "Creating lb pool $LB_NAME using protocol $LB_PROTOCOL"
LB=$(neutron lb-pool-create --lb-method $LB_METHOD --name $LB_NAME --protocol $LB_PROTOCOL --subnet-id $LB_SUBNET_ID | grep 'Created a new pool')
if [ -z "$LB" ]; then
	logMessageToConsole "ERROR" "coud not create lb... exiting"
	exit 1
fi

logMessageToConsole "INFO" "Associating health monitor $LB_HEALTH_MONITOR to $LB_NAME"
HEALTH_MESSAGE=$(neutron lb-healthmonitor-associate $LB_HEALTH_MONITOR $LB_NAME)

if [ -z "$(echo $HEALTH_MESSAGE | grep Associated)" ]; then
	logMessageToConsole "WARNING" "Coud not attach monitor for lb..."
fi

logMessageToConsole "INFO" "Creating vip ${LB_NAME}_vip on protocol $LB_PROTOCOL subnet $LB_SUBNET_ID listenning on port $VIP_PORT for load balancer pool $LB_NAME"
ADDRESS=$(neutron lb-vip-create --name $LB_NAME'_vip' --protocol $LB_PROTOCOL --subnet-id $LB_SUBNET_ID --protocol-port $VIP_PORT $LB_NAME --address $IP | grep ' address ' | awk -F'|' '{print $3}')

if [ -z "$ADDRESS" ]; then
	logMessageToConsole "ERROR" 'Coud not create vip for lb... exiting'
	exit 1
fi
