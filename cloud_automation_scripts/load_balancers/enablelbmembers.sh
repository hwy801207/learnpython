#!/bin/bash

if [ -z "$1" -o -z "$2" -o -z "$3" ]; then
echo "Please enter build no, webui build no and environment ex. 
		./enablelbmembers.sh 371 84 stage 
		./enablelbmembers.sh 371 84 prod
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

function enableMember(){
MEMBER_TO_ENABLE=$1
if [ ! -z "$MEMBER_TO_ENABLE" ]; then
	logMessageToConsole "INFO" "Enableling lb member $MEMBER_TO_ENABLE ..."
	listLBMemberDetails $MEMBER_TO_ENABLE
	neutron lb-member-update $MEMBER_TO_ENABLE --admin_state_up True
fi
}

function enableHTTPSMembersToLoadBalancers(){
enableMember $AUTH_HTTPS_MEMBER_1
enableMember $USER_HTTPS_MEMBER_1
enableMember $BANKING_HTTPS_MEMBER_1
enableMember $COMPANY_HTTPS_MEMBER_1
enableMember $SUPPORT_HTTPS_MEMBER_1
enableMember $SEARCH_HTTPS_MEMBER_1
enableMember $TRANSACTION_HTTPS_MEMBER_1
enableMember $BACKEND_HTTPS_MEMBER_1
enableMember $BASP_HTTPS_MEMBER_1
enableMember $WEBUI_HTTPS_MEMBER_1

enableMember $AUTH_HTTPS_MEMBER_2
enableMember $USER_HTTPS_MEMBER_2
enableMember $BANKING_HTTPS_MEMBER_2
enableMember $COMPANY_HTTPS_MEMBER_2
enableMember $SUPPORT_HTTPS_MEMBER_2
enableMember $SEARCH_HTTPS_MEMBER_2
enableMember $TRANSACTION_HTTPS_MEMBER_2
enableMember $BACKEND_HTTPS_MEMBER_2
enableMember $BASP_HTTPS_MEMBER_2
enableMember $WEBUI_HTTPS_MEMBER_2
}

function enableHTTPMembersToLoadBalancers(){
enableMember $AUTH_HTTP_MEMBER_1
enableMember $USER_HTTP_MEMBER_1
enableMember $BANKING_HTTP_MEMBER_1
enableMember $COMPANY_HTTP_MEMBER_1
enableMember $SUPPORT_HTTP_MEMBER_1
enableMember $SEARCH_HTTP_MEMBER_1
enableMember $TRANSACTION_HTTP_MEMBER_1
enableMember $BACKEND_HTTP_MEMBER_1
enableMember $BASP_HTTP_MEMBER_1
enableMember $WEBUI_HTTP_MEMBER_1

enableMember $AUTH_HTTP_MEMBER_2
enableMember $USER_HTTP_MEMBER_2
enableMember $BANKING_HTTP_MEMBER_2
enableMember $COMPANY_HTTP_MEMBER_2
enableMember $SUPPORT_HTTP_MEMBER_2
enableMember $SEARCH_HTTP_MEMBER_2
enableMember $TRANSACTION_HTTP_MEMBER_2
enableMember $BACKEND_HTTP_MEMBER_2
enableMember $BASP_HTTP_MEMBER_2
enableMember $WEBUI_HTTP_MEMBER_2

}

function enableALLMembersToLoadBalancers(){
#enableHTTPSMembersToLoadBalancers
enableHTTPMembersToLoadBalancers

enableMember $ANDROID_PROMO_HTTP_MEMBER
enableMember $PROPAGANDA_HTTP_MEMBER
}

######################run main######################
#enableHTTPSMembersToLoadBalancers
enableHTTPMembersToLoadBalancers
#enableALLMembersToLoadBalancers

clean