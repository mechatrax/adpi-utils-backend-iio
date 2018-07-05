#!/bin/bash

set -e

CONF_FILE=/etc/adpi.conf
LIB_PATH=/usr/lib/adpi-utils-backend-iio/

parse_args ()
{
  I2C_DEV=$1
}

export_config ()
{
  local c

  for c in $1
  do
    eval config_$c
  done
}

export_device ()
{
  if [ "$1" == "" ]
  then
    device_channels=4
    return
  fi
  
  local params
  local p

  params="$(${LIB_PATH}/get_device_params.sh $1 ${LIB_PATH}/device.conf)"
  for p in $params
  do
    eval device_$p
  done
}

export_gpio ()
{
  local i
  local dev
  local chip
  local base
  
  dev="/sys/bus/i2c/devices/${I2C_DEV}"
  chip=$(find ${dev}/gpio/gpiochip*/ -maxdepth 0)
  base=$(cat ${chip}/base)
  
  for i in $(seq $base $(($base + $device_channels - 1)))
  do
    echo $i > ${chip}/subsystem/export
    echo "out" > ${chip}/subsystem/gpio${i}/direction
  done
}

parse_args $@

[ -r $CONF_FILE ]

SECTIONS=$(/usr/lib/adpi-utils/parse_sections.sh $CONF_FILE)

for s in $SECTIONS
do
  params=$(/usr/lib/adpi-utils/parse_parameters.sh $s $CONF_FILE)
  for p in $params
  do
    if [ "gpio=0x$(echo $I2C_DEV | sed -e 's/^1-00//')" = "$p" ]
    then
      export_config "$params"
      export_device "$config_device"
      export_gpio
      break
    fi
  done
done

