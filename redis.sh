#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_DIR="/var/log/roboshop-scripts"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
echo -e "$G The name of the script is: $SCRIPT_NAME"
LOG_FILE="$LOGS_DIR/$SCRIPT_NAME.log"
echo -e "$G The log file is: $LOG_FILE $N"
mkdir -p $LOGS_DIR
echo "script started at $(date)"  | tee -a $LOG_FILE
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)

userid=$(id -u)
if [ $userid -ne 0 ]; then
    echo -e "$R You need to run this script as root or with sudo. $N"  | tee -a $LOG_FILE
    exit 1
    else
    echo "You are running this script as root." &>> $LOG_FILE
fi

VALIDATE(){
    if [ $1 -eq 0 ]; then
        echo -e "$2 is Successful." | tee -a $LOG_FILE
    else
        echo -e "$2 is not Successful." | tee -a $LOG_FILE
        exit 1
    fi
}

#disable the redis module
dnf module disable redis -y &>> $LOG_FILE
VALIDATE $? "Redis Module Disable"
echo -e "$G Redis module is disabled successfully. $N" | tee -a $LOG_FILE

#Enable Redis 7 module
dnf module enable redis:7 -y &>> $LOG_FILE
VALIDATE $? "Redis 7 Module Enable"
echo -e "$G Redis 7 module is enabled successfully. $N" | tee -a $LOG_FILE
#Install Redis
echo -e "$Y Installing Redis... $N" | tee -a $LOG_FILE
dnf install redis -y &>> $LOG_FILE
VALIDATE $? "Redis Installation"
echo -e "$G Redis is installed successfully. $N" | tee -a $LOG_FILE

#modify redis.conf
sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/c protected-mode no' /etc/redis/redis.conf &>> $LOG_FILE
VALIDATE $? "Redis Configuration Change"
echo -e "$G Redis Configuration Change is Successful. $N" | tee -a $LOG_FILE

#Enable and start Redis service
echo -e "$Y Enabling Redis service... $N" | tee -a $LOG_FILE
systemctl enable redis &>> $LOG_FILE
VALIDATE $? "Redis Service Enable"
echo -e "$G Redis Service Enable is Successful. $N" | tee -a $LOG_FILE

# Start Redis service
echo -e "$Y Starting Redis service... $N" | tee -a $LOG_FILE
systemctl start redis &>> $LOG_FILE
VALIDATE $? "Redis Service Start"
echo -e "$G Redis Service Start is Successful. $N" | tee -a $LOG_FILE

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script execution completed in $EXECUTION_TIME seconds. $N" | tee -a $LOG_FILE
