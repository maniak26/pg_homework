#!/bin/bash

INSTANCE_NAME=pg15

yc compute instance delete --name ${INSTANCE_NAME} --async

sed "/^${INSTANCE_NAME}/d" hosts.ini > tmpfile && mv tmpfile hosts.ini
