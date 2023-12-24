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

echo "Script started executing at $TIMESTAMP" &>>"$LOGFILE"

if [ "$ID" -ne 0 ]
then 
  echo -e "$RC ERROR: Please run script using root access $NC"
  exit 1
else
  echo -e "$GC You are root user$NC"
fi

#Function to validation various commands
VALIDATE() {
  if [ "$1" -ne 0 ] 
  then
    echo -e "$RC $2 is ...FAILED$NC"
    exit 1
  else
    echo -e "$GC$2 is ...SUCCESS$NC"
  fi
}

echo -e "$YC Installing rpm package.....$NC"
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm -y &>>"$LOGFILE"
VALIDATE $? "Installing rpm package"

echo -e "$YC Installing redis.....$NC"
dnf module enable redis:remi-6.2 -y &>>"$LOGFILE"
VALIDATE $? "Enable redis package"

dnf list installed redis &>>"$LOGFILE"
if [ $? -ne 0 ]
then
  dnf install redis -y &>>"$LOGFILE"
  VALIDATE $? "Installing redis"
else
  echo -e "$YC redis already installed...SKIPPING$NC"
fi

sed -i 's/127.0.0.1/0.0.0.0/g' "/etc/redis/redis.conf" &>>"$LOGFILE"
VALIDATE $? "IP configuration"

systemctl enable redis &>>"$LOGFILE"
VALIDATE $? "Enable redis"

systemctl start redis &>>"$LOGFILE"
VALIDATE $? "Start redis"