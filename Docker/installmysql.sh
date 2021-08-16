#!/bin/bash

curl -OL https://dev.mysql.com/get/mysql-apt-config_0.8.15-1_all.deb 
#debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-server select mysql-8.0'
DEBIAN_FRONTEND=noninteractive dpkg -i mysql-apt-config_0.8.15-1_all.deb
apt-get update 
DEBIAN_FRONTEND=noninteractive apt-get install -y  mysql-server mysql-client # mysql-connector-python-py3
apt-get clean
mysqld_safe &
sleep 5
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY ''"
