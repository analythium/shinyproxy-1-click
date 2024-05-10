#!/bin/bash

## Install ShinyProxy
export VERSION="3.1.0"
sudo wget https://www.shinyproxy.io/downloads/shinyproxy_${VERSION}_amd64.deb
sudo apt install -y ./shinyproxy_${VERSION}_amd64.deb
sudo rm shinyproxy_${VERSION}_amd64.deb

## Install certbot
snap install core; sudo snap refresh core
apt-get remove certbot
snap install --classic certbot
ln -s /snap/bin/certbot /usr/bin/certbot
