#!/bin/bash
#
# Script Name: EC2-Route53.sh
# Author: Narayanadasu Rakesh
# Version: 1.0
# Date: December 20, 2023
#
# Description: This script does create ec2 instance and maps domain name to Route53 A records.
#
# Usage: ./EC2-Route53.sh
#
#START#
GC="\e[32m"
NC="\e[0m"

IMAGE_ID="<ami-id>"
SG="<security-group-id>" 
INSTANCE=("web" "catalogue" "cart" "user" "shipping" "payment" "dispatch" "mongodb" "mysql" "redis" "rabbitmq")
DOMAIN_NAME="yourdomail.com"
ZONE_ID="<zone-id>"

for i in "${INSTANCE[@]}"
do
    if [ $i == "mongodb" ] || [ $i == "mysql" ] || [ $i == "shipping" ]
    then
        INSTANCE_TYPE="t3.small"
    else
        INSTANCE_TYPE="t2.micro"
    fi
    
    #Create EC2 Instance and Print Private IP Address
    IP_ADDR=$(aws ec2 run-instances --image-id $IMAGE_ID --instance-type $INSTANCE_TYPE --security-group-ids $SG --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value="$i"}]" --query 'Instances[0].[PrivateIpAddress]' --output text)
    echo "$GC $i: $IP_ADDR $NC"

    #Create Route53 A Records
    aws route53 change-resource-record-sets \
    --hosted-zone-id $ZONE_ID \
    --change-batch '
    {
        "Comment": "Creating A record"
        ,"Changes": [{
        "Action"              : "CREATE"
        ,"ResourceRecordSet"  : {
            "Name"              : "'$i'.'$DOMAIN_NAME'"
            ,"Type"             : "A"
            ,"TTL"              : 1
            ,"ResourceRecords"  : [{
                "Value"         : "'$IP_ADDR'"
            }]
        }
        }]
    }
        '
done

#END#