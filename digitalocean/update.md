# Updating DigitalOcean 1-Click app for ShinyProxy

> This document guides you through how to update ShinyProxy

[![DO button](https://raw.githubusercontent.com/analythium/shinyproxy-1-click/master/digitalocean/images/do-btn-blue.svg)](https://marketplace.digitalocean.com/apps/shinyproxy)

## 1. Create and edit application.yml

Create and `application.yml` file or use the file in this directory as a starting point.

## 2. Provide credentials for private registry login

This step is optional if private registry access is needed for pulling Docker images.

Log into your droplet via ssh and lig into your registry via `docker login`
(Docker Hub by default, use `docker login registry.gitlab.com` for the GitLab 
container registry). You will be asked to authenticate interactively
and your access token (not password) will be saved on the droplet.

Uncomment lines as needed for registry login:

```bash
echo ">>> Logging into registry"
docker login registry.gitlab.com
```

## Usage

```bash
bash setup.sh -i ~/.ssh/id_rsa -s root@ip_address -f application.yml
```

The following command line arguments need to be passed to the `setup.sh` script:

- `-i`: your ssh key,
- `-s`: user name (root for DigitalOcean droplets) and the IP address: `user@ip_address`,
- `-f`: path and file name to the yml with the ShinyProxy config, e.g. `/path/to/application-new.yml`.

## What the script does

1. Copies the `application.yml` to the droplet,
2. logs into private registry (optional),
3. pulls the docker images listed in the `application.yml` file,
4. and restarts ShinyProxy.
