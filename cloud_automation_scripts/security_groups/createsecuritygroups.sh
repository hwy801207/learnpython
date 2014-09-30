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

##############function used to create the empty groups##############
function createGroups(){
nova secgroup-create $SOLR_SECURITY_GROUP $SOLR_SECURITY_GROUP
nova secgroup-create $WEBUI_SECURITY_GROUP $WEBUI_SECURITY_GROUP
nova secgroup-create $REDIS_SECURITY_GROUP $REDIS_SECURITY_GROUP
nova secgroup-create $RABBITMQ_SECURITY_GROUP $RABBITMQ_SECURITY_GROUP
nova secgroup-create $MONGO_SECURITY_GROUP $MONGO_SECURITY_GROUP
nova secgroup-create $MYSQL_SECURITY_GROUP $MYSQL_SECURITY_GROUP
nova secgroup-create $ZABBIX_SECURITY_GROUP $ZABBIX_SECURITY_GROUP
nova secgroup-create $API_SECURITY_GROUP $API_SECURITY_GROUP
nova secgroup-create $CORE_SECURITY_GROUP $CORE_SECURITY_GROUP
nova secgroup-create $LBWEB_SECURITY_GROUP $LBWEB_SECURITY_GROUP
nova secgroup-create $MAIN_PROXY_SECURITY_GROUP $MAIN_PROXY_SECURITY_GROUP
nova secgroup-create $BASP_PROXY_SECURITY_GROUP $BASP_PROXY_SECURITY_GROUP
nova secgroup-create $ADMIN_PROXY_SECURITY_GROUP $ADMIN_PROXY_SECURITY_GROUP
nova secgroup-create $REPOSITORY_SECURITY_GROUP $REPOSITORY_SECURITY_GROUP
nova secgroup-create $ADMINSERVER_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP
}

