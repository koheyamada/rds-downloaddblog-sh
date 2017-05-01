#!/bin/bash

## Parameters.
export AWS_ACCESS_KEY_ID=""
export AWS_SECRET_ACCESS_KEY=""
export AWS_DEFAULT_REGION="ap-northeast-1"

INSTANCE="rds001"
LOG_TYPE="slowquery"
ZONE="JST"
BASE_DIR="/var/log/rds-log"

HOUR=`date -u +%H`
NUM=`expr $HOUR + 0`

# Zone
case "$ZONE" in
  UTC ) ZERO_HOURS=`expr $HOUR + 0` ;;
  JST ) ZERO_HOURS=`expr $HOUR + 9` ;;
esac
DATE=`date +%Y%m%d`
if [ $ZERO_HOURS -eq 0 ]; then
  DATE=`date --date '1 day ago' +%Y%m%d`
fi

## Command.
# Check the error log.
for i in $INSTANCE
do
  LOG_DIR="$BASE_DIR/$i"
  if [ ! -d $LOG_DIR ]; then
    mkdir $LOG_DIR
  fi
  LOG_NAME=`aws rds describe-db-log-files --db-instance-identifier $i --filename-contains $LOG_TYPE --output text | awk '{print $3}' | grep log.$NUM$`
  if [ $? -eq 0 ]; then
    aws rds download-db-log-file-portion --db-instance-identifier $i --log-file-name $LOG_NAME --output text >> $LOG_DIR/rds-$LOG_TYPE.$DATE.log
    if [ $? -ne 0 ]; then
      echo "error"
      exit 1
    fi
  fi
done

