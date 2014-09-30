if [ -z "$1" -o -z "$2" -o -z "$3" -o -z "$4" ]; then
echo "Please enter rpm version, replica set, instances group and environment ./removeZabbixHosts.sh 123 01 01 stage"
exit 1
fi
BUILD_NO=$1
REPLICA_SET=$2
INSTANCES_NO=$3
ENVIRONMENT=$4

. ../../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

HOSTNAME=(api-auth api-backend api-banking api-basp api-company api-search api-support api-transaction api-user core-backend  core-banking core-company core-encryption core-engine core-file core-messaging core-transaction core-user)

for i in{0..18}
do

AUTH_REPONSE=$(wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$AUTH_METHOD\",\"params\": {\"user\": \"admin\",\"password\": \"zabbix\"},\"auth\": null,\"id\": 0}")
AUTH_TOKEN=$( echo $AUTH_REPONSE | awk '{split($0,array,":"); split(array[3],array1,"\"")} END{print array1[2]}')

HOST_RESPONSE=$(wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$GET_HOST\",\"params\": {\"output\": \"hostids\",\"filter\": {\"host\":\"$HOSTNAME-BUILD_NO-rs$REPLICA_SET-$INSTANCES_NO\"}},\"auth\": \"$AUTH_TOKEN\",\"id\": 1}")
HOST_ID=$( echo $HOST_RESPONSE | awk '{split ($0,array,"\"")} END{print array[10]}')


wget -O- -o /dev/null $ZABBIX_API --header 'Content-Type: application/json-rpc' --post-data "{\"jsonrpc\": \"2.0\",\"method\": \"$DELETE_HOST\",\"params\":[\"$HOST_ID\"],\"auth\": \"$AUTH_TOKEN\",\"id\": 1}"

done