##############function used to configure solr security group##############
function configureSolrGroup(){
nova secgroup-add-group-rule $SOLR_SECURITY_GROUP $SOLR_SECURITY_GROUP tcp $SOLR_PORT_START $SOLR_PORT_STOP
nova secgroup-add-group-rule $SOLR_SECURITY_GROUP $ADMIN_PROXY_SECURITY_GROUP tcp $SOLR_PORT_START $SOLR_PORT_STOP
nova secgroup-add-group-rule $SOLR_SECURITY_GROUP $API_SECURITY_GROUP tcp $SOLR_PORT_START $SOLR_PORT_STOP
nova secgroup-add-group-rule $SOLR_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $SOLR_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $SOLR_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure webui security group##############
function configureWebuiGroup(){
nova secgroup-add-group-rule $WEBUI_SECURITY_GROUP $LBWEB_SECURITY_GROUP tcp $WEBUI_PORT_START $WEBUI_PORT_STOP
nova secgroup-add-group-rule $WEBUI_SECURITY_GROUP default tcp $WEBUI_PORT_START $WEBUI_PORT_STOP
nova secgroup-add-group-rule $WEBUI_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $WEBUI_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $WEBUI_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure redis security group##############
function configureRedisGroup(){
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $REDIS_SECURITY_GROUP tcp $REDIS_PORT_REDIS_START $REDIS_PORT_REDIS_STOP
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $API_SECURITY_GROUP tcp $REDIS_PORT_FOR_API_START $REDIS_PORT_FOR_API_STOP
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $CORE_SECURITY_GROUP tcp $REDIS_PORT_FOR_API_START $REDIS_PORT_FOR_API_STOP
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $REDIS_SECURITY_GROUP tcp $REDIS_PORT_FOR_API_START $REDIS_PORT_FOR_API_STOP
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $WEBUI_SECURITY_GROUP tcp $REDIS_PORT_FOR_WEBUI_START $REDIS_PORT_FOR_WEBUI_STOP
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $REDIS_SECURITY_GROUP tcp $REDIS_PORT_FOR_WEBUI_START $REDIS_PORT_FOR_WEBUI_STOP
nova secgroup-add-group-rule $REDIS_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $REDIS_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure rabbitmq security group##############
function configureRabbitmqGroup(){
nova secgroup-add-group-rule $RABBITMQ_SECURITY_GROUP $RABBITMQ_SECURITY_GROUP tcp 1 65535
nova secgroup-add-group-rule $RABBITMQ_SECURITY_GROUP $ADMIN_PROXY_SECURITY_GROUP tcp $RABBITMQ_ADMIN_PORT_START $RABBITMQ_ADMIN_PORT_STOP
nova secgroup-add-group-rule $RABBITMQ_SECURITY_GROUP $CORE_SECURITY_GROUP tcp $RABBITMQ_PORT_START $RABBITMQ_PORT_STOP
nova secgroup-add-group-rule $RABBITMQ_SECURITY_GROUP default tcp $RABBITMQ_PORT_START $RABBITMQ_PORT_STOP
nova secgroup-add-group-rule $RABBITMQ_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $RABBITMQ_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $RABBITMQ_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure mongo security group##############
function configureMongoGroup(){
nova secgroup-add-group-rule $MONGO_SECURITY_GROUP $MONGO_SECURITY_GROUP tcp $MONGO_PORT_START $MONGO_PORT_STOP
nova secgroup-add-group-rule $MONGO_SECURITY_GROUP $CORE_SECURITY_GROUP tcp $MONGO_PORT_START $MONGO_PORT_STOP
nova secgroup-add-group-rule $MONGO_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $MONGO_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $MONGO_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure mysql security group##############
function configureMySQLGroup(){
nova secgroup-add-group-rule $MYSQL_SECURITY_GROUP $MYSQL_SECURITY_GROUP tcp $MYSQL_PORT_START $MYSQL_PORT_STOP
nova secgroup-add-group-rule $MYSQL_SECURITY_GROUP $CORE_SECURITY_GROUP tcp $MYSQL_PORT_START $MYSQL_PORT_STOP
nova secgroup-add-group-rule $MYSQL_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $MYSQL_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $MYSQL_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure zabbix security group##############
function configureZabbixGroup(){
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $ADMIN_PROXY_SECURITY_GROUP tcp $ZABBIX_WEBUI_PORT $ZABBIX_WEBUI_PORT
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $SOLR_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $WEBUI_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $REDIS_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $RABBITMQ_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $MONGO_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $MYSQL_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $API_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $CORE_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $LBWEB_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $MAIN_PROXY_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $BASP_PROXY_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $ADMIN_PROXY_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $ZABBIX_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $ZABBIX_SECURITY_GROUP tcp $ZABBIX_WEBUI_PORT $ZABBIX_WEBUI_PORT $EXTERN_IP_CLASS
nova secgroup-add-rule $ZABBIX_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure api security group##############
function configureApiGroup(){
nova secgroup-add-group-rule $API_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $API_PORT_START $API_PORT_STOP
nova secgroup-add-group-rule $API_SECURITY_GROUP default tcp $API_PORT_START $API_PORT_STOP
nova secgroup-add-group-rule $API_SECURITY_GROUP $WEBUI_SECURITY_GROUP tcp $API_PORT_START $API_PORT_STOP
nova secgroup-add-group-rule $API_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp 1 65535
nova secgroup-add-group-rule $API_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $API_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure core security group##############
function configureCoreGroup(){
nova secgroup-add-group-rule $CORE_SECURITY_GROUP $CORE_SECURITY_GROUP tcp $CORE_PORT_START $CORE_PORT_STOP
nova secgroup-add-group-rule $CORE_SECURITY_GROUP $API_SECURITY_GROUP tcp $CORE_PORT_START $CORE_PORT_STOP
nova secgroup-add-group-rule $CORE_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp 1 65535
nova secgroup-add-group-rule $CORE_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $CORE_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure lbweb security group##############
function configureLbWebGroup(){
nova secgroup-add-group-rule $LBWEB_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-rule $LBWEB_SECURITY_GROUP tcp $LBWEB_PORT1_START $LBWEB_PORT1_STOP $EXTERN_IP_CLASS
nova secgroup-add-rule $LBWEB_SECURITY_GROUP tcp $LBWEB_PORT2_START $LBWEB_PORT2_STOP $EXTERN_IP_CLASS
nova secgroup-add-group-rule $LBWEB_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $LBWEB_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure mainproxy security group##############
function configureMainProxyGroup(){
nova secgroup-add-group-rule $MAIN_PROXY_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-rule $MAIN_PROXY_SECURITY_GROUP tcp $MAIN_PROXY_PORT_START $MAIN_PROXY_PORT_STOP $EXTERN_IP_CLASS
nova secgroup-add-group-rule $MAIN_PROXY_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $MAIN_PROXY_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure baspproxy security group##############
function configureBaspProxyGroup(){
nova secgroup-add-group-rule $BASP_PROXY_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-rule $BASP_PROXY_SECURITY_GROUP tcp $BASP_PROXY_PORT_START_1 $BASP_PROXY_PORT_STOP_1 $BASP_IP_CLASS
nova secgroup-add-rule $BASP_PROXY_SECURITY_GROUP tcp $BASP_PROXY_PORT_START_2 $BASP_PROXY_PORT_STOP_2 $BASP_IP_CLASS
nova secgroup-add-group-rule $BASP_PROXY_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $BASP_PROXY_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure adminproxy security group##############
function configureAdminProxyGroup(){
nova secgroup-add-group-rule $ADMIN_PROXY_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-rule $ADMIN_PROXY_SECURITY_GROUP tcp $ADMIN_PROXY_PORT_START $ADMIN_PROXY_PORT_STOP $SV_IP_CLASS
nova secgroup-add-rule $ADMIN_PROXY_SECURITY_GROUP tcp $ADMIN_PROXY_PORT_START $ADMIN_PROXY_PORT_STOP $CN_IP_CLASS
nova secgroup-add-group-rule $ADMIN_PROXY_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $ADMIN_PROXY_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure repository security group##############
function configureRepositoryGroup(){
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $SOLR_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $WEBUI_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $REDIS_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $RABBITMQ_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $MONGO_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $MYSQL_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $API_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $CORE_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $LBWEB_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $MAIN_PROXY_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $ADMIN_PROXY_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $BASP_PROXY_SECURITY_GROUP tcp $REPOSITORY_PORT_START $REPOSITORY_PORT_STOP
nova secgroup-add-group-rule $REPOSITORY_SECURITY_GROUP $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT
nova secgroup-add-rule $REPOSITORY_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure adminserver security group##############
function configureAdminServerGroup(){
nova secgroup-add-group-rule $ADMINSERVER_SECURITY_GROUP $ZABBIX_SECURITY_GROUP tcp $ZABBIX_PORT_START $ZABBIX_PORT_STOP
nova secgroup-add-rule $ADMINSERVER_SECURITY_GROUP tcp $SSH_PORT $SSH_PORT $EXTERN_IP_CLASS
nova secgroup-add-rule $ADMINSERVER_SECURITY_GROUP icmp -1 -1 $EXTERN_IP_CLASS
}

##############function used to configure all security groups##############
function configureGroups(){
configureSolrGroup
configureWebuiGroup
configureRedisGroup
configureRabbitmqGroup
configureMongoGroup
configureMySQLGroup
configureZabbixGroup
configureApiGroup
configureCoreGroup
configureLbWebGroup
configureMainProxyGroup
configureBaspProxyGroup
configureAdminProxyGroup
configureRepositoryGroup
configureAdminServerGroup
}

##############main function##############
function main(){
createGroups
configureGroups
}

##############run main function##############
main