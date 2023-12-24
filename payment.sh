#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP"
SERVICE_FILE="/etc/systemd/system/payment.service"
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
  exit
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

echo -e "$YC Installing python.....$NC"
dnf install python36 gcc python3-devel -y &>>$LOGFILE
VALIDATE $? "Installing python"

#creating user
id roboshop  &>>$LOGFILE
if [ $? -ne 0 ]
then
  useradd roboshop 
  VALIDATE $? "USER CREATING"
else
  echo -e "$YC roboshop user already exist...skipping$NC"
fi

mkdir -p /app  &>>$LOGFILE
VALIDATE $? "Creating directory"

curl -L -o /tmp/payment.zip https://roboshop-builds.s3.amazonaws.com/payment.zip &>>$LOGFILE
VALIDATE $? "Downloading payment src"

cd /app &>>$LOGFILE
VALIDATE $? "Change directory"

unzip -o /tmp/payment.zip &>>$LOGFILE
VALIDATE $? "Unzip src"

pip3.6 install -r requirements.txt &>>$LOGFILE
VALIDATE $? "Installing dependencies"

cp "$PWD_PATH"/payment.service /etc/systemd/system/payment.service &>>$LOGFILE
VALIDATE $? "Copying payment.service file"

# Enter mongodb IP/domain name as input
read -p "Enter cart host: " CART_HOST
read -p "Enter user host: " USER_HOST
read -p "Enter rabbitmq host: " RABBITMQ_HOST
if [ -f "$SERVICE_FILE" ]; then
  # Replace IP
  sed -i "s/<CART-SERVER-IPADDRESS>/${CART_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  sed -i "s/<USER-SERVER-IPADDRESS>/${USER_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  sed -i "s/<RABBITMQ-SERVER-IPADDRESS>/${RABBITMQ_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  echo "Replacement successful."
else
  echo "Error: File not found - $SERVICE_FILE"
  exit 1
fi

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable payment  &>>$LOGFILE
VALIDATE $? "Enable payment service"

systemctl start payment &>>$LOGFILE
VALIDATE $? "Start payment service"

