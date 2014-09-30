#! /bin/bash

if [ -z "$1" ]; then
echo "Please enter instance"
exit 1
fi

nova list > novalist_.tmp
CORE_FILE=`grep core-file-$1 novalist_.tmp | awk -F"|" '{print $2}'`
CORE_USER=`grep core-user-$1 novalist_.tmp | awk -F"|" '{print $2}'`
CORE_MESSAGING=`grep core-messaging-$1 novalist_.tmp | awk -F"|" '{print $2}'`
CORE_BANKING=`grep core-banking-$1 novalist_.tmp | awk -F"|" '{print $2}'`
CORE_COMPANY=`grep core-company-$1 novalist_.tmp | awk -F"|" '{print $2}'`
CORE_ENGINE=`grep core-engine-$1 novalist_.tmp | awk -F"|" '{print $2}'` 
CORE_ENCRYPTION=`grep core-encryption-$1 novalist_.tmp | awk -F"|" '{print $2}'`
CORE_TRANSACTION=`grep core-transaction-$1 novalist_.tmp | awk -F"|" '{print $2}'`

API_USER=`grep api-user-$1 novalist_.tmp | awk -F"|" '{print $2}'`
API_AUTH=`grep api-auth-$1 novalist_.tmp | awk -F"|" '{print $2}'`
API_BANKING=`grep api-banking-$1 novalist_.tmp | awk -F"|" '{print $2}'`
API_COMPANY=`grep api-company-$1 novalist_.tmp | awk -F"|" '{print $2}'`
API_SEARCH=`grep api-search-$1 novalist_.tmp | awk -F"|" '{print $2}'`
API_SUPPORT=`grep api-support-$1 novalist_.tmp | awk -F"|" '{print $2}'`
API_TRANSACTION=`grep api-transaction-$1 novalist_.tmp | awk -F"|" '{print $2}'`

echo "Deleting all core instances "$1
if [ ! -z "$CORE_FILE" ]; then
nova delete  $CORE_FILE
fi
if [ ! -z "$CORE_USER" ]; then
nova delete  $CORE_USER
fi
if [ ! -z "$CORE_MESSAGING" ]; then
nova delete  $CORE_MESSAGING
fi
if [ ! -z "$CORE_BANKING" ]; then
nova delete  $CORE_BANKING
fi
if [ ! -z "$CORE_COMPANY" ]; then
nova delete  $CORE_COMPANY
fi
if [ ! -z "$CORE_ENGINE" ]; then
nova delete  $CORE_ENGINE
fi
if [ ! -z "$CORE_ENCRYPTION" ]; then
nova delete  $CORE_ENCRYPTION
fi
if [ ! -z "$CORE_TRANSACTION" ]; then
nova delete  $CORE_TRANSACTION
fi

echo "Deleting all api instances "$1
if [ ! -z "$API_USER" ]; then
nova delete  $API_USER
fi
if [ ! -z "$API_AUTH" ]; then
nova delete  $API_AUTH
fi
if [ ! -z "$API_BANKING" ]; then
nova delete  $API_BANKING
fi
if [ ! -z "$API_COMPANY" ]; then
nova delete  $API_COMPANY
fi
if [ ! -z "$API_SEARCH" ]; then
nova delete  $API_SEARCH
fi
if [ ! -z "$API_SUPPORT" ]; then
nova delete  $API_SUPPORT
fi
if [ ! -z "$API_TRANSACTION" ]; then
nova delete  $API_TRANSACTION
fi
echo 'Please wait ...'
sleep 10

nova list 
