#! /bin/bash
STARTTIME=$(date +%s)

if [ -z "$1" ]; then
echo "Please enter environment ex. 
                ./add_cloud_instances.sh stage 
                ./add_cloud_instances.sh prod
                "
exit 1
fi
ENVIRONMENT=$1

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

WAIT_FOR_IP_TO_BE_UP=1     #minutes
WAIT_FOR_PING_REPLY=1      #minutes
RETRY_INTERVAL=5           #DEFAULT 5 seconds ; must be under 60 seconds

function waitForPrimaryToBeUp(){
FLOATING_IP=$1
logMessageToConsole "INFO" 'Waiting for primary to be up...'
j=1
while [ $j -le $(($WAIT_FOR_IP_TO_BE_UP*$((60/$RETRY_INTERVAL))))  -a -z "$IS_UP" ]
do
        nova list  >  novalist.tmp
        IS_UP=$(grep $FLOATING_IP novalist.tmp)
        ((j++))
        sleep $RETRY_INTERVAL
done
if [ -z "$IS_UP" ]; then
logMessageToConsole "ERROR" 'The ip was not taken by instance... Something went wrong ... Exiting'
exit 1
fi
REPLY=''
i=1
while [ $i -le $(($WAIT_FOR_PING_REPLY*$((60/$RETRY_INTERVAL)))) ]
do

        ping -q -c 1 $FLOATING_IP > /dev/null
        if [ "$?" -eq "0" ]; then
                REPLY=1
                i=$(($WAIT_FOR_PING_REPLY*$((60/$RETRY_INTERVAL))))
        fi
        ((i++))
        sleep $RETRY_INTERVAL
done
if [ -z "$REPLY" ]; then
logMessageToConsole "ERROR" 'The ip did not replied to ping... Something went wrong ... Exiting'
exit 1
fi
}

AVAILABILITY_ZONE_1=$(getAZName 1)
AVAILABILITY_ZONE_2=$(getAZName 2)

##########main-proxy creating process##########
logMessageToConsole "INFO" "Creating main-proxy instances"
./createinstance.sh "$BASP_PROXY_GENERIC-01" $AVAILABILITY_ZONE_1 $ENVIRONMENT $BASP_PROXY_STATIC_IP1
exitIfNotSuccess "$?"
nova add-floating-ip "$BASP_PROXY_GENERIC-01" $BASP_PROXY_FLOATING_IP
waitForPrimaryToBeUp $BASP_PROXY_FLOATING_IP
#./createinstance.sh "$BASP_PROXY_GENERIC-02" $AVAILABILITY_ZONE_2 $ENVIRONMENT $BASP_PROXY_STATIC_IP2
#nova add-floating-ip "$BASP_PROXY_GENERIC-02" $BASP_PROXY_FLOATING_IP_2
#waitForPrimaryToBeUp $BASP_PROXY_FLOATING_IP_2

formExecutionTime
logMessageToConsole "INFO" "Add cloud instances execution time $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"