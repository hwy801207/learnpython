#!/bin/bash

##########We need to have environment specified##########
if [ -z "$1" ]; then
echo "Please enter environment ex. ./createsecuritygroups.sh prod | ./createsecuritygroups.sh stage"
exit 1
fi
ENVIRONMENT=$1

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT


. parameters

function deleteGroup(){
if [ -z "$1" ];then
echo "Empty security group received to delete ! Skipped !"
return 1
fi
echo "Deleting security group $1"
nova secgroup-delete $1
}

function deleteGroups(){
deleteGroup $SOLR_SECURITY_GROUP 
deleteGroup $WEBUI_SECURITY_GROUP 
deleteGroup $REDIS_SECURITY_GROUP 
deleteGroup $RABBITMQ_SECURITY_GROUP 
deleteGroup $MONGO_SECURITY_GROUP 
deleteGroup $MYSQL_SECURITY_GROUP 
deleteGroup $ZABBIX_SECURITY_GROUP
deleteGroup $API_SECURITY_GROUP 
deleteGroup $CORE_SECURITY_GROUP
deleteGroup $LBWEB_SECURITY_GROUP 
deleteGroup $MAIN_PROXY_SECURITY_GROUP 
deleteGroup $BASP_PROXY_SECURITY_GROUP 
deleteGroup $ADMIN_PROXY_SECURITY_GROUP
deleteGroup $REPOSITORY_SECURITY_GROUP
deleteGroup $ADMINSERVER_SECURITY_GROUP 
}

deleteGroups