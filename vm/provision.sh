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

# create startup command
STARTUP=~/run-app.sh
echo "
#!/bin/bash

# exit on error
set -e

# remove unused docker images and containers
sudo docker system prune --force --all

# clone repo
rm -rfd titans-api
git clone https://github.com/lakes-legendaries/titans-api.git

# inject secrets into Dockerfile
SECRET=$(echo $(cat titans-fileserver) | sed -E 's/(.)/\\\1/g')
sed -i 's/\$AZURE_STORAGE_CONNECTION_STRING/'"$SECRET"'/g' \
    titans-api/Dockerfile

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

# set startup command to run on reboot, and set monthly reboot
echo "
@reboot $STARTUP
0 0 1 * * reboot
" | sudo tee /var/spool/cron/crontabs/root &> /dev/null

# run startup script
$STARTUP
