#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" -o -z "$5" ]; then
echo "Please enter environment ex. 
		./createlb.sh http_company_lb 203.130.40.120 5bdbf0b9-58b4-412d-b767-d0ae7c80760a http stge 
		./createlb.sh http_company_lb 203.130.40.120 5bdbf0b9-58b4-412d-b767-d0ae7c80760a http prod
		"
exit 1
fi
LB_NAME=$1
FLOATING_IP_ADDRESS=$2
LB_HEALTH_MONITOR=$3
LB_PROTOCOL=$4
ENVIRONMENT=$5

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

. parameters


LB_METHOD='ROUND_ROBIN'

checkNovaAndNeutron

if [ "$LB_PROTOCOL" == 'HTTP' ]; then
	VIP_PORT=80
else
	VIP_PORT=443
fi

echo 'Creating lb pool '$LB_NAME' using protocol '$LB_PROTOCOL
LB=$(neutron lb-pool-create --lb-method $LB_METHOD --name $LB_NAME --protocol $LB_PROTOCOL --subnet-id $LB_SUBNET_ID | grep 'Created a new pool')
if [ -z "$LB" ]; then
	logMessageToConsole "ERROR" "coud not create lb... exiting"
	exit 1
fi

logMessageToConsole "INFO" "Associating health monitor $LB_HEALTH_MONITOR' to $LB_NAME"
HEALTH_MESSAGE=$(neutron lb-healthmonitor-associate $LB_HEALTH_MONITOR $LB_NAME)

if [ -z "$(echo $HEALTH_MESSAGE | grep Associated)" ]; then
	logMessageToConsole "WARNING" "Coud not attach monitor for lb..."
fi

logMessageToConsole "INFO" "Creating vip ${LB_NAME}_vip on protocol $LB_PROTOCOL subnet $LB_SUBNET_ID listenning on port $VIP_PORT for load balancer pool $LB_NAME"
ADDRESS=$(neutron lb-vip-create --name $LB_NAME'_vip' --protocol $LB_PROTOCOL --subnet-id $LB_SUBNET_ID --protocol-port $VIP_PORT $LB_NAME | grep ' address ' | awk -F'|' '{print $3}')

if [ -z "$ADDRESS" ]; then
	logMessageToConsole "ERROR" "Coud not create vip for lb... exiting"
	exit 1
fi

logMessageToConsole "INFO" "Searching for availability of floating ip $FLOATING_IP_ADDRESS"
FLOATING_IP_ID=$(neutron floatingip-list | grep $FLOATING_IP_ADDRESS | awk -F'|' '{print $2}')

if [ -z "$FLOATING_IP_ID" ]; then
	logMessageToConsole "ERROR" "Floating ip not found... exiting"
	exit 1
fi

logMessageToConsole "INFO" "Searching for port on vip created at address $ADDRESS"
VIP_PORT_ID=$(neutron port-list | grep 'vip' | grep $ADDRESS | awk -F'|' '{print $2}' )

if [ -z "$VIP_PORT_ID" ]; then
	logMessageToConsole "ERROR" "VIP_PORT_ID=$VIP_PORT_ID not found... There was a problem with the VIP ... exiting"
	exit 1
fi

logMessageToConsole "INFO" "'Associating floating ip id $FLOATING_IP_ID to fixed ip $ADDRESS found on vip port $VIP_PORT_ID"
IP_MESSAGE=$(neutron floatingip-associate --fixed-ip-address $ADDRESS $FLOATING_IP_ID $VIP_PORT_ID)
if [ -z "$(echo $IP_MESSAGE | grep 'Associated floatingip')" ]; then
	logMessageToConsole "ERROR" "There was a problem associating floating ip ... exiting"
	exit 1
fi