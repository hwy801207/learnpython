#!/bin/bash


if [ -z "$1" -o -z "$2" ]; then
echo "Please enter lb to delete and environment ex. 
		./removelb.sh https_basp_lb stage 
		./removelb.sh https_basp_lb prod
		"
exit 1
fi
LB=$1
ENVIRONMENT=$2

. ../utils/config_func.sh
loadConfigParamsLocally $ENVIRONMENT



. parameters
checkNovaAndNeutron

neutron lb-vip-delete $LB'_vip'
neutron lb-pool-delete $LB