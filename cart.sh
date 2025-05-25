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

#disable the nodejs module
echo -e "$Y Disabling NodeJS module... $N" | tee -a $LOG_FILE   
dnf module disable nodejs -y &>> $LOG_FILE
VALIDATE $? "NodeJS Module Disable"
echo -e "$G NodeJS module is disabled successfully. $N" | tee -a $LOG_FILE

#Enable NodeJS 20 module
echo -e "$Y Enabling NodeJS 20 module... $N" | tee -a $LOG_FILE 
dnf module enable nodejs:20 -y &>> $LOG_FILE
VALIDATE $? "NodeJS 20 Module Enable"
echo -e "$G NodeJS 20 module is enabled successfully. $N" | tee -a $LOG_FILE

#Install NodeJS
echo -e "$Y Installing NodeJS... $N" | tee -a $LOG_FILE
dnf install nodejs -y &>> $LOG_FILE
VALIDATE $? "NodeJS Installation"
echo -e "$G NodeJS is installed successfully. $N" | tee -a $LOG_FILE  

#validate if roboshop user exists
id roboshop
if [ $? -eq 0 ]; then
    # If the user exists, do nothing 
    echo -e "$G User roboshop exists. $N" | tee -a $LOG_FILE
else
    echo -e "$R User roboshop does not exist. $N" | tee -a $LOG_FILE
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $LOG_FILE
    VALIDATE $? "User Creation"
    echo -e "$G User roboshop is created successfully. $N" | tee -a $LOG_FILE
fi

#Create application directory  
APP_DIR="/app"
echo -e "$Y Creating application directory... $N" | tee -a $LOG_FILE
mkdir -p $APP_DIR &>> $LOG_FILE
VALIDATE $? "Application Directory Creation"
echo -e "$G Application directory is created successfully. $N" | tee -a $LOG_FILE

#Download application code
echo -e "$Y Downloading application code... $N" | tee -a $LOG_FILE
curl -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip
VALIDATE $? "Application Code Download"
echo -e "$G Application code is downloaded successfully. $N" | tee -a $LOG_FILE

#Extract application code
echo -e "$Y Extracting application code... $N" | tee -a $LOG_FILE  
cd $APP_DIR
rm -rf /app/* &>> $LOG_FILE
unzip /tmp/cart.zip &>> $LOG_FILE
VALIDATE $? "Application Code Extraction"
echo -e "$G Application code is extracted successfully. $N" | tee -a $LOG_FILE

#Install NodeJS dependencies
echo -e "$Y Installing NodeJS dependencies... $N" | tee -a $LOG_FILE
npm install &>> $LOG_FILE
VALIDATE $? "NodeJS Dependencies Installation"
echo -e "$G NodeJS dependencies are installed successfully. $N" | tee -a $LOG_FILE

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>> $LOG_FILE
VALIDATE $? "Service File Copy"
echo -e "$G Service file is copied successfully. $N" | tee -a $LOG_FILE

#Reload systemd daemon
echo -e "$Y Reloading systemd daemon... $N" | tee -a $LOG_FILE
systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Systemd Daemon Reload"
echo -e "$G Systemd daemon is reloaded successfully. $N" | tee -a $LOG_FILE

#Enable and start the service
echo -e "$Y Enabling and starting the cart service... $N" | tee -a $LOG_FILE
systemctl enable cart &>> $LOG_FILE
VALIDATE $? "cart Service Enable"  
echo -e "$G cart service is enabled successfully. $N" | tee -a $LOG_FILE

# Start the cart service
echo -e "$Y Starting the cart service... $N" | tee -a $LOG_FILE
systemctl start cart &>> $LOG_FILE
VALIDATE $? "cart Service Start"
echo -e "$G cart service is enabled and started successfully. $N" | tee -a $LOG_FILE

#Check the status of the service
echo -e "$Y Checking the status of the cart service... $N" | tee -a $LOG_FILE
systemctl status cart &>> $LOG_FILE
if [ $? -eq 0 ]; then
    echo -e "$G cart service is running successfully. $N" | tee -a $LOG_FILE
else
    echo -e "$R cart service is not running. Please check the logs for more details. $N" | tee -a $LOG_FILE
    exit 1
fi
echo -e "$G cart service setup completed successfully. $N" | tee -a $LOG_FILE

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script execution completed in $EXECUTION_TIME seconds. $N" | tee -a $LOG_FILE
