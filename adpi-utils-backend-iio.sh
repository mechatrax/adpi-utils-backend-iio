#!/bin/bash

set -e

#
# Usage: adpi-utils-backend-iio.sh \
#          device=<DEV_NAME> adc=<ADC_SPI> eeprom=<EEPROM_I2C> \
#          { get | set } <PARAM> [VALUE [,...]]
#
ARGS=($@)
OPTS=()

for arg in ${ARGS[@]}
do
  case "$arg" in
  device=*)
    DEV_NAME=$(echo $arg | cut -d= -f2)
    ;;
  adc=*)
    SPI_ADDR=$(echo $arg | cut -d= -f2)
    ;;
  eeprom=*)
    EEPROM_ADDR=$(echo $arg | cut -d= -f2)
    ;;
  *=*)
    ;;
  *)
    OPTS=(${OPTS[@]} $arg)
    ;;
  esac
done

LIB_PATH=/usr/lib/adpi-utils-backend-iio/
IIO_PATH=$(find /sys/bus/spi/devices/${SPI_ADDR}/iio:device* -maxdepth 0)
EEPROM_PATH=/sys/bus/i2c/devices/${EEPROM_ADDR}/eeprom

FREQ_NODE=${IIO_PATH}/sampling_frequency
SCALE_NODE=${IIO_PATH}/in_voltage-voltage_scale

INDEX_OFFSET=-1

#
# Usage: list_freq
#
list_freq ()
{
  cat ${FREQ_NODE}_avaliable
}

#
# Usage: list_scale
#
list_scale ()
{
  cat ${SCALE_NODE}_available
}

#
# Usage: set_calib SCALE_INDEX
#
set_calib ()
{
  if [ ! -e "$EEPROM_PATH" ]
  then
    return 0
  fi
  
  local datasize
  local biases
  local scales
  
  datasize=$((4*$CHANNELS))
  biases=($(od -v -An -td4 -j$((2*${datasize}*${1})) -N$datasize \
    ${EEPROM_PATH}))
  scales=($(od -v -An -td4 -j$((2*${datasize}*${1}+${datasize})) -N$datasize \
    ${EEPROM_PATH}))
  
  local i 
  for ((i=0; i<$CHANNELS; i++))
  do
    local bias
    local biasnode
    local scale
    local scalenode
    
    bias=${biases[$i]}
    biasnode=${IIO_PATH}/in_voltage${i}-voltage${i}_calibbias
    scale=${scales[$i]}
    scalenode=${IIO_PATH}/in_voltage${i}-voltage${i}_calibscale
    
    if [ -w ${biasnode} ]
    then
      echo $bias > ${biasnode}
    fi
    
    if [ -w ${scalenode} ]
    then
      echo $scale > ${scalenode}
    fi
  done
}

#
# Usage: set_gpio <N> { "on" | "off" }
#
set_gpio ()
{
  if [ "$1" = "" ] || [ "$2" = "" ]
  then
    return 2
  fi
  
  local line
  
  line="${DEV_NAME}$(echo $SPI_ADDR | cut -d\. -f2)_ch$(($1 + $INDEX_OFFSET))"
  
  case $2 in
  0|off)
    gpioget --bias=pull-down $(gpiofind "$line") > /dev/null
    ;;
  1|on)
    gpioset --bias=disable $(gpiofind "$line")=1
    ;;
  *)
    echo "Invalid value $2" >&2
    return 1
    ;;
  esac
}

#
# Usage: set_freq FREQUENCY
#
set_freq ()
{
  if [ "$1" = "" ]
  then
    return 2
  fi
  
  echo $1 > $FREQ_NODE
}

