#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP"
PWD_PATH=$(pwd) # Save the current working directory in a variable

#Colors
RC="\e[31m"
GC="\e[32m"
YC="\e[33m"
NC="\e[0m"

echo "Script started executing at $TIMESTAMP" &>>$LOGFILE

#Check for root user
if [ $ID -ne 0 ]
then
  echo -e "$RC ERROR: Please run script with root access$NC"
  exit 1
else
  echo -e "$GC You are root user$NC"
fi

VALIDATE() {
    if [ "$1" -ne 0 ]
    then
      echo -e "$RC ERROR: $2 is FAILED$NC"
      exit 1
    else
      echo -e "$GC $2 is SUCCESS$NC"
    fi
}

dnf module disable mysql -y &>>$LOGFILE
VALIDATE $? "Disable Mysql"

cp "$PWD_PATH"/mysql.repo /etc/yum.repos.d/mysql.repo &>>$LOGFILE
VALIDATE $? "Copying Mysql repo"

echo -e "$YC Installing mysql.....$NC"
dnf install mysql-community-server -y &>>$LOGFILE
VALIDATE $? "Installing Mysql"

systemctl enable mysqld &>>$LOGFILE
VALIDATE $? "Enable mysql"

systemctl start mysqld &>>$LOGFILE
VALIDATE $? "Start mysql"

mysql_secure_installation --set-root-pass RoboShop@1 &>>$LOGFILE
VALIDATE $? "set mysql root password"

mysql -uroot -pRoboShop@1 &>>$LOGFILE
VALIDATE $? "login to mysql"