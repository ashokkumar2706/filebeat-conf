#!/bin/sh

set -e

environment=$env

if [[ "$environment" == "sit" ]]
then
  rm -rf /etc/filebeat/prod-filebeat.yml /etc/filebeat/uat-filebeat.yml
elif [[ "$environment" == "prod" ]]
then
  rm -rf /etc/filebeat/sit-filebeat.yml /etc/filebeat/uat-filebeat.yml
  exit 0
elif [[ "$environment" == "uat" ]]
then
  rm -rf /etc/filebeat/prod-filebeat.yml /etc/filebeat/sit-filebeat.yml
  exit 0
else
  echo " Please provide only sit,uat,prod env"
fi


# if command starts with an option, prepend filebeat (executable)
if [ "${1:0:1}" = '-' ]; then
	set -- filebeat "$@"
fi

# Set Logstash host if needed
LOGSTASH_HOST_COUNT=`grep LOGSTASH_HOST /etc/filebeat/$environment-filebeat.yml | wc -l`
if [ $LOGSTASH_HOST_COUNT -gt 0 ]; then
  if [ -z "$LOGSTASH_HOST" ]; then
    echo "LOGSTASH_HOST environment variable must be supplied" 1>&2;
    exit -1
  else
    sed --in-place "s/LOGSTASH_HOST/$LOGSTASH_HOST/" /etc/filebeat/$environment-filebeat.yml
  fi
fi

# Optionally enable TLS/SSL
if [ "$TLS" == "true" ]; then
  echo "Enabling TLS/SSL"
  sed --in-place "s/# tls:/tls:/" /etc/filebeat/$environment-filebeat.yml
  
  if [ "$INSECURE" == "true" ]; then
    echo "Allowing insecure TLS/SSL"
    sed --in-place "s/#  insecure: true/  insecure: true/" /etc/filebeat/$environment-filebeat.yml
  fi
fi
sleep 500000
exec "$@"
