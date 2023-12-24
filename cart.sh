#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP"
SERVICE_FILE="/etc/systemd/system/cart.service"
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

echo -e "$YC Disabling nodejs.....$NC"
dnf module disable nodejs -y &>> $LOGFILE
VALIDATE $? "DISABLING CURRENT NODEJS"

echo -e "$YC Enabling nodejs.....$NC"
dnf module enable nodejs:18 -y &>> $LOGFILE
VALIDATE $? "ENABLING NODEJS:18"

echo -e "$YC Installing Nodejs .....$NC"
dnf install nodejs -y &>> $LOGFILE
VALIDATE $? "INSTALLING NODEJS"

#creating user
id roboshop &>> $LOGFILE
if [ $? -ne 0 ]
then
  useradd roboshop &>> $LOGFILE
  VALIDATE $? "USER CREATING"
else
  echo -e "$YC roboshop user already exist...skipping$NC"
fi

mkdir -p /app

curl -o /tmp/cart.zip https://roboshop-builds.s3.amazonaws.com/cart.zip
VALIDATE $? "DOWNLOADING CART APPLICATION"

cd /app 
unzip -o /tmp/cart.zip &>> $LOGFILE

npm install &>> $LOGFILE
VALIDATE $? "INSTALLING DEPENDENCIES"

#copying cart service file
cp "$PWD_PATH"/cart.service /etc/systemd/system/cart.service &>> $LOGFILE
VALIDATE $? "COPYING CART SERVICE FILE"

# Enter mongodb IP/domain name as input
read -p "Enter redis host: " REDIS_HOST
read -p "Enter catalogue host: " CATALOGUE_HOST
if [ -f "$SERVICE_FILE" ]; then
  # Replace IP
  sed -i "s/<CATALOGUE-SERVER-IP>/${CATALOGUE_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  sed -i "s/<REDIS-SERVER-IP>/${REDIS_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  echo "Replacement successful."
else
  echo "Error: File not found - $SERVICE_FILE"
  exit 1
fi

systemctl daemon-reload &>> $LOGFILE
VALIDATE $? "CART DAEMON RELOAD"

systemctl enable cart &>> $LOGFILE
VALIDATE $? "ENABLING CART"

systemctl start cart &>> $LOGFILE
VALIDATE $? "STARTING CART"

