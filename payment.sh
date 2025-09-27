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
MYSQL_HOST="mysql.srinivasa.fun"
SCRIPT_DIR=$(pwd)
START_TIME=$(date +%s)
mkdir -p $LOGS_FOLDER
echo "script started executed at: $(date)" | tee -a $LOG_FILE
if [ $USERID -ne 0 ]; then
    echo "Error::Please run this script as root user"
    exit 1 # failure is othere than 0 Means it will stop here dont run furthur
fi

VALIDATE () {
    if [ $1 -ne 0 ]; then
        echo -e "Error: $2 ... $R failure $N" | tee -a $LOG_FILE
        exit 1 # 1 for failure
    else
        echo -e "$2 ... $G successful $N" | tee -a $LOG_FILE
    fi
}

dnf install python3 gcc python3-devel -y
id roboshop 
if [ $? -ne 0 ]; then    
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "roboshop user is created"
else
    echo -e "User already exist ....$Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading payment content"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "removing old"

unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "unzip payment content"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "PIP Install"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service  &>>$LOG_FILE
systemctl daemon-reload

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enable payment"

systemctl start payment  &>>$LOG_FILE
VALIDATE $? "Start payment"
