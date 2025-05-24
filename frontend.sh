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

#disable the nginx module
dnf module disable nginx -y &>> $LOG_FILE
VALIDATE $? "Nginx Module Disable"
echo -e "$G Nginx module is disabled successfully. $N" | tee -a $LOG_FILE

#Install Nginx 1.24
echo -e "$Y Installing Nginx 1.24... $N" | tee -a $LOG_FILE
dnf module enable nginx:1.24 -y &>> $LOG_FILE
dnf install nginx -y &>> $LOG_FILE
VALIDATE $? "Nginx Installation"    
echo -e "$G Nginx is installed successfully. $N" | tee -a $LOG_FILE

#start Nginx service
echo -e "$Y Starting Nginx service... $N" | tee -a $LOG_FILE
systemctl enable nginx &>> $LOG_FILE
VALIDATE $? "Nginx Service Enable"

# Start Nginx service
echo -e "$Y Starting Nginx service... $N" | tee -a $LOG_FILE
systemctl start nginx &>> $LOG_FILE
VALIDATE $? "Nginx Service Start"
echo -e "$G Nginx service is started successfully. $N" | tee -a $LOG_FILE

rm -rf /usr/share/nginx/html/* 
echo -e "$Y Removing default Nginx content... $N" | tee -a $LOG_FILE

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  
VALIDATE $? "Frontend Zip Download"
echo -e "$G Frontend Zip Download is Successful. $N" | tee -a $LOG_FILE

echo -e "$Y Unzipping frontend content... $N" | tee -a $LOG_FILE
cd /usr/share/nginx/html
unzip /tmp/frontend.zip &>> $LOG_FILE
VALIDATE $? "Frontend Unzip"
echo -e "$G Frontend Unzip is Successful. $N" | tee -a $LOG_FILE

rm -rf /etc/nginx/nginx.conf
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>> $LOG_FILE
VALIDATE $? "Nginx Configuration Copy"
echo -e "$G Nginx Configuration Copy is Successful. $N" | tee -a $LOG_FILE

# Restart Nginx service
systemctl restart nginx &>> $LOG_FILE
VALIDATE $? "Nginx Service Restart"
echo -e "$G Nginx Service Restart is Successful. $N" | tee -a $LOG_FILE
echo "script ended at $(date)"  | tee -a $LOG_FILE
echo -e "$G Script execution completed successfully. $N" | tee -a $LOG_FILE
