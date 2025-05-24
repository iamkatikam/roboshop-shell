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

cp mongodb.repo /etc/yum.repos.d/mongodb.repo &>> $LOG_FILE
VALIDATE $? "MongoDB Repo Copy"
echo -e "$G MongoDB Repo Copy is Successful. $N" | tee -a $LOG_FILE
echo -e "$Y Installing MongoDB... $N" | tee -a $LOG_FILE
# Install MongoDB
dnf install mongodb-org -y &>> $LOG_FILE
VALIDATE $? "MongoDB Installation"
echo -e "$G MongoDB Installation is Successful. $N" | tee -a $LOG_FILE
echo -e "$Y Starting MongoDB Service... $N" | tee -a $LOG_FILE
# Start MongoDB Service
systemctl enable mongod &>> $LOG_FILE
VALIDATE $? "MongoDB Service Enable"
echo -e "$G MongoDB Service Enable is Successful. $N" | tee -a $LOG_FILE
systemctl start mongod &>> $LOG_FILE
VALIDATE $? "MongoDB Service Start"
echo -e "$G MongoDB Service Start is Successful. $N" | tee -a $LOG_FILE

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf &>> $LOG_FILE  
VALIDATE $? "MongoDB Configuration Change"
echo -e "$G MongoDB Configuration Change is Successful. $N" | tee -a $LOG_FILE  
echo -e "$Y Restarting MongoDB Service... $N" | tee -a $LOG_FILE
# Restart MongoDB Service
systemctl restart mongod &>> $LOG_FILE
VALIDATE $? "MongoDB Service Restart"
echo -e "$G MongoDB Service Restart is Successful. $N" | tee -a $LOG_FILE
