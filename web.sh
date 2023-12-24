#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP"
SERVICE_FILE="/etc/systemd/system/user.service"
PWD_PATH=$(pwd) # Save the current working directory in a variable

#Colors
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
NC="\e[0m"

echo "Script started executing at $TIMESTAMP" &>>$LOGFILE

#Check for root user
if [ $ID -ne 0 ]
then
  echo -e "$RED ERROR: Please run script with root access$NC"
  exit 1
else
  echo -e "$GREEN You are root user$NC"
fi

VALIDATE() {
    if [ "$1" -ne 0 ]
    then
      echo -e "$RED ERROR: $2 is FAILED$NC"
      exit 1
    else
      echo -e "$GREEN $2 is SUCCESS$NC"
    fi
}

echo -e "$YELLOW Installing nginx.....$NC"
dnf install nginx -y &>>$LOGFILE
VALIDATE $? "Installing nginx"

echo -e "$YELLOW Enabling nginx.....$NC"
systemctl enable nginx &>>$LOGFILE
VALIDATE $? "Enable nginx"

echo -e "$YELLOW Starting nginx.....$NC"
systemctl start nginx &>>$LOGFILE
VALIDATE $? "Start nginx"

rm -rf /usr/share/nginx/html/* &>>$LOGFILE
VALIDATE $? "Removing default nginx html"

curl -o /tmp/web.zip https://roboshop-builds.s3.amazonaws.com/web.zip &>>$LOGFILE
VALIDATE $? "Downloading web src"

cd /usr/share/nginx/html &>>$LOGFILE
VALIDATE $? "Change directory"

unzip -o /tmp/web.zip &>>$LOGFILE
VALIDATE $? "Unzip web src"

cp "$PWD_PATH"/roboshop.conf /etc/nginx/default.d/roboshop.conf &>>$LOGFILE
VALIDATE $? "Copying roboshop.conf file"

systemctl restart nginx &>>$LOGFILE
VALIDATE $? "Restarting nginx"