#
# Usage: set_scale SCALE
#
set_scale ()
{
  if [ "$1" = "" ]
  then
    return 2
  fi
  
  local scales
  scales=($(list_scale))
  
  local i 
  for ((i=0; i<${#scales[@]}; i++))
  do
    local scale
    scale=${scales[$i]}
    if [ "$1" = "$scale" ]
    then
      set_calib $i
      echo $scale > $SCALE_NODE
      return $?
    fi
  done
  
  echo "Invalid value $1" >&2
  
  return 1
}

#
# Usage: set_gain GAIN
#
set_gain ()
{
  if [ "$1" = "" ]
  then
    return 2
  fi
  
  local gains
  local scales
  gains=(1 2 4 8 16 32 64 128 256)
  scales=($(list_scale))
 
  local i 
  for ((i=0; i<${#scales[@]}; i++))
  do
    local scale
    local gain
    scale=${scales[$i]}
    gain=${gains[$i]}
    if [ "$1" = "$gain" ]
    then
      set_calib $i
      echo $scale > $SCALE_NODE
      return $?
    fi
  done
  
  echo "Invalid value $1" >&2
  
  return 1
}

#
# Usage: get_gpio <N>
#
get_gpio ()
{
  if [ "$1" = "" ]
  then
    return 2
  fi
  
  local line
  
  line="${DEV_NAME}$(echo $SPI_ADDR | cut -d\. -f2)_ch$(($1 + $INDEX_OFFSET))"
 
  if [ "$line" = "" ]
  then
    echo "Invalid value $1" >&2
    return 1
  fi

  local value
  
  value=$(gpioinfo $(gpiofind $line | cut -d\  -f1) | grep $line)
  
  case $value in
  *input*)
    echo "off"
    ;;
  *output*)
    echo "on"
    ;;
  *)
    echo "Unknown value $value" >&2
    return 1
    ;;
  esac
}

#
# Usage: get_freq
#
get_freq ()
{
  cat $FREQ_NODE
}

#
# Usage: get_scale
#
get_scale ()
{
  cat $SCALE_NODE
}

#
# Usage: get_gain
#
get_gain ()
{
  local gain
  local gains
  local scale
  local scales
  
  gain=""
  gains=(1 2 4 8 16 32 64 128 256)
  scale=$(get_scale)
  scales=($(list_scale))
  
  local i 
  for ((i=0; i<${#scales[@]}; i++))
  do
    if [ "$scale" = "${scales[$i]}" ]
    then
      gain=${gains[$i]}
    fi
  done
  
  echo $gain
}

#
# Usage get_temp
#
get_temp ()
{
  local ofs
  local scl
  local raw
  
  ofs=$(cat ${IIO_PATH}/in_temp0_offset)
  scl=$(cat ${IIO_PATH}/in_temp_scale)
  raw=$(cat ${IIO_PATH}/in_temp0_raw)
  
  printf "%.9f\n" $(echo "($raw + $ofs) * $scl / 1000.0 / 0.81" | bc -l)
}

#
# Usage: get_voltage <N>
#
get_voltage ()
{
  if [ "$1" = "" ]
  then
    return 2
  fi
  
  local idx
  local ofs
  local scl
  local raw
  
  idx=$(($1 + $INDEX_OFFSET))
  ofs=$(cat ${IIO_PATH}/in_voltage${idx}-voltage${idx}_offset)
  scl=$(cat ${IIO_PATH}/in_voltage-voltage_scale)
  raw=$(cat ${IIO_PATH}/in_voltage${idx}-voltage${idx}_raw)
  
  printf "%.9f\n" $(echo "($raw + $ofs) * $scl" | bc -l)
}

#
# Usage: adpi_get { frequency | gain | output <N> | scale | voltage <N> }
#
adpi_get ()
{
  case $1 in
    frequency)
      get_freq
      ;;
    gain)
      get_gain
      ;;
    output)
      get_gpio $2
      ;;
    scale)
      get_scale
      ;;
    temperature)
      get_temp
      ;;
    voltage)
      get_voltage $2
      ;;
    *)
      return 2
      ;;
  esac
  
  return $?
}

#
# Usage: adpi_set { frequency | gain | output <N> | scale } <VALUE>
#
adpi_set ()
{
  case $1 in
    frequency)
      set_freq $2
      ;;
    gain)
      set_gain $2
      ;;
    output)
      set_gpio $2 $3
      ;;
    scale)
      set_scale $2
      ;;
    *)
      return 2
      ;;
  esac
  
  return $?
}


#
# parse device config
#
for param in $(${LIB_PATH}/get_device_params.sh $DEV_NAME)
do
  case $param in
  channels*)
    CHANNELS=$(echo $param | cut -d= -f2)
    ;;
  esac
done

#
# execute command
#
status=2

case ${OPTS[0]} in
  get)
    adpi_get ${OPTS[@]:1}
    status=$?
    ;;
  set)
    adpi_set ${OPTS[@]:1}
    status=$?
    ;;
  *)
    ;;
esac

exit $status

