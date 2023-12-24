#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"
PWD_PATH=$(pwd) # Save the current working directory in a variable

#colors
RC="\e[31m"
GC="\e[32m"
YC="\e[33m"
NC="\e[0m"

echo "script started executing at $TIMESTAMP" &>> "$LOGFILE"

VALIDATE() {
  if [ $1 -ne 0 ]
  then
    echo -e "$RC ERROR: $2 FAILED $NC"
    exit 1
  else
    echo -e "$GC $2 SUCCESS $NC"
  fi
}
# Check root user or not
if [ $ID -ne 0 ]
then
  echo -e "$RC ERROR: Please run script with root access $NC"
  exit 1
else
  echo -e "$GC You are a root user $NC"
fi

cp "$PWD_PATH"/mongo.repo /etc/yum.repos.d/mongo.repo &>> "$LOGFILE"
VALIDATE $? "Copied MongoDB Repo"

echo -e "$YC Installing MONGODB ..... $NC"
dnf install mongodb-org -y  &>> "$LOGFILE"
VALIDATE $? "INSTALLATION OF MONGODB"

systemctl enable mongod  &>> "$LOGFILE"
VALIDATE $? "ENABLED MONGODB"

systemctl start mongod &>> "$LOGFILE"
VALIDATE $? "STARTED MONGODB"

sed -i 's/127.0.0.1/0.0.0.0/g' "/etc/mongod.conf" &>> "$LOGFILE"

systemctl restart mongod &>> "$LOGFILE"
VALIDATE $? "RESTARTED MONGODB"


