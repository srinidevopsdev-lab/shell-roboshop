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
SCRIPT_DIR=$($pwd)
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

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo  &>>$LOG_FILE
VALIDATE $? "Copying rabbitmq repo"
dnf install rabbitmq-server -y  &>>$LOG_FILE
VALIDATE $? "Installing rabbitmq "
systemctl enable rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "Enabling rabbitmq "
systemctl start rabbitmq-server  &>>$LOG_FILE
VALIDATE $? "Starting rabbitmq"
rabbitmqctl add_user roboshop roboshop123 &>>$LOG_FILE
VALIDATE $? "Adding rabbitmq user"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"
VALIDATE $? "Set permissions rabbitmq"

END_TIME=$(date +%s)
TOTAL_TIME=$(($END_TIME - $START_TIME))
echo -e "Script executed time: $Y $TOTAL_TIME $N"