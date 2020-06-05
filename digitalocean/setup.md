# Setup DigitalOcean 1-Click app for ShinyProxy

https://marketplace.digitalocean.com/apps/shinyproxy

Using the DigitalOcean Marketplace, we can deliver a truly seamless experience for users,
creating the ability for developers to deploy fully-tested app environments with the click of a button.

## Step 1: Become a vendor on the DigitalOcean Marketplace

Click on 'Become a Vendor' button on the [DigitalOcean Marketplace](https://marketplace.digitalocean.com/vendors) page: fill in the form.
Then you'll be redirected to [this](- https://marketplace.digitalocean.com/vendors/getting-started-as-a-digitalocean-marketplace-vendor
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

Use DigitalOcean control panel to create a Droplet based on the Ubuntu 18.04 (TLS) image
(this is one of the supported operating systems for Marketplace images).
This image uses 1 CPU and 1GB RAM with 25GB SSD drive, this is a Standard US $5/mo image.
For production purposes, 2 CPUs and 4GB RAM might be required.

Select your preferred region, don't forget to add SSH keys.
We use the smallest suitable disk size here to run Shiny/Shinyproxy, because
DigitalOcean does not support decreasing the size of a Droplet's disk as it poses
data integrity issues. Building the image using the smallest disk size lets the
users choose from the widest variety of Droplet plans.

We do not enable unnecessary DigitalOcean features on your build Droplet, e.g.
monitoring, IPv6, or private networking. Retaining more of the distribution's standard configuration means less cleanup before you creating the final image.

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

Software included:

- OpenJDK 11.0.7 (GPL 2 with the Classpath Exception)
- Docker CE 19.03.6 (Apache 2)
- Docker Compose 1.17.1 (Apache 2)
- ShinyProxy 2.3.0 (Apache 2)
- Nginx 1.14.0 (2-clause BSD)
- Certbot 0.31.0 (Apache 2)
- Webhook 2.7.0 (MIT)

#### Install Java

Log into your droplet with
`ssh -i ~/.ssh/YOUR_SSH_KEY root@YOUR_IP_ADDRESS`,
use your SSH key and IP address.

```bash
sudo apt-get update
sudo apt-get install default-jre
sudo apt-get install default-jdk
```

`java -version` should return something like:

```bash
openjdk version "11.0.7" 2020-04-14
OpenJDK Runtime Environment (build 11.0.7+10-post-Ubuntu-2ubuntu218.04)
OpenJDK 64-Bit Server VM (build 11.0.7+10-post-Ubuntu-2ubuntu218.04, mixed mode, sharing)
```

#### Install Docker CE and Docker Compose

```bash
sudo apt-get install docker
sudo apt-get install docker-compose
```

Check to see if Docker is running `sudo service docker status`.

Edit system startup options to enable Docker automatically:

```bash
sudo vim /lib/systemd/system/docker.service
```

Replace:

```vim
ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
```

with:

```vim
ExecStart=/usr/bin/dockerd -H fd:// -D -H tcp://127.0.0.1:2375
```

save and exit using `:wq!`

Reload the system daemon and restart docker:

```bash
sudo systemctl daemon-reload
sudo systemctl restart docker
sudo systemctl enable docker
```

The `sudo systemctl enable docker` enables Docker service start when the system boots.

#### Install ShinyProxy

```bash
sudo wget https://www.shinyproxy.io/downloads/shinyproxy_2.3.0_amd64.deb
sudo apt install ./shinyproxy_2.3.0_amd64.deb
sudo rm shinyproxy_2.3.0_amd64.deb
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

### Secure Nginx with Let's Encrypt

Add repository for up to date Certbot version:

```bash
sudo add-apt-repository ppa:certbot/certbot
```

You’ll need to press ENTER to accept.

Install Certbot’s Nginx package with apt:

```bash
sudo apt install python-certbot-nginx
```

Certbot is now ready to use.

### Setting up webhook

We are going to use [webhook](https://github.com/adnanh/webhook).
The community maintained `sudo apt-get install webhook` gives a really outdated version.
Therefore we pick the latest (2.7.0) using pre-compiled binary for our
architecture (if in doubt, check `dpkg --print-architecture`):

```bash
sudo wget https://github.com/adnanh/webhook/releases/download/2.7.0/webhook-linux-amd64.tar.gz
tar -zxvf webhook-linux-amd64.tar.gz
```

Next we will follow [this](https://davidauthier.com/blog/2017/09/07/deploy-using-github-webhooks/) guide
and we move the binary and other files with settings in the `/var/www/webhooks` directory:

```bash
sudo mkdir /var/www/webhooks
sudo cp webhook-linux-amd64/webhook /var/www/webhooks/
rm -rf *
```

Make `hooks.json` to store the hook definitions:

```bash
sudo touch /var/www/webhooks/hooks.json
```

The following array of hook definitions goes inside (`vim /var/www/webhooks/hooks.json`):
```json
[
  {
    "id": "pull-all-gitlab",
    "execute-command": "webhook-pull-all-gitlab",
    "response-message": "Pulling all Docker images.",
    "response-headers":
    [
      {
        "name": "Access-Control-Allow-Origin",
        "value": "*"
      }
    ],
    "trigger-rule": {
      "match":
      {
        "type": "value",
        "value": "secret_token_1234",
        "parameter":
        {
          "source": "header",
          "name": "X-Gitlab-Token"
        }
      }
    }
  },
  {
    "id": "pull-one-gitlab",
    "execute-command": "webhook-pull-one-gitlab",
    "response-message": "Pulling Docker image.",
    "response-headers":
    [
      {
        "name": "Access-Control-Allow-Origin",
        "value": "*"
      }
    ],
    "pass-arguments-to-command": [
      {
        "source": "payload",
        "name": "image_name"
      }
    ],
    "trigger-rule": {
      "match":
      {
        "type": "value",
        "value": "secret_token_1234",
        "parameter":
        {
          "source": "header",
          "name": "X-Gitlab-Token"
        }
      }
    }
  },
  {
    "id": "pull-one-dockerhub",
    "execute-command": "webhook-pull-one-dockerhub",
    "response-message": "Pulling Docker image from Docker Hub.",
    "response-headers":
    [
      {
        "name": "Access-Control-Allow-Origin",
        "value": "*"
      }
    ],
    "pass-arguments-to-command": [
      {
        "source": "payload",
        "name": "repository.repo_name"
      },
      {
        "source": "payload",
        "name": "push_data.tag"
      }
    ]
  }
]
```

This array contains 3 hooks. The 1st and the second is
set up to work with GitLab CICD pipelines.
See corresponding `.gitlab-ci.yml` file [here](https://gitlab.com/analythium/shinyproxy-hello/-/blob/master/.gitlab-ci.yml).

These need a secret header (value `"secret_token_1234"`) 
that is used in the hook definition and in the webhook request. Change to some random
high entropy value.

The 1st hook definition calls the command `webhook-pull-all-gitlab` without arguments.
The command pulls the latest version of all the docker images that are on the server.
After that it cleans up the dangling images. So let's put this command into
the `/bin` folder and make it executable:

```bash
sudo touch /bin/webhook-pull-all-gitlab
chmod 755 /bin/webhook-pull-all-gitlab
```

This is the content that goes inside:

```bash
#! /bin/sh

#echo "\n--- Logging into GitLab registry ---\n"
#docker login -u $GITLAB_USER -p $GITLAB_TOKEN registry.gitlab.com

echo "\n--- Pulling all Docker images ---\n"
/usr/bin/docker images |grep -v REPOSITORY|awk '{print $1":"$2}'|xargs -L1 /usr/bin/docker pull

echo "\n--- Removing dangling images ---\n"
/usr/bin/docker system prune -f

echo "\n--- Done ---\n"
```

The section that is commented out (`docker login`)
is needed when you use private GitLab registry.
Export `GITLAB_USER` and `GITLAB_TOKEN` as
`export GITLAB_USER="GITLAB_USERNAME"` and `export GITLAB_TOKEN="DEPLOY_TOKEN"`.
See [here](https://docs.gitlab.com/ee/user/project/deploy_tokens/) how to set up
deploy tokens.

The second hook definition uses the command `webhook-pull-one-gitlab` which
pulls a single image based on the argument passed

```bash
sudo touch /bin/webhook-pull-one-gitlab
chmod 755 /bin/webhook-pull-one-gitlab
```

```bash
#! /bin/sh

#echo "\n--- Logging into GitLab registry ---\n"
#docker login -u $GITLAB_USER -p $GITLAB_TOKEN registry.gitlab.com

echo "\n--- Pulling Docker image $1 ---\n"
/usr/bin/docker pull $1

echo "\n--- Removing dangling images ---\n"
/usr/bin/docker system prune -f

echo "\n--- Done ---\n"
```

The 3rd hook definition is similar the previous hook in that it also pulls a single
docker image. But this one is written for the payload that Docker Hub's webhook
delivers (read more [here](https://docs.docker.com/docker-hub/webhooks/#example-webhook-payload)).
The image name and the tag are parsed separately, so the `webhook-pull-one-dockerhub`
takes these two arguments:

```bash
sudo touch /bin/webhook-pull-one-dockerhub
chmod 755 /bin/webhook-pull-one-dockerhub
```

```bash
#! /bin/sh

#echo "\n--- Logging into Docker registry ---\n"
#cat ~/my_password.txt | docker login --username DOCKER_USER --password-stdin

echo "\n--- Pulling Docker image $1:$2 ---\n"
/usr/bin/docker pull $1:$2

echo "\n--- Removing dangling images ---\n"
/usr/bin/docker system prune -f

echo "\n--- Done ---\n"
```

The commented section here again allows to
use `docker login` if pulling from private registry.
Using `STDIN` prevents the password from ending up in the shell’s history, or log-files.

Now create the `webhook.service` file with the daemon settings via `systemctl`:

```bash
sudo touch /etc/systemd/system/webhook.service
```

Put these into the service file (`vim /etc/systemd/system/webhook.service`):

```vim
[Unit]
Description=Webhooks

[Service]
ExecStart=/var/www/webhooks/webhook -hooks /var/www/webhooks/hooks.json -hotreload

[Install]
WantedBy=multi-user.target
```

The option `-hotreload` watches for changes in the `hook.json` file and reloads them upon change.

Run a few commands with `systemctl`:
`sudo systemctl enable webhook.service` to enable the newly created service,
`sudo systemctl start webhook.service` to start the service.

Now check the service status using `sudo service webhook status`. If all went well,
you should see something like:

```bash
● webhook.service - Webhooks
   Loaded: loaded (/etc/systemd/system/webhook.service; enabled; vendor preset: enabled)
   Active: active (running) since Fri 2020-06-05 07:31:31 UTC; 6s ago
 Main PID: 5228 (webhook)
    Tasks: 6 (limit: 1152)
   CGroup: /system.slice/webhook.service
           └─5228 /var/www/webhooks/webhook -hooks /var/www/webhooks/hooks.json -hotreload
```

### Setting cron job to update images

We add a couple of lines to cron. All commented out but there if needed.
We need to restart the webhook daemon restart regularly
because it is not updating when the certificate is renewed.

We have access to the cron utility: run `crontab -e`, 
pick an editor (nano) if you haven’t done so already and then add 
these lines to the bottom and save it:

```bash
# Restart webhook daemon at 2:00am every day
#0 2 * * * systemctl restart webhook.service

# Update all images at 3:00am every Sunday
#0 3 * * 0 webhook-pull-all-gitlab

# Update all images at 1:00am every day
#0 1 * * * webhook-pull-all-gitlab
```

Check `crontab -l`

See [this](https://www.digitalocean.com/community/tutorials/how-to-use-cron-to-automate-tasks-ubuntu-1804) guide for cron settings.

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
Only these ports are open: 22 (SSH), 80 (HTTP), 443 (HTTPS), 9000 (webhook).

   * help and more information https://hub.analythium.io/docs/
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
See a detailed tutorial [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-18-04).

```bash
sudo apt install ufw

sudo ufw default deny incoming
sudo ufw default allow outgoing

sudo ufw allow ssh
sudo ufw allow http
sudo ufw allow https
sudo ufw allow 9000
```

Finally, enable these rules by running
`sudo ufw enable`. This also disables the previously used 8080 port.
Check `ufw status`.

## Step 3: Clean up and validate

Clean up and validate the build Droplet with the [provided scripts](https://github.com/digitalocean/marketplace-partners), `cleanup.sh` and `img_check.sh`.
The scripts will check for and fix potential security concerns and verify that the image will be compatible with Marketplace, see
[here](https://github.com/digitalocean/marketplace-partners/blob/master/getting-started.md).

```bash
wget https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/cleanup.sh
wget https://raw.githubusercontent.com/digitalocean/marketplace-partners/master/scripts/img_check.sh
bash cleanup.sh
bash img_check.sh
```

To clear up log files, use `truncate -s 0 /var/log/*log`.

Finally, clean up these files as `rm *.sh`.

## Step 4: Take a snapshot

Take a [snapshot](https://www.digitalocean.com/docs/images/snapshots/) of the build Droplet after you power it down (`shutdown -h now`), then test the resulting image.
While there are several ways to create an image, we recommend snapshots as the most simple and consistent option.

Test the snapshot by creating a Droplet based on the image.
Visiting the IP address should display the ShinyProxy login page
with username/password (see yml file for values).
Logging in via SSH should reveal the MOTD message.

## Step 5: Submit your final image

Submit your final image to the Marketplace team for review.
