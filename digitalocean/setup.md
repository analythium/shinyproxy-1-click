# Setup DigitalOcean 1-Click app for ShinyProxy

> This document guides you through the 1-click setup process for ShinyProxy

[![DO button](https://raw.githubusercontent.com/analythium/shinyproxy-1-click/master/digitalocean/images/do-btn-blue.svg)](https://marketplace.digitalocean.com/apps/shinyproxy?refcode=a8041699739d)

Using the DigitalOcean Marketplace, we can deliver a truly seamless experience for users,
creating the ability for developers to deploy fully-tested app environments with the click of a button.

## Step 1: Become a vendor on the DigitalOcean Marketplace

Click on 'Become a Vendor' button on the [DigitalOcean Marketplace](https://marketplace.digitalocean.com/vendors) page: fill in the form.
Then you'll be redirected to [this](https://marketplace.digitalocean.com/vendors/getting-started-as-a-digitalocean-marketplace-vendor
) page and receive a follow up email.

Vendors can list **1-Click Apps** that run on DigitalOcean Droplets.

Read that into page to see how to promote the 1-Click Apps, and follow
the steps in the [technical documentation](https://github.com/digitalocean/marketplace-partners).

Note, creating a listing is not automatically allowed:

> Once we've reviewed and approved your application to become a Marketplace Vendor, you'll get a link to a short form. That form is where you will tell us about your app – where the bits can be found, and the benefits that it will deliver to DigitalOcean's community of 1 million+ developers. The Marketplace is searchable, by Google and through a built-in search function. So make sure that you're including keywords in your listing that will help the community when they're searching for a solution to their problem.

## Step 2: Create and configure

Create and configure a build Droplet manually first to make sure your configuration works.

You can create a build Droplet with any method, like the **control panel**, the **API**, or **command-line tools** like `doctl`.

### Create a droplet

Use DigitalOcean control panel to create a Droplet based on the
[one of the supported OS-es](https://github.com/digitalocean/marketplace-partners#supported-operating-systems)
for Marketplace images.
This image uses 1 CPU and 1GB RAM with 25GB SSD drive, this is a Standard US $5/mo image.
For production purposes, 2 CPUs and 4GB RAM might be required.

Select your preferred region, don't forget to add SSH keys.
We use the smallest suitable disk size here to run Shiny/Shinyproxy, because
DigitalOcean does not support decreasing the size of a Droplet's disk as it poses
data integrity issues. Building the image using the smallest disk size lets the
users choose from the widest variety of Droplet plans.

We do not enable unnecessary DigitalOcean features on your build Droplet, e.g.
monitoring, IPv6, or private networking. Retaining more of the distribution's standard configuration means less cleanup before creating the final image.

### Install required software packages

The following software packages are necessary for the initial configuration of new Droplets and to ensure connectivity:

- `cloud-init` 0.76 or higher (0.79 or higher recommended)
- `openssh-server` (SFTP-enabled configuration recommended)

All of these packages are provided by default in the default DigitalOcean base images.

### Optional in our case: running commands on first boot or first login

Some setup (like setting database passwords or configuration that needs the Droplet's assigned IP address) will need to be run for each new Droplet created from your image.
Read [here](https://github.com/digitalocean/marketplace-partners/blob/master/getting-started.md#running-commands-on-first-boot) how set up scripts to run on first boot.

Some of your image setup may require information that you can't get automatically, like the domain name to use for a service. You may also need to run interactive third-party scripts, like LetsEncrypt's Certbot. Read [this](https://github.com/digitalocean/marketplace-partners/blob/master/getting-started.md#running-commands-on-first-login) section about how to run a script on the user's first login.

### Install application

Using Ubuntu 20.04 (LTS)

Software included:

- OpenJDK 11.0.8 (GPL 2 with the Classpath Exception)
- Docker CE 19.03.8 (Apache 2)
- Docker Compose 1.25.0 (Apache 2)
- ShinyProxy 2.4.0 (Apache 2)
- Nginx 1.18.0 (2-clause BSD)

#### Install Java

Log into your droplet with
`ssh -i ~/.ssh/YOUR_SSH_KEY root@YOUR_IP_ADDRESS`,
use your SSH key and IP address.

```bash
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install default-jre
sudo apt-get install default-jdk
```

`java -version` should return something like:

```bash
openjdk version "11.0.8" 2020-07-14
OpenJDK Runtime Environment (build 11.0.8+10-post-Ubuntu-0ubuntu120.04)
OpenJDK 64-Bit Server VM (build 11.0.8+10-post-Ubuntu-0ubuntu120.04, mixed mode, sharing)
```

#### Install Docker CE and Docker Compose

```bash
sudo apt-get install docker
sudo apt-get install docker-compose
```

Check to see if Docker is running `sudo service docker status`.
`docker --version` and `docker-compose --version` will return version in use.

ShinyProxy needs to connect to the docker daemon to spin up the containers for the apps.
By default ShinyProxy will do so on port 2375 of the docker host.
In order to allow for connections on port 2375, the startup options need to be edited
following the ShinyProxy [guide](https://www.shinyproxy.io/getting-started/#docker-startup-options).

On an Ubuntu 16.04 LTS or higher that uses systemd,
one can create a file `/etc/systemd/system/docker.service.d/override.conf`:

```bash
mkdir /etc/systemd/system/docker.service.d
touch /etc/systemd/system/docker.service.d/override.conf
```

Add the following content (`vim /etc/systemd/system/docker.service.d/override.conf`):

```bash
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd -H unix:// -D -H tcp://127.0.0.1:2375
```

Reload the system daemon and restart docker:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
```

The `sudo systemctl enable docker` enables Docker service start when the system boots.

#### Install ShinyProxy

```bash
sudo wget https://www.shinyproxy.io/downloads/shinyproxy_2.4.0_amd64.deb
sudo apt install ./shinyproxy_2.4.0_amd64.deb
sudo rm shinyproxy_2.4.0_amd64.deb
```

Pull demo Docker images:

```bash
sudo docker pull analythium/shinyproxy-demo:latest
sudo docker pull registry.gitlab.com/analythium/shinyproxy-hello/hello:latest
```

Add favicon and create `application.yml`

```bash
cd /etc/shinyproxy
sudo wget https://hub.analythium.io/assets/favicon.ico
sudo touch application.yml
```

Copy these configs using `vim /etc/shinyproxy/application.yml`:

```vim
proxy:
  title: Open Analytics Shiny Proxy by Analythium
  logo-url: https://hub.analythium.io/assets/logo/logo.png
  landing-page: /
  favicon-path: favicon.ico
  heartbeat-rate: 10000
  heartbeat-timeout: 600000
  port: 8080
  authentication: simple
  admin-groups: admins
  # Example: 'simple' authentication configuration
  users:
  - name: admin
    password: password
    groups: admins
  - name: user
    password: password
    groups: users
  # Docker configuration
  docker:
    cert-path: /home/none
    url: http://localhost:2375
    port-range-start: 20000
  specs:
  - id: 01_hello
    display-name: Hello Shiny App
    description: A simple reactive histogram
    container-cmd: ["R", "-e", "shiny::runApp('/root/app')"]
    container-image: registry.gitlab.com/analythium/shinyproxy-hello/hello:latest
    logo-url: https://github.com/analythium/shinyproxy-1-click/raw/master/digitalocean/images/app-hist.png
    access-groups: [admins, users]
  - id: 02_hello
    display-name: Demo Shiny App
    description: App with sliders and large file upload
    container-cmd: ["R", "-e", "shiny::runApp('/root/app')"]
    container-image: analythium/shinyproxy-demo:latest
    logo-url: https://github.com/analythium/shinyproxy-1-click/raw/master/digitalocean/images/app-dots.png
    access-groups: [admins]

logging:
  file:
    shinyproxy.log

spring:
  servlet:
    multipart:
      max-file-size: 200MB
      max-request-size: 200MB
```

Edit `/etc/shinyproxy/application.yml` as required (file size limits, apps, `heartbeat-timeout`),
then restart ShinyProxy to take effect using `sudo service shinyproxy restart`.

Besides adding apps and permission, edits were made to increase file size limit
and the default `heartbeat-timeout: 60000` (1 minute in milliseconds) to `600000` (10 mins), etc.
Now `cd ~` back to the home (`/root`) folder to continue.

### Removing port 8080 and using port 80

Install nginx:

```bash
sudo apt-get install nginx
```

Edit the config file:

```bash
sudo vim /etc/nginx/sites-enabled/default
```

Find the `location / {` line and add the following:

```bash
location / {
    proxy_pass          http://127.0.0.1:8080/;

    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 600s;

    proxy_redirect    off;
    proxy_set_header  Host             $http_host;
    proxy_set_header  X-Real-IP        $remote_addr;
    proxy_set_header  X-Forwarded-For  $proxy_add_x_forwarded_for;
    proxy_set_header  X-Forwarded-Protocol $scheme;
}
```

Add `client_max_body_size 200M;` to the `server {` block if handling large files is needed.

Restart nginx with `sudo service nginx restart` and you can access the site at `http://YOUR_IP/`

`nginx -v` will print out Nginx version.

### Add a message of the day

Add a message of the day (MOTD), which is text displayed when a user logs into their Droplet.
The MOTD introduces the image's features and points users to its documentation.

```bash
sudo touch /etc/update-motd.d/99-image-readme
vim /etc/update-motd.d/99-image-readme
```

```vim
#!/bin/sh
export TERM=xterm-256color
cat <<EOF
********************************************************************************

Welcome to Analythium's 1-Click ShinyProxy Droplet.
To keep this Droplet secure, the UFW firewall is enabled.
Only these ports are open: 22 (SSH), 80 (HTTP).

   * help and more information https://hub.analythium.io/
   * ShinyProxy documentation  https://www.shinyproxy.io/

********************************************************************************
To delete this message of the day: rm -rf $(readlink -f ${0})
EOF
```

Make it executable:

```bash
sudo chmod +x /etc/update-motd.d/99-image-readme
```

### Install and configure ufw

UFW is an Uncomplicated Firewall.
We enables the UFW firewall to allow only SSH, HTTP and HTTPS.
See a detailed tutorial [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-20-04).

```bash
sudo apt install ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow ssh
sudo ufw allow http
```

Finally, enable these rules by running
`sudo ufw enable`. This also disables the previously used 8080 port.
Check `ufw status` to see:

```bash
Status: active

To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
22/tcp (v6)                ALLOW       Anywhere (v6)
80/tcp (v6)                ALLOW       Anywhere (v6)
```

## Step 3: Clean up and validate

Clean up and validate the build Droplet with the [provided scripts](https://github.com/digitalocean/marketplace-partners), `cleanup.sh` and `img_check.sh`.
The scripts will check for and fix potential security concerns and verify that the image will be compatible with Marketplace, see
[here](https://github.com/digitalocean/marketplace-partners/blob/master/getting-started.md).

```bash
wget https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/cleanup.sh
wget https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/img_check.sh

bash cleanup.sh
bash img_check.sh


truncate -s 0 /var/log/*log
bash img_check.sh
rm *.sh
history -c
shutdown -h now
```

To clear up log files, use `truncate -s 0 /var/log/*log`. Clear bash history: `history -c`.

Finally, clean up these script files as `rm *.sh`, `truncate -s 0 /var/log/*log` and power down (`shutdown -h now`).

## Step 4: Take a snapshot

Take a [snapshot](https://www.digitalocean.com/docs/images/snapshots/) of the build Droplet after you power it down (`shutdown -h now`), then test the resulting image.
While there are several ways to create an image, we recommend snapshots as the most simple and consistent option.

Test the snapshot by creating a Droplet based on the image.
Visiting the IP address should display the ShinyProxy login page
with username/password (see yml file for values).
Logging in via SSH should reveal the MOTD message.

## Step 5: Submit your final image

Submit your final image to the Marketplace team for review.

## Additional setup

Secure the ShinyProxy server following [this](secure.md) tutorial.

[Updating](update.md) ShinyProxy configuration (i.e. changing defaults and adding docker images).

Add webhook to ShinyProxy server for CI/CD following [this](webhook.md) tutorial.
