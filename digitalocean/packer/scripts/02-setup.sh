#!/bin/bash

## Enable Docker
systemctl daemon-reload
systemctl restart docker
systemctl enable docker

## Pull Docker images
docker pull registry.gitlab.com/analythium/shinyproxy-hello/hello:latest
docker pull analythium/shinyproxy-demo:latest

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
ufw allow https
ufw --force enable

# make bootstrap script executable
sudo chmod +x /opt/shinyproxy/boot_strap.sh
# make copy of .bashrc
sudo cp -f /root/.bashrc /etc/skel/.bashrc
# run this 1st time when root logs in via ssh
sudo echo '/opt/shinyproxy/boot_strap.sh' >> /root/.bashrc 

# To uninstall the agent and remove the DO directory
apt-get purge droplet-agent* -y

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
echo -------------------------------
certbot --version
echo ===============================

# test
echo !!!!!!!!!!!!!!!!!!!!!!! TESTING START !!!!!!!!!!!!!!!!!!!!!
ls -al /opt/shinyproxy/
ls -al /etc/shinyproxy/
systemctl status nginx
systemctl status docker
systemctl status shinyproxy
echo !!!!!!!!!!!!!!!!!!!!!!! TESTING END !!!!!!!!!!!!!!!!!!!!!
