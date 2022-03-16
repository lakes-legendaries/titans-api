#!/bin/bash

# error on failure
set -e

# setup unix
sudo apt-get update
sudo apt-get install -y ca-certificates curl git gnupg lsb-release

# access docker repository
KEYFILE=/usr/share/keyrings/docker-archive-keyring.gpg
sudo rm -f $KEYFILE
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o $KEYFILE
echo "deb [arch=$(dpkg --print-architecture) signed-by=$KEYFILE] \
    https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# get ssl/tls certificates for secure https connection
sudo apt-get install -y snapd
sudo snap install core
sudo snap refresh core
sudo apt-get remove -y certbot
sudo ln --force -s /snap/bin/certbot /usr/bin/certbot
sudo certbot certonly --standalone -n --domains titansapi.eastus.cloudapp.azure.com

# create startup command
REPO=https://raw.githubusercontent.com/lakes-legendaries/titans-api
FILE=main/webserver/startup.sh
curl $REPO/$FILE > ~/startup.sh
chmod +x ~/startup.sh

# schedule startup command, and plan monthly reboot
echo "@reboot $HOME/startup.sh" | sudo tee /var/spool/cron/crontabs/$USER
echo "0 0 1 * * reboot" | sudo tee /var/spool/cron/crontabs/root
sudo chmod 0600 /var/spool/cron/crontabs/$USER
sudo chmod 0600 /var/spool/cron/crontabs/root

# run startup script
~/startup.sh
