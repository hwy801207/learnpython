#!/bin/bash

SERVICE=`hostname | awk -F'-' '{print $1"-"$2}'`
echo "Starting $SERVICE ..."
service $SERVICE start 

echo "$SERVICE started !"
