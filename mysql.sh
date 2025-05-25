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

#Set MySQL root password
echo "Enter the MySQL root password:"
read -s MYSQL_ROOT_PASSWORD

#install MySQL
echo -e "$Y Installing MySQL... $N" | tee -a $LOG_FILE
dnf install mysql-server -y &>> $LOG_FILE
VALIDATE $? "MySQL Installation"    
echo -e "$G MySQL Installation is Successful. $N" | tee -a $LOG_FILE

#Enable MySQL service
echo -e "$Y Enabling MySQL service... $N" | tee -a $LOG_FILE
systemctl enable mysqld &>> $LOG_FILE
VALIDATE $? "MySQL Service Enable"
echo -e "$G MySQL Service Enable is Successful. $N" | tee -a $LOG_FILE

#start MySQL service
echo -e "$Y Starting MySQL Service... $N" | tee -a $LOG_FILE
systemctl start mysqld &>> $LOG_FILE
VALIDATE $? "MySQL Service Start"
echo -e "$G MySQL Service Start is Successful. $N" | tee -a $LOG_FILE


mysql_secure_installation --set-root-pass MYSQL_ROOT_PASSWORD

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script execution completed in $EXECUTION_TIME seconds. $N" | tee -a $LOG_FILE
