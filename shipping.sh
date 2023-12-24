#!/bin/bash

ID=$(id -u)
TIMESTAMP=$(date +%F-%H-%M-%S)
LOGFILE="/tmp/$0-$TIMESTAMP"
SERVICE_FILE="/etc/systemd/system/shipping.service"
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

echo -e "$YC Installing maven.....$NC"
dnf install maven -y &>>$LOGFILE
VALIDATE $? "Installing maven"

#creating user
id roboshop &>>$LOGFILE
if [ $? -ne 0 ]
then
  useradd roboshop &>>$LOGFILE
  VALIDATE $? "USER CREATING"
else
  echo -e "$YC roboshop user already exist...skipping$NC"
fi

mkdir -p /app &>>$LOGFILE
VALIDATE $? "creating app directory"

curl -L -o /tmp/shipping.zip https://roboshop-builds.s3.amazonaws.com/shipping.zip &>>$LOGFILE
VALIDATE $? "Downloading shipping.zip file"

cd /app &>>$LOGFILE
VALIDATE $? "Changing into app directory"

unzip -o /tmp/shipping.zip &>>$LOGFILE
VALIDATE $? "unzip file"

echo -e "$YC Installing dependencies.....$NC"
mvn clean package &>>$LOGFILE 
VALIDATE $? "Installing Dependencies"

mv target/shipping-1.0.jar shipping.jar &>>$LOGFILE
VALIDATE $? "renaming and moving shipping.jar into app directory from target directory"

cp "$PWD_PATH"/shipping.service /etc/systemd/system/shipping.service &>>$LOGFILE
VALIDATE $? "Copying shipping.service file "

# Enter mongodb IP/domain name as input
read -p "Enter cart host: " CART_HOST
read -p "Enter mysql host: " MYSQL_HOST
if [ -f "$SERVICE_FILE" ]; then
  # Replace IP
  sed -i "s/<CART-SERVER-IPADDRESS>/${CART_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  sed -i "s/<MYSQL-SERVER-IPADDRESS>/${MYSQL_HOST}/g" "$SERVICE_FILE" &>> "$LOGFILE"
  echo "Replacement successful."
else
  echo "Error: File not found - $SERVICE_FILE"
  exit 1
fi

systemctl daemon-reload &>>$LOGFILE
VALIDATE $? "Daemon reload"

systemctl enable shipping  &>>$LOGFILE
VALIDATE $? "Enable shipping"

systemctl start shipping &>>$LOGFILE
VALIDATE $? "Starting shipping"

echo -e "$YC Installing mysql client.....$NC"
dnf install mysql -y &>>$LOGFILE
VALIDATE $? "Installing mysql client"

mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/schema/shipping.sql  &>>$LOGFILE
VALIDATE $? "loading schema"

systemctl restart shipping &>>$LOGFILE
VALIDATE $? "Restarting shipping"

