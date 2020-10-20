# Adding webhook to DigitalOcean 1-Click app for ShinyProxy

> This document guides you through TLS setup for ShinyProxy 1-click app

[![DO button](https://raw.githubusercontent.com/analythium/shinyproxy-1-click/master/digitalocean/images/do-btn-blue.svg)](https://marketplace.digitalocean.com/apps/shinyproxy)

## Open port for webhook

UFW is an Uncomplicated Firewall.
We enables the UFW firewall to allow only SSH, HTTP and HTTPS.
See a detailed tutorial [here](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-with-ufw-on-ubuntu-20-04).

```bash
sudo apt install ufw

#sudo ufw default deny incoming
#sudo ufw default allow outgoing

#sudo ufw allow ssh
#sudo ufw allow http
#sudo ufw allow https
sudo ufw allow 9000
```

Finally, enable these rules by running `sudo ufw enable`. 
Check `ufw status`.

## Install webhook

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
We need to restart the webhook daemon regularly
because it is not updating when the TLS certificate is renewed.

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
