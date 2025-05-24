#!/bin/bash

AMI_ID="ami-09c813fb71547fc4f"
#INSTANCE_TYPE="t2.micro"
#KEY_NAME="roboshop-key"
SECURITY_GROUP="sg-0aba3fdb97c048851"
#REGION="us-west-2"  
ISTTANCES=("mongodb" "catalogue" "user" "payment" "shipping" "frontend" "rabbitmq" "redis" "mysql" "dispatch" "cart")
ZONE_ID="Z0816687161ICZE30XIP3"
DOMAIN_NAME="rameshaws.site"

for instance in "${ISTTANCES[@]}"; do
  INSTANCE_ID=$(aws ec2 run-instances \
    --image-id ami-09c813fb71547fc4f \
    --instance-type t2.micro \
    --security-group-ids sg-0aba3fdb97c048851 \
    --tag-specifications "ResourceType=instance,Tags=[{Key=Name, Value=test}]" \
	--query "Instances[0].InstanceId"
	--output text)
  if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PrivateIpAddress" \
    --output text)
  else
    IP=$(aws ec2 describe-instances \
    --instance-ids $INSTANCE_ID \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)
  fi
  echo "Instance $instance created with ID: $INSTANCE_ID and IP: $IP"
done
