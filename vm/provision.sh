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
sudo ln -s /snap/bin/certbot /usr/bin/certbot
sudo certbot certonly --standalone -n --domains titansapi.eastus.cloudapp.azure.com

# create startup command
STARTUP=~/run-app.sh
echo "
#!/bin/bash

# exit on error
set -e

# renew certificates
sudo certbot renew

# remove unused docker images and containers
CONTAINERS=\$(sudo docker ps -aq)
if [ ! -z \"\$CONTAINERS\" ]; then
    sudo docker rm --force \$CONTAINERS
fi
sudo docker system prune --force --all

# clone repo
rm -rfd titans-api
git clone https://github.com/lakes-legendaries/titans-api.git

# copy secrets into docker context
for FILE in \
    titans-fileserver \
    /etc/letsencrypt/live/titansapi.eastus.cloudapp.azure.com/fullchain.pem \
    /etc/letsencrypt/live/titansapi.eastus.cloudapp.azure.com/privkey.pem \
; do
    sudo cp \$FILE titans-api/
done

# build docker image
cd titans-api
sudo docker build -t titans-api .
cd ..

# run docker container
sudo docker run -dp 443:443 titans-api

# clean up
rm -rfd titans-api
" > $STARTUP
chmod +x $STARTUP

# set startup command to run on reboot, and set monthly reboot
echo "
@reboot $STARTUP
0 0 1 * * reboot
" | sudo tee /var/spool/cron/crontabs/root &> /dev/null

# run startup script
$STARTUP
