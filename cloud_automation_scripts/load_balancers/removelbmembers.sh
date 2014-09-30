#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter build no, webui build no and environment ex. 
		./removelbmembers.sh 371 84 stage
		./removelbmembers.sh 371 84 prod
		"
exit 1
fi
BUILD_NO=$1
WEBUI_BUILD_NO=$2
ENVIRONMENT=$3

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT
. parameters

checkNovaAndNeutron
. maplbmembers.sh $BUILD_NO $WEBUI_BUILD_NO $ENVIRONMENT

function removeMember(){
MEMBER_TO_REMOVE=$1
if [ ! -z "$MEMBER_TO_REMOVE" ]; then
	logMessageToConsole "INFO" "Removing lb member $MEMBER_TO_REMOVE ..."
	listLBMemberDetails $MEMBER_TO_REMOVE
	neutron lb-member-delete $MEMBER_TO_REMOVE
fi
}

function removeHTTPSMembersToLoadBalancers(){
removeMember $AUTH_HTTPS_MEMBER_1
removeMember $USER_HTTPS_MEMBER_1
removeMember $BANKING_HTTPS_MEMBER_1
removeMember $COMPANY_HTTPS_MEMBER_1
removeMember $SUPPORT_HTTPS_MEMBER_1
removeMember $SEARCH_HTTPS_MEMBER_1
removeMember $TRANSACTION_HTTPS_MEMBER_1
removeMember $BACKEND_HTTPS_MEMBER_1
removeMember $BASP_HTTPS_MEMBER_1
removeMember $WEBUI_HTTPS_MEMBER_1

removeMember $AUTH_HTTPS_MEMBER_2
removeMember $USER_HTTPS_MEMBER_2
removeMember $BANKING_HTTPS_MEMBER_2
removeMember $COMPANY_HTTPS_MEMBER_2
removeMember $SUPPORT_HTTPS_MEMBER_2
removeMember $SEARCH_HTTPS_MEMBER_2
removeMember $TRANSACTION_HTTPS_MEMBER_2
removeMember $BACKEND_HTTPS_MEMBER_2
removeMember $BASP_HTTPS_MEMBER_2
removeMember $WEBUI_HTTPS_MEMBER_2
}

function removeHTTPMembersToLoadBalancers(){
removeMember $AUTH_HTTP_MEMBER_1
removeMember $USER_HTTP_MEMBER_1
removeMember $BANKING_HTTP_MEMBER_1
removeMember $COMPANY_HTTP_MEMBER_1
removeMember $SUPPORT_HTTP_MEMBER_1
removeMember $SEARCH_HTTP_MEMBER_1
removeMember $TRANSACTION_HTTP_MEMBER_1
removeMember $BACKEND_HTTP_MEMBER_1
removeMember $BASP_HTTP_MEMBER_1
removeMember $WEBUI_HTTP_MEMBER_1

removeMember $AUTH_HTTP_MEMBER_2
removeMember $USER_HTTP_MEMBER_2
removeMember $BANKING_HTTP_MEMBER_2
removeMember $COMPANY_HTTP_MEMBER_2
removeMember $SUPPORT_HTTP_MEMBER_2
removeMember $SEARCH_HTTP_MEMBER_2
removeMember $TRANSACTION_HTTP_MEMBER_2
removeMember $BACKEND_HTTP_MEMBER_2
removeMember $BASP_HTTP_MEMBER_2
removeMember $WEBUI_HTTP_MEMBER_2
}

function removeALLMembersToLoadBalancers(){
#removeHTTPSMembersToLoadBalancers
removeHTTPMembersToLoadBalancers
removeMember $ANDROID_PROMO_HTTP_MEMBER
removeMember $PROPAGANDA_HTTP_MEMBER
}

######################run main######################
#removeHTTPSMembersToLoadBalancers
removeHTTPMembersToLoadBalancers
#removeALLMembersToLoadBalancers

clean



