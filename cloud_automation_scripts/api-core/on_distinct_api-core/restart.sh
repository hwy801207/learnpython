#!/bin/bash

SERVICE=`hostname | awk -F'-' '{print $1"-"$2}'`

echo "Restarting $SERVICE ..."

service $SERVICE stop 
sleep 1
service $SERVICE start

echo "$SERVICE restarted !"




