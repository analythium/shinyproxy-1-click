#!/bin/bash

# usage: `bash setup.sh -i ~/.ssh/id_rsa -s root@ip_address -f application.yml`
# -i: ssh key
# -s: user@ip_address
# -f: /path/to/application.file

# uncomment lines as needed for registry login

while getopts i:s:f: flag
do
    case "${flag}" in
        i) key=${OPTARG};;
        s) server=${OPTARG};;
        f) file=${OPTARG};;
    esac
done

echo ">>> Copying $file to droplet"
scp -i $key $file $server:/etc/shinyproxy/application.yml

ssh -i $key $server /bin/bash << EOF
#  echo ">>> Logging into registry"
#  docker login registry.gitlab.com
  echo ">>> Updating docker images according to application.yaml"
  wget -O ./update.sh https://raw.githubusercontent.com/analythium/shinyproxy-1-click/master/digitalocean/update.sh
  bash ./update.sh /etc/shinyproxy/application.yml
  echo ">>> Restarting ShinyProxy"
  sudo service shinyproxy restart
  rm ./update.sh
  echo ">>> Done"
EOF
