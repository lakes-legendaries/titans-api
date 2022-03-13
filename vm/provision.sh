#!/bin/bash

# error on failure
set -e

# setup unix
sudo apt-get update
sudo apt-get install -y ca-certificates curl git gnupg lsb-release

# access docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg -y --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# create startup command
STARTUP=~/run-app.sh
echo "
#!/bin/bash

# exit on error
set -e

# clone repo
rm -rfd titans-api
git clone https://github.com/lakes-legendaries/titans-api.git

# build docker image
cd titans-api
sudo docker build -t titans-api .
cd ..

# run docker container
sudo docker run -dp 80:80 titans-api

# clean up
rm -rfd titans-api
" > $STARTUP
chmod +x $STARTUP

# set startup command to run on reboot
echo "@reboot ~/run-app.sh" | \
    sudo tee /var/spool/cron/crontabs/root &> /dev/null
