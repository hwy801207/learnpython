#!/bin/bash

SERVICE=`hostname | awk -F'-' '{print $1"-"$2}'`
echo "Stopping $SERVICE ..."
service $SERVICE stop 

echo "$SERVICE stopped !"