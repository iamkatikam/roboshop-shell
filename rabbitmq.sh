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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> $LOG_FILE
VALIDATE $? "RabbitMQ Repo Copy"
echo -e "$G RabbitMQ Repo Copy is Successful. $N" | tee -a $LOG_FILE

#Install rabbitmq-server
echo -e "$Y Installing RabbitMQ Server... $N" | tee -a $LOG_FILE
dnf install rabbitmq-server -y &>> $LOG_FILE
VALIDATE $? "RabbitMQ Server Installation"
echo -e "$G RabbitMQ Server Installation is Successful. $N" | tee -a $LOG_FILE

#Enable and start RabbitMQ service
echo -e "$Y Enabling RabbitMQ Service... $N" | tee -a $LOG_FILE
systemctl enable rabbitmq-server &>> $LOG_FILE
VALIDATE $? "RabbitMQ Service Enable"
echo -e "$G RabbitMQ Service Enable is Successful. $N" | tee -a $LOG_FILE
echo -e "$Y Starting RabbitMQ Service... $N" | tee -a $LOG_FILE
systemctl start rabbitmq-server &>> $LOG_FILE
VALIDATE $? "RabbitMQ Service Start"
echo -e "$G RabbitMQ Service Start is Successful. $N" | tee -a $LOG_FILE

rabbitmqctl add_user roboshop roboshop123
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script execution completed in $EXECUTION_TIME seconds. $N" | tee -a $LOG_FILE
