#!/bin/bash

ID=$(id -u)
TIMESTAMP=(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP"
SERVICE_FILE="/etc/systemd/system/user.service"
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
    echo -e "$GC $2 is ...SUCCESS$NC"
  fi
}

echo -e "$YC Disabling nodejs.....$NC"
dnf module disable nodejs -y &>>"$LOGFILE"
VALIDATE $? "Module disable"

echo -e "$YC Enabling nodejs.....$NC"
dnf module enable nodejs:18 -y &>>"$LOGFILE"
VALIDATE $? "Module enable"

dnf list installed nodejs &>>"$LOGFILE"
if [ $? -ne 0 ]
then
  dnf install nodejs -y &>>"$LOGFILE"
  VALIDATE $? "Install nodejs"
else
  echo -e "$YC nodejs already installed....SKIPPING$NC"
fi   

id roboshop &>>"$LOGFILE"
if [ $? -ne 0 ]
then
  useradd roboshop &>>"$LOGFILE"
  VALIDATE $? "roboshop user creation"
else
  echo -e "$YC roboshop user already exists...SKIPPING$NC"
fi

mkdir -p /app &>>"$LOGFILE"
VALIDATE $? "Creating app directory"

curl -L -o /tmp/user.zip https://roboshop-builds.s3.amazonaws.com/user.zip &>>"$LOGFILE"
VALIDATE $? "Downloading user.zip"

cd /app  &>>"$LOGFILE"
VALIDATE $? "Change directory"

unzip -o /tmp/user.zip &>>"$LOGFILE"
VALIDATE $? "unzip"

npm install  &>>"$LOGFILE"
VALIDATE $? "Installing dependencies"

cp "$PWD_PATH"/user.service /etc/systemd/system/user.service &>>"$LOGFILE"
VALIDATE $? "copying user.service file"

# Enter mongodb IP/domain name as input
read -p "Enter mongodb host: " MONGODB_HOST
read -p "Enter redis host: " REDIS_HOST
if [ -f "$SERVICE_FILE" ]; then
  # Replace IP
  sed -i "s/<MONGODB-SERVER-IP-ADDRESS>/${MONGODB_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  sed -i "s/<REDIS-SERVER-IP-ADDRESS>/${REDIS_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  echo "Replacement successful."
else
  echo "Error: File not found - $SERVICE_FILE"
  exit 1
fi

systemctl daemon-reload &>>"$LOGFILE"
VALIDATE $? "Daemon reload"

systemctl enable user  &>>"$LOGFILE"
VALIDATE $? "Enable user"

systemctl start user &>>"$LOGFILE"
VALIDATE $? "Start user"
cp "$PWD_PATH"/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying mongodb client repo"

dnf install mongodb-org-shell -y &>>"$LOGFILE"
VALIDATE $? "Installing mongodb client"

mongo --host $MONGODB_HOST </app/schema/user.js &>>"$LOGFILE"
VALIDATE $? "Schema into mongodb"

