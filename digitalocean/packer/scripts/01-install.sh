#!/bin/bash

## Install Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt -qqy update
sudo apt -qqy install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose

## Install ShinyProxy
export VERSION="3.1.1"
sudo wget -nv https://www.shinyproxy.io/downloads/shinyproxy_${VERSION}_amd64.deb
sudo apt install -y ./shinyproxy_${VERSION}_amd64.deb
sudo rm shinyproxy_${VERSION}_amd64.deb

## Install certbot
snap install core; sudo snap refresh core
apt-get remove certbot
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
