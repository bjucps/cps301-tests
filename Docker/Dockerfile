FROM ubuntu:18.04 

RUN apt-get update && apt-get install -y curl wget unzip python3 sqlite3 lsb-release gnupg
RUN apt install -y python3-pip
RUN pip3 install  pytest mysql-connector

COPY installmysql.sh .

# Enable MYSQL repo
RUN bash installmysql.sh

COPY cps301.cnf /etc/mysql/mysql.conf.d/zz_cps301.conf
COPY updatedb.sh .

RUN bash updatedb.sh
