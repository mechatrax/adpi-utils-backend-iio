adpi-utils-backend-iio
======================

IIO を利用して ADPi に搭載された ADC の操作を行うツール類を提供します。

## 提供ファイル
次のファイルがパッケージに含まれています。

### /lib/udev/rules.d/85-adpi-utils-backend-iio.rules  
ADPi のデバイスを定義した設定ファイルです。

### /lib/systemd/system/adpi-utils-backend-iio-init<span>@</span>.service  
ADPi の初期化を行うサービスの設定ファイルです。

### /usr/lib/adpi-utils/export_gpio.sh  
GPIO の初期化を行うスクリプトファイルです。

### /usr/lib/adpi-utils-backend-iio/adpi-utils-backend-iio.sh  
IIO を利用して ADPi の操作を行うスクリプトファイルです。

### /usr/lib/adpi-utils-backend-iio/device.conf  
ADPi のデバイス設定が記述されたファイルです。

### /usr/lib/adpi-utils-backend-iio/get_device_params.sh  
ADPi のデバイス設定ファイルからパラメータを取得して表示するスクリプトファイルです。

### /usr/share/doc/adpi-utils-backend-iio/changelog.gz
パッケージの変更履歴を記録したファイルです。

### /usr/share/doc/adpi-utils-backend-iio/copyright
著作権とライセンスを記載したファイルです。

## 作成ファイル
インストール時に次のファイルが作成されます。

### /usr/lib/adpi-utils/adpi-utils-backend  
/usr/lib/adpi-utils-backend-iio/adpi-utils-backend-iio.sh へのシンボリックリンクです。
