#!/bin/bash

# setup unix
sudo apt-get update
sudo apt-get install -y ca-certificates curl git gnupg lsb-release

# access docker repository
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker engine
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# build titans-api docker image
git clone https://github.com/lakes-legendaries/titans-api.git
cd titans-api
sudo docker build -t titans-api .

# start image on vm startup
STARTUP=/etc/init.d/run-app.sh
echo "sudo docker run -dp 80:80 titans-api" > $STARTUP
chmod +x $STARTUP
