#!/bin/bash

# Usage 
#
# `bash setup.sh -i ~/.ssh/id_rsa -s root@ip_address -f application.yml`
#
# -i: ssh key
# -s: user@ip_address
# -f: /path/to/application.yml file

# Registry login (do it only once)
#
# Log in to host via ssh and add access token into a file:
# `echo your_token > ./token.txt`
# this will be used to pass token via stdin:
# `cat ./token.txt | docker login --username username --password-stdin registryname`
# Change `--username username` to your username and `registryname` to the registry.

while getopts i:s:f: flag
do
    case "${flag}" in
        i) key=${OPTARG};;
        s) server=${OPTARG};;
        f) file=${OPTARG};;
    esac
done

echo "[INFO] Copying $file to host"
scp -q -i $key $file $server:/etc/shinyproxy/application.yml
ssh -i $key $server /bin/bash << EOF
echo "[INFO] Updating docker images according to application.yaml"
curl -s https://raw.githubusercontent.com/analythium/shinyproxy-1-click/master/digitalocean/update.sh -o update.sh
bash ./update.sh /etc/shinyproxy/application.yml
echo "[INFO] Restarting ShinyProxy"
sudo service shinyproxy restart
#echo "[INFO] Restarting Docker Engine"
#sudo service docker restart
rm ./update.sh
echo "[INFO] Done"
EOF
