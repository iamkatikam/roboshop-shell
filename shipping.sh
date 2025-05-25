#!/bin/bash

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

USERID=$(id -u)
LOGS_DIR="/var/log/roboshop-scripts"
SCRIPT_NAME=$(echo $0 | cut -d '.' -f1)
echo -e "$G The name of the script is: $SCRIPT_NAME"
LOG_FILE="$LOGS_DIR/$SCRIPT_NAME.log"
echo -e "$G The log file is: $LOG_FILE $N"
mkdir -p $LOGS_DIR
echo "script started at $(date)"  | tee -a $LOG_FILE
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)


if [ $USERID -ne 0 ]; then
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

#Install maven
echo -e "$Y Installing Maven... $N" | tee -a $LOG_FILE
dnf install maven -y &>> $LOG_FILE
VALIDATE $? "Maven Installation"
echo -e "$G Maven is installed successfully. $N" | tee -a $LOG_FILE

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
curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip
VALIDATE $? "Application Code Download"
echo -e "$G Application code is downloaded successfully. $N" | tee -a $LOG_FILE

#Extract application code
echo -e "$Y Extracting application code... $N" | tee -a $LOG_FILE  
cd $APP_DIR
rm -rf /app/* &>> $LOG_FILE
unzip /tmp/shipping.zip &>> $LOG_FILE
VALIDATE $? "Application Code Extraction"
echo -e "$G Application code is extracted successfully. $N" | tee -a $LOG_FILE

mvn clean package 
VALIDATE $? "Maven Packaege"
echo -e "$G Maven package is successful. $N" | tee -a $LOG_FILE

#moving and renaming the jar file
echo -e "$Y Moving and renaming the jar file... $N" | tee -a $LOG_FILE
mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "Jar File Move and Rename"
echo -e "$G Jar file is moved and renamed successfully. $N" | tee -a $LOG_FILE

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>> $LOG_FILE
VALIDATE $? "Service File Copy"
echo -e "$G Service file is copied successfully. $N" | tee -a $LOG_FILE

#reload systemd to recognize the new service
echo -e "$Y Reloading systemd daemon... $N" | tee -a $LOG_FILE
systemctl daemon-reload &>> $LOG_FILE
VALIDATE $? "Systemd Daemon Reload"
echo -e "$G Systemd daemon is reloaded successfully. $N" | tee -a $LOG_FILE

#Enable and start the service
echo -e "$Y Enabling and starting the shipping service... $N" | tee -a $LOG_FILE
systemctl enable shipping &>> $LOG_FILE
VALIDATE $? "Shipping Service Enable"
systemctl start shipping &>> $LOG_FILE
VALIDATE $? "Shipping Service Start"
echo -e "$G Shipping service is enabled and started successfully. $N" | tee -a $LOG_FILE

dnf install mysql -y &>> $LOG_FILE
VALIDATE $? "MySQL Installation"
echo -e "$G MySQL is installed successfully. $N" | tee -a $LOG_FILE

mysql -h mysql.rameshaws.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql
mysql -h mysql.rameshaws.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql 
mysql -h mysql.rameshaws.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql
VALIDATE $? "MySQL loading schema"
echo -e "$G MySQL schema and data are loaded successfully. $N" | tee -a $LOG_FILE


systemctl restart shipping
VALIDATE $? "Shipping Service Restart"
echo -e "$G Shipping service is restarted successfully. $N" | tee -a $LOG_FILE

END_TIME=$(date +%s)
EXECUTION_TIME=$((END_TIME - START_TIME))
echo -e "$G Script execution completed in $EXECUTION_TIME seconds. $N" | tee -a $LOG_FILE
