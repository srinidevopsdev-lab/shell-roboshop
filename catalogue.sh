#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log
MONGODB_HOST="mongo.srinivasa.fun"
SCRIPT_DIR=$(pwd)
mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" | tee -a $LOG_FILE
if [ $USERID -ne 0 ]; then
    echo "Error::Please run this script as root user"
    exit 1 # failure is othere than 0 Means it will stop here dont run furthur
fi

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo "Error: $2 ... $R failure $N" | tee -a $LOG_FILE
        exit 1 # 1 for failure
    else
        echo -e "$2 ... $G successful $N" | tee -a $LOG_FILE
    fi
}

dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "Disable current module"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "Enable required module"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "roboshop user is created"

mkdir /app 
VALIDATE $? "creating app directory"
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading catalogue content"
cd /app 
VALIDATE $? "Changing to app directory"
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "unzip catalogue content"
npm install  &>>$LOG_FILE
VALIDATE $? "npm installing"
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "copying catalogue.service"
systemctl daemon-reload
VALIDATE $? "deamon reload"
systemctl enable catalogue  &>>$LOG_FILE
VALIDATE $? "Enable catalogue"

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo.repo"
dnf install mongodb-mongosh -y  &>>$LOG_FILE
VALIDATE $? "installing mongodb client"
mongosh --host $MONGODB_HOST </app/db/master-data.js  &>>$LOG_FILE
VALIDATE $? "load catlogue products"
systemctl restart catalogue 
VALIDATE $? "Restarting catalogue"
