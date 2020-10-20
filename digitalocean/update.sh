#!/bin/bash

# usage:
# `bash update.sh file` where file is the application.yml file

db=$(grep 'container-image:' $1 | sed 's/[^:]*://' | sed 's/^[[:space:]]*//g')
while IFS= read -r line; do docker pull $line; done <<< "$db"
