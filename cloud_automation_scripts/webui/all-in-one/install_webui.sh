#!/bin/bash

SERVICE=$1
STARTTIME=$(date +%s)

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

# PARAMETERS FILE
SWIFT_UTILS_CONTAINER='script_utils'

. /tmp/config_params.sh
. /tmp/config_func.sh

rm -f  /tmp/config_params.sh /tmp/config_func.sh

setHostname
configureLocalRepo
addKydevUser
removeDevopsUserSudoPassword

##########If no input parameter use hostname as service##########
if [ -z "$1" ]; then
	SERVICE=$(hostname)
fi
TYPE=$(echo $SERVICE | awk -F'-' '{print $1}')

##########Getting curent host ip##########
 findMyIP

##########If current ip not found exit##########
if [ -z "$myip" ]; then
	logMessageToFile "ERROR"  "Could not get your ip for the specified host $(hostname)... $SERVICE not installed! "
	exit 1;
fi

configureHostname

##########Saving current directory path##########
PWD_DIR=$(pwd)

installAndConfigureWebui
startApache

installAndConfigureZabbixOnWebUI
startZabbix

formExecutionTime
logMessageToFile "INFO"  "Instance was installed and configured successfully in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"