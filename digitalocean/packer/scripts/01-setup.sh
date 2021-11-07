#!/bin/bash

## Enable Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

## Pull Docker images
docker pull registry.gitlab.com/analythium/shinyproxy-hello/hello:latest
docker pull analythium/shinyproxy-demo:latest

## Install ShinyProxy
export VERSION="2.6.0"
wget https://www.shinyproxy.io/downloads/shinyproxy_${VERSION}_amd64.deb
apt install ./shinyproxy_${VERSION}_amd64.deb
rm shinyproxy_${VERSION}_amd64.deb

## Allow ShinyProxy to write logs
sudo mkdir /etc/shinyproxy/logs
sudo chown -R shinyproxy:shinyproxy /etc/shinyproxy/logs

## Restart ShinyProxy
service shinyproxy restart

## Restart Nginx
service nginx restart

# Setting firewall rules
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
#ufw allow https
ufw --force enable

echo ===============================
echo Version info:
echo 
echo -------------------------------
echo ShinyProxy $VERSION
echo -------------------------------
java -version 
echo -------------------------------
docker -v
echo -------------------------------
docker-compose -v
echo -------------------------------
nginx -v
echo -------------------------------
ufw version
echo ===============================
