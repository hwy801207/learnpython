#!/bin/bash


if [ -z "$1" ]; then
echo "Please enter environment ex. 
		./removelbs.sh stage 
		./removelbs.sh prod
		"
exit 1
fi

ENVIRONMENT=$1

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT

. parameters

function removeHTTPSLoadBalancers(){
./removelb.sh $LB_HTTPS_API_USER $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_AUTH $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_BANKING $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_COMPANY $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_SUPPORT $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_SEARCH $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_TRANSACTION $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_BACKEND $ENVIRONMENT
./removelb.sh $LB_HTTPS_API_BASP $ENVIRONMENT
./removelb.sh $LB_HTTPS_WEB_UI $ENVIRONMENT
}

function removeHTTPLoadBalancers(){
./removelb.sh $LB_HTTP_API_USER $ENVIRONMENT
./removelb.sh $LB_HTTP_API_AUTH $ENVIRONMENT
./removelb.sh $LB_HTTP_API_BANKING $ENVIRONMENT
./removelb.sh $LB_HTTP_API_COMPANY $ENVIRONMENT
./removelb.sh $LB_HTTP_API_SUPPORT $ENVIRONMENT
./removelb.sh $LB_HTTP_API_SEARCH $ENVIRONMENT
./removelb.sh $LB_HTTP_API_TRANSACTION $ENVIRONMENT
./removelb.sh $LB_HTTP_API_BACKEND $ENVIRONMENT
./removelb.sh $LB_HTTP_API_BASP $ENVIRONMENT
./removelb.sh $LB_HTTP_WEB_UI $ENVIRONMENT
}

function removeALLLoadBalancers(){
#removeHTTPSLoadBalancers
removeHTTPLoadBalancers

./removelb.sh $LB_HTTP_AndroidPromo $ENVIRONMENT
./removelb.sh $LB_HTTP_PROPAGANDA $ENVIRONMENT
}

######################run main######################
#removeHTTPSLoadBalancers
removeHTTPLoadBalancers
#removeALLLoadBalancers