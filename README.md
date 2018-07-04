adpi-utils-backend-iio
======================

IIO を利用して ADPi に搭載された ADC の操作を行うツール類を提供します。

## 提供ファイル
動作に必要な次のファイルがパッケージに含まれています。

* /lib/udev/rules.d/99-adpi-iio.rule  
  ADPi の認識時に初期設定を行うファイルです。  

* /lib/udev/rules.d/99-adpi-gpio.rule  
  ADPi の認識時に GPIO の設定を行うファイルです。  

* /usr/lib/adpi-utils/export_gpio.sh  
  GPIO の初期化を行うスクリプトファイルです。  

* /usr/lib/adpi-utils-backend-iio/adpi-utils-backend-iio.sh  
  IIO を利用して ADPi の操作を行うスクリプトファイルです。

* /usr/lib/adpi-utils-backend-iio/device.conf  
  ADPi のデバイス設定が記述されたファイルです。

* /usr/lib/adpi-utils-backend-iio/get_device_params.sh  
  ADPi のデバイス設定ファイルからパラメータを取得して表示するスクリプトファイルです。

## 作成ファイル
インストール時に次のファイルが作成されます。

* /usr/lib/adpi-utils/adpi-utils-backend  
  /usr/lib/adpi-utils-backend-iio/adpi-utils-backend-iio.sh へのシンボリックリンクです。  
