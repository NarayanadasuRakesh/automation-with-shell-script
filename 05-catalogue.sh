#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP.log"
SERVICE_FILE="/etc/systemd/system/catalogue.service"
PWD_PATH=$(pwd) # Save the current working directory in a variable

RC="\e[31m"
GC="\e[32m"
YC="\e[33m"
NC="\e[0m"

echo "script started executing at $TIMESTAMP"  

# root access check
if [ $ID -ne 0 ]
then
  echo -e "$RC ERROR: please run script with root access $NC"
  exit 1
else
  echo -e "$GC You are root user$NC"
fi

VALIDATE() {
    if [ $1 -ne 0 ]
    then 
      echo -e "$RC $2 IS FAILED$NC"
      exit 1
    else
      echo -e "$GC $2 IS SUCCESS$NC"
    fi
}

echo -e "$YC Disabling nodejs.....$NC"
dnf module disable nodejs -y &>> "$LOGFILE"
VALIDATE $? "DISABLING CURRENT NODEJS"

echo -e "$YC Enabling nodejs 18.....$NC"
dnf module enable nodejs:18 -y &>> "$LOGFILE"
VALIDATE $? "ENABLING NODEJS:18"

echo -e "$YC Installing Nodejs .....$NC"
dnf install nodejs -y &>> "$LOGFILE"
VALIDATE $? "INSTALLING NODEJS"

#creating user
id roboshop &>> "$LOGFILE"
if [ $? -ne 0 ]
then
  useradd roboshop &>> "$LOGFILE"
  VALIDATE $? "USER CREATING"
else
  echo -e "$YC roboshop user already exist skipping$NC"
fi

mkdir -p /app &>> "$LOGFILE"

curl -o /tmp/catalogue.zip https://roboshop-builds.s3.amazonaws.com/catalogue.zip
VALIDATE $? "DOWNLOADING CATALOGUE APPLICATION"

cd /app &>> "$LOGFILE"
unzip -o /tmp/catalogue.zip &>> "$LOGFILE"

npm install &>> "$LOGFILE"
VALIDATE $? "INSTALLING DEPENDENCIES"



# Copying catalogue service file
cp "$PWD_PATH"/catalogue.service /etc/systemd/system/catalogue.service &>> "$LOGFILE"
VALIDATE $? "COPYING CATALOGUE SERVICE FILE"

# Enter mongodb IP/domain name as input
read -p "Enter mongodb host: " MONGODB_HOST
if [ -f "$SERVICE_FILE" ]; then
  # Replace IP
  sed -i "s/<MONGODB-SERVER-IPADDRESS>/${MONGODB_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  echo "Replacement successful."
else
  echo "Error: File not found - $SERVICE_FILE"
  exit 1
fi

systemctl daemon-reload &>> "$LOGFILE"
VALIDATE $? "CATALOGUE DAEMON RELOAD"

systemctl enable catalogue &>> "$LOGFILE"
VALIDATE $? "ENABLING CATALOGUE"

systemctl start catalogue &>> "$LOGFILE"
VALIDATE $? "STARTING CATALOGUE"

cp "$PWD_PATH"/mongo.repo /etc/yum.repos.d/mongo.repo &>> "$LOGFILE"
VALIDATE $? "Copied MongoDB Repo"

echo -e "$YELLOW Installing mongo client$NC"
dnf install mongodb-org-shell -y &>> "$LOGFILE"
VALIDATE $? "INSTALLING MONGODB CLIENT"


mongo --host "${MONGODB_HOST}" </app/schema/catalogue.js &>> "$LOGFILE"
VALIDATE $? "Loading Catalogue data into MongoDB"

