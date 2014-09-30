#!/bin/bash

##########Script needs to be runned under root privileges##########
if [ "$UID" -ne 0 ]; then
echo "Please run this bash script as root !"
exit 1
fi

##########LOCAL REPO config parameters##########
LOCAL_REPO='192.168.150.253'

##########Parameters##########
CONNECTIONS_ALIVE_TIME_OUT=1 # if connections are not closed after one minute abort starting ...
SLEEP_TIME=2 # seconds to sleep between two connection closed checks
PORT_USER=10001
PORT_COMPANY=11001
PORT_BANKING=12001
PORT_MESSAGING=13001
PORT_FILE=14001
PORT_ENCRYPTION=17001
PORT_ENGINE=18001
PORT_API_USER=9000
PORT_API_AUTH=9001
PORT_API_BANKING=9005
PORT_API_COMPANY=9004
PORT_API_SUPPORT=9006
PORT_API_SEARCH=9003
PORT_API_TRANSACTION=9007
PORT_SEARCH_STRING=$PORT_USER"\|"$PORT_COMPANY"\|"$PORT_BANKING"\|"$PORT_MESSAGING"\|"$PORT_FILE"\|"$PORT_ENCRYPTION"\|"$PORT_ENGINE"\|"$PORT_API_USER"\|"$PORT_API_AUTH"\|"$PORT_API_BANKING"\|"$PORT_API_COMPANY"\|"$PORT_API_SUPPORT"\|"$PORT_API_SEARCH"\|"$PORT_API_TRANSACTION

rm -f /etc/yum.repos.d/localrepo.repo 
echo '[LocalRepo]
name=KY-Local-Repo
baseurl=file:///home/kysysadmin/localrepo
enabled=1
gpgcheck=0' > /etc/yum.repos.d/localrepo.repo
chmod 644 /etc/yum.repos.d/localrepo.repo

##########Stopping services##########
./stop.sh

##########Installing and configuring cores##########
echo "Installing and configuring core-user default instance ..."
./configure_server.sh 'core-user'
sleep 1
echo "Core-user instance installed ..."

echo "Installing and configuring core-engine instance ..."
./configure_server.sh 'core-engine' 
sleep 1
echo "Core-engine instance installed ..."

echo "Installing and configuring core-banking instance ..."
./configure_server.sh 'core-banking' 
sleep 1
echo "Core-banking instance installed ..."

echo "Installing and configuring core-company instance ..."
./configure_server.sh 'core-company' 
sleep 1
echo "Core-company instance installed ..."

echo "Installing and configuring core-encryption instance ..."
./configure_server.sh 'core-encryption' 
sleep 1
echo "Core-encryption instance installed ..."

echo "Installing and configuring core-file instance ..."
./configure_server.sh 'core-file' 
sleep 1
echo "Core-file instance installed ..."

echo "Installing and configuring core-messaging instance ..."
./configure_server.sh 'core-messaging' 
sleep 1
echo "Core-messaging instance installed ..."

echo "Installing and configuring core-transaction instance ..."
./configure_server.sh 'core-transaction' 
sleep 1
echo "Core-transaction instance installed ..."

##########Installing and configuring apis##########
echo "Installing and configuring api-user default instance ..."
./configure_server.sh 'api-user'
sleep 1
echo "api-user instance installed ..."

echo "Installing and configuring api-search instance ..."
./configure_server.sh 'api-search' 
sleep 1
echo "api-search instance installed ..."

echo "Installing and configuring api-banking instance ..."
./configure_server.sh 'api-banking' 
sleep 1
echo "api-banking instance installed ..."

echo "Installing and configuring api-company instance ..."
./configure_server.sh 'api-company' 
sleep 1
echo "api-company instance installed ..."

echo "Installing and configuring api-support instance ..."
./configure_server.sh 'api-support' 
sleep 1
echo "api-support instance installed ..."

echo "Installing and configuring api-auth instance ..."
./configure_server.sh 'api-auth' 
sleep 1
echo "api-auth instance installed ..."

echo "Installing and configuring api-transaction instance ..."
./configure_server.sh 'api-transaction' 
sleep 1
echo "api-transaction instance installed ..."

##########Wait for opened connections to close##########
CONNECTIONS=$(netstat -an | grep tcp  | grep $PORT_SEARCH_STRING)
echo "Please wait untill all connections are beeing closed ..."
i=1
while [ ! -z "$CONNECTIONS" -a "$i" -le "$(($CONNECTIONS_ALIVE_TIME_OUT*$SLEEP_TIME))" ];
do
CONNECTIONS=$( netstat -an | grep tcp  | grep $PORT_SEARCH_STRING)
echo "Still open connections..."
sleep $SLEEP_TIME
((i++))
done
if [ ! -z "$CONNECTIONS" ]; then
echo "Connections have not closed in time... Please close them and the start the new services !"
exit 1
fi

##########Start services##########
./start.sh
