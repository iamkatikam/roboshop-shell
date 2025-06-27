#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
INSTANCE_TYPE="t3.micro"
#KEY_NAME="roboshop-key"
SECURITY_GROUP="sg-0a30f9b8a8f6adb2b"
#REGION="us-west-2"  
INSTANCES=("mongodb" "catalogue" "user" "payment" "shipping" "frontend" "rabbitmq" "redis" "mysql" "dispatch" "cart")
ZONE_ID="Z0816687161ICZE30XIP3"
DOMAIN_NAME="rameshaws.site"


#for instance in "${INSTANCES[@]}"; do
for instance in $@
do
  INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --security-group-ids $SECURITY_GROUP --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=$instance}]" --query "Instances[0].InstanceId" --output text)
  if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PrivateIpAddress" --output text)
    RECORD_NAME="$instance.$DOMAIN_NAME"
  else
    IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID --query "Reservations[0].Instances[0].PublicIpAddress" --output text)
    RECORD_NAME="$DOMAIN_NAME"
  fi
  echo "Instance $instance created and IP adress is: $IP"

#Create Route 53 record
    aws route53 change-resource-record-sets --hosted-zone-id $ZONE_ID --change-batch '{
      "Changes": [
        {
          "Action": "UPSERT",
          "ResourceRecordSet": {
            "Name": "'"$RECORD_NAME"'",
            "Type": "A",
            "TTL": 1,
            "ResourceRecords": [{"Value": "'"$IP"'"}]
          }
        }
      ]
    }'
    echo "Route 53 record for $instance.$DOMAIN_NAME created with IP: $IP"
    echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
done
