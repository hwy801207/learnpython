#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
	echo "Please enter build no, webui build no and environment ex. 
	./disablelbmembers.sh 371 84 stage 
	./disablelbmembers.sh 371 84 prod
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

function disableMember(){
MEMBER_TO_DISABLE=$1
if [ ! -z "$MEMBER_TO_DISABLE" ]; then
	logMessageToConsole "INFO" "Disableing lb member $MEMBER_TO_DISABLE ..."
	listLBMemberDetails $MEMBER_TO_DISABLE
	neutron lb-member-update $MEMBER_TO_DISABLE --admin_state_up False
fi
}


function disableHTTPSMembersToLoadBalancers(){
disableMember $AUTH_HTTPS_MEMBER_1
disableMember $USER_HTTPS_MEMBER_1
disableMember $BANKING_HTTPS_MEMBER_1
disableMember $COMPANY_HTTPS_MEMBER_1
disableMember $SUPPORT_HTTPS_MEMBER_1
disableMember $SEARCH_HTTPS_MEMBER_1
disableMember $TRANSACTION_HTTPS_MEMBER_1
disableMember $BACKEND_HTTPS_MEMBER_1
disableMember $BASP_HTTPS_MEMBER_1
disableMember $WEBUI_HTTPS_MEMBER_1

disableMember $AUTH_HTTPS_MEMBER_2
disableMember $USER_HTTPS_MEMBER_2
disableMember $BANKING_HTTPS_MEMBER_2
disableMember $COMPANY_HTTPS_MEMBER_2
disableMember $SUPPORT_HTTPS_MEMBER_2
disableMember $SEARCH_HTTPS_MEMBER_2
disableMember $TRANSACTION_HTTPS_MEMBER_2
disableMember $BACKEND_HTTPS_MEMBER_2
disableMember $BASP_HTTPS_MEMBER_2
disableMember $WEBUI_HTTPS_MEMBER_2
}

function disableHTTPMembersToLoadBalancers(){
disableMember $AUTH_HTTP_MEMBER_1
disableMember $USER_HTTP_MEMBER_1
disableMember $BANKING_HTTP_MEMBER_1
disableMember $COMPANY_HTTP_MEMBER_1
disableMember $SUPPORT_HTTP_MEMBER_1
disableMember $SEARCH_HTTP_MEMBER_1
disableMember $TRANSACTION_HTTP_MEMBER_1
disableMember $BACKEND_HTTP_MEMBER_1
disableMember $BASP_HTTP_MEMBER_1
disableMember $WEBUI_HTTP_MEMBER_1

disableMember $AUTH_HTTP_MEMBER_2
disableMember $USER_HTTP_MEMBER_2
disableMember $BANKING_HTTP_MEMBER_2
disableMember $COMPANY_HTTP_MEMBER_2
disableMember $SUPPORT_HTTP_MEMBER_2
disableMember $SEARCH_HTTP_MEMBER_2
disableMember $TRANSACTION_HTTP_MEMBER_2
disableMember $BACKEND_HTTP_MEMBER_2
disableMember $BASP_HTTP_MEMBER_2
disableMember $WEBUI_HTTP_MEMBER_2
}

function disableALLMembersToLoadBalancers(){
#disableHTTPSMembersToLoadBalancers
disableHTTPMembersToLoadBalancers

disableMember $ANDROID_PROMO_HTTP_MEMBER
disableMember $PROPAGANDA_HTTP_MEMBER
}

######################run main######################
#disableHTTPSMembersToLoadBalancers
disableHTTPMembersToLoadBalancers
#disableALLMembersToLoadBalancers
clean