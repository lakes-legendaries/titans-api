#!/bin/bash

# exit on error
set -e

# renew certificates
sudo certbot renew

# remove unused docker images and containers
CONTAINERS=$(sudo docker ps -aq)
if [ ! -z "$CONTAINERS" ]; then
    sudo docker rm --force "$CONTAINERS"
fi
sudo docker system prune --force --all

# clone repo
rm -rfd titans-api
git clone https://github.com/lakes-legendaries/titans-api.git

# copy certs into secrets
for FILE in \
    /etc/letsencrypt/live/titansapi.eastus.cloudapp.azure.com/fullchain.pem \
    /etc/letsencrypt/live/titansapi.eastus.cloudapp.azure.com/privkey.pem \
; do
    sudo cp $FILE ~/secrets/
done

# build docker image
cd titans-api
sudo docker build -t titans-api .
cd ..

# sync secrets files
SECRETS_URL=https://titansfileserver.blob.core.windows.net/webserver/secrets
SECRETS_SAS=$(cat ~/secrets/titans-fileserver-sas)
sudo docker run -v ~/secrets:/secrets titans-api \
    /bin/bash -c "azcopy cp '$SECRETS_URL/*$SECRETS_SAS' '/secrets/'"

# run docker container
sudo docker run -dp 443:443 -v ~/secrets:/secrets titans-api

# clean up
rm -rfd titans-api
