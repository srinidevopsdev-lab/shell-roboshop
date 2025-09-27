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

dnf install maven -y
id roboshop 
if [ $? -ne 0 ]; then    
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "roboshop user is created"
else
    echo -e "User already exist ....$Y skipping $N"
fi

mkdir -p /app 
VALIDATE $? "creating app directory"

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading shipping content"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/*
VALIDATE $? "removing old"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "unzip shipping content"

mvn clean package &>>$LOG_FILE
VALIDATE $? "unzip shipping content"

mv target/shipping-1.0.jar shipping.jar 
VALIDATE $? "unzip shipping content"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service

systemctl daemon-reload

systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enable shipping"

#systemctl start shipping

dnf install mysql -y &>>$LOG_FILE
mysql -h $MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
if [ $? -ne 0 ]; then
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h $MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql &>>$LOG_FILE
else
    echo -e "Shipping data is already loaded ....$Y Skipping $N"
fi
VALIDATE $? "Installing mysql client"
systemctl restart shipping
VALIDATE $? "Restart shipping"