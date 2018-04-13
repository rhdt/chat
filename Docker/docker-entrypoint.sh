#!/bin/bash
MM_HOME=/opt/mattermost
MM_CONFIG=${MM_HOME}/config/config.json
MM_CONFIG_ORIG=${MM_HOME}/config.json.orig

function updatejson() {
  set -o nounset
  key=$1
  value=$2
  file=$3
  jq "$key = \"$value\"" $file > ${file}.new
  mv ${file}.new ${file}
  echo "Set key $key in file $file"
  set +o nounset
}

if [[ ! -f $MM_CONFIG ]]; then
  cp -f $MM_CONFIG_ORIG $MM_CONFIG
fi

if [[ "$1" == "mattermost" ]]; then
  if [[ -z $MM_DB_HOST ]]; then echo "MM_DB_HOST not set."; exit 1; fi
  if [[ -z $MM_DB_PORT ]]; then echo "MM_DB_PORT not set."; exit 1; fi
  if [[ -z $MM_DB_USER ]]; then echo "MM_DB_USER not set."; exit 1; fi
  if [[ -z $MM_DB_PASS ]]; then echo "MM_DB_PASS not set."; exit 1; fi
  if [[ -z $MM_DB_NAME ]]; then echo "MM_DB_NAME not set."; exit 1; fi

  echo "Updating mattermost configuration..."
  updatejson ".SqlSettings.DriverName" "postgres" $MM_CONFIG
  updatejson ".SqlSettings.DataSource" "postgres://${MM_DB_USER}:${MM_DB_PASS}@${MM_DB_HOST}:${MM_DB_PORT}/${MM_DB_NAME}?sslmode=disable&connect_timeout=10" $MM_CONFIG

  # Check if we want to use S3 for data storage
  if [[ "$MM_USE_S3" == "true" ]]; then
    if [[ -z $MM_S3_ACCESS_KEY_ID ]]; then echo "MM_S3_ACCESS_KEY_ID not set."; exit 1; fi
    if [[ -z $MM_S3_SECRET_ACCESS_KEY ]]; then echo "MM_S3_SECRET_ACCESS_KEY not set."; exit 1; fi
    if [[ -z $MM_S3_BUCKET ]]; then echo "MM_S3_BUCKET not set."; exit 1; fi

    MM_S3_REGION=${MM_S3_REGION:-us-east-1}
    MM_S3_ENDPOINT=${MM_S3_ENDPOINT:-s3.amazonaws.com}

    updatejson ".FileSettings.DriverName" "amazons3" $MM_CONFIG
    updatejson ".FileSettings.AmazonS3AccessKeyId" "${MM_S3_ACCESS_KEY_ID}" $MM_CONFIG
    updatejson ".FileSettings.AmazonS3SecretAccessKey" "${MM_S3_SECRET_ACCESS_KEY}" $MM_CONFIG
    updatejson ".FileSettings.AmazonS3Bucket" "${MM_S3_BUCKET}" $MM_CONFIG
    updatejson ".FileSettings.AmazonS3Region" "${MM_S3_REGION}" $MM_CONFIG
    updatejson ".FileSettings.AmazonS3Endpoint" "${MM_S3_ENDPOINT}" $MM_CONFIG
  
  fi

  while ! echo | nc -w1 $MM_DB_HOST $MM_DB_PORT > /dev/null 2>&1; do
    echo "Could not connect to database at ${MM_DB_HOST}:${MM_DB_PORT}... Retrying..."
    sleep 1
  done
  
  echo "Starting platform"
  cd ${MM_HOME}
  ./bin/platform
else
  exec "$@"
fi
