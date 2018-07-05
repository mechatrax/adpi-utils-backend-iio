#!/bin/bash

set -e

CONF_FILE=/usr/lib/adpi-utils-backend-iio/device.conf
PARSER=/usr/lib/adpi-utils/parse_parameters.sh

DEV_NAME=$1

[ -r $CONF_FILE ]
[ -x $PARSER ]

params=$($PARSER $DEV_NAME $CONF_FILE)
for p in $params
do
  echo $p
done

