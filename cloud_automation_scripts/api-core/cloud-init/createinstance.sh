#! /bin/bash

STARTTIME=$(date +%s)

##########Prerequisites##########
# 1. Nova is installed
# 2. This script is beeing runned from the cloud admin server 
# 3. The instances are beeing created using cloud admin server key which is added in nova as cloud_admin_ssh_key

##########We need to have group of instances no specified##########
if [ -z "$1" ]; then
echo "Please enter instance name (ex: core-user-01)"
exit 1
fi


##########Constants##########
INSTANCE=$1

# PARAMETERS FILES
SWIFT_PARAM_FILE='config_params.sh'
SWIFT_FUNC_FILE='config_func.sh'
SWIFT_UTILS_CONTAINER='script_utils'

#OpenStack config
export OS_TENANT_NAME=admin
export OS_USERNAME=kycloud
export OS_PASSWORD=kycloud
export OS_AUTH_URL="http://192.168.150.98:5000/v2.0/"
export OS_AUTH_STRATEGY=keystone

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

##########We need to have group of instances no specified##########
nova list  >  novalist.tmp
INSTANCE_ALREADY_EXISTS=$(grep $INSTANCE novalist.tmp)

if [ ! -z "$INSTANCE_ALREADY_EXISTS" ]; then
	echo "At least one instance with that name exist... Please delete first or change instances name"
	rm -f novalist.tmp
	exit 1
fi

rm -f novalist.tmp

##########Function to create a valid instance##########
function createInstance(){
echo "Creating instance: "$1
((RETRY_INDEX++))
INSTANCE_ID=`nova boot $1 --flavor 1 --image centos-6.5-X86-64-20140127 --security-groups default --nic net-id=3aa866e3-54b4-460f-9da3-fd998d69f4cf --key-name cloud_admin_ssh_key --user-data install_v2.sh | grep " id " | awk -F'|' '{print $3}'`

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
	echo "Instance "$INSTANCE_ID" created in error... Detele and Retry..."
	nova delete $(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $2}')
	sleep $SHORT_RETRY_INTERVAL
	if [ $RETRY_INDEX -le $RETRY ]; then
		createInstance $1
	else
		echo "Instance create failed; no more retries.. exiting"
	fi
	

elif [ -z "$INSTANCE_IS_RUNNING" ]; then
	echo "Instance "$INSTANCE_ID" could not reach running state! Deleting..."
	nova delete $(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $2}')
	sleep $SHORT_RETRY_INTERVAL
	if [ $RETRY_INDEX -le $RETRY ]; then
		createInstance $1
	else
		echo "Instance create failed; no more retries.. exiting"
	fi
fi

echo "Verifying instance "$INSTANCE_ID" reply to ping... Please be patient this could take up to "$WAIT_FOR_PING_REPLY " minutes"
INSTANCE_IP=$(grep $INSTANCE_ID novalist.tmp | awk -F'|' '{print $7}' | awk -F'=' '{print $2}' | awk -F',' '{if ( count==0 ) print $1 ; count++; if(count>2) exit }' | tr -d ' ')
checkInstanceCreatedSuccssfully $INSTANCE_IP

if [ "$?" != "0" ]; then
	echo "Instance failed to respond to ping. Recreating ..."
	TO_BE_DELETED=$TO_BE_DELETED" "$INSTANCE_ID
	if [ $RETRY_INDEX -le $RETRY ]; then
		createInstance $1
	else
		echo "Instance create failed; no more retries.. exiting"
	fi
else
	echo "Instance created successfully!"
fi

if [ ! -z "$TO_BE_DELETED" ]; then
	echo "Deleting broken instance:" $TO_BE_DELETED
	nova delete $TO_BE_DELETED
	TO_BE_DELETED=""
fi

rm -f novalist.tmp
}

createInstance $INSTANCE

ENDTIME=$(date +%s)
ELAPSED_TIME=$(($ENDTIME - $STARTTIME))
HOURS_PASSED=$(($ELAPSED_TIME/$((60*60))))
MINUTES_PASSED=$(($(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))))/60))
SECONDS_PASSED=$(($ELAPSED_TIME-$(($HOURS_PASSED*60*60))-$(($MINUTES_PASSED*60))))

echo "Instance $INSTANCE were created successfully at ip: $INSTANCE_IP in $HOURS_PASSED hours $MINUTES_PASSED minutes $SECONDS_PASSED seconds"