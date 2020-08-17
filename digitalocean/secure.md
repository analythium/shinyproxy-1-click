# Securing DigitalOcean 1-Click app for ShinyProxy

> This document guides you through TLS setup for ShinyProxy 1-click app

[![](https://raw.githubusercontent.com/analythium/shinyproxy-1-click/master/digitalocean/images/do-btn-blue.svg)](https://marketplace.digitalocean.com/apps/shinyproxy)

## Let's Encript certificate setup

Based on [this](https://www.digitalocean.com/community/tutorials/how-to-secure-nginx-with-let-s-encrypt-on-ubuntu-18-04)
post.

You need a fully registered domain name to use certificate, therefore
we only set up required software, but leave it up to the user to finish
setting up security.

We use `example.com` imaginary domain where you have to substitute you domain name.
Both of the following DNS records set up for your server:

- an A record with `example.com` pointing to your server’s public IP address.
- an A record with `www.example.com` pointing to your server’s public IP address.

but in order for it to configure SSL for Nginx, we need to verify some of Nginx’s configuration.

#### Nginx and firewall configuration

In the `/etc/nginx/sites-available/default` file,
find the line `server_name _;` and change it to
`server_name example.com www.example.com;`.

Next, test to make sure that there are no syntax errors in any of your Nginx files by
`sudo nginx -t`.

If there aren't any problems, restart Nginx to enable your changes by
`sudo systemctl restart nginx`.

There is no need to firewall off port 80, instead pick forwarding when asked by cetbot (option 2).
See https://letsencrypt.org/docs/allow-port-80/ for explanation.

#### Obtaining an SSL Certificate

```bash
sudo certbot --nginx -d example.com -d www.example.com
```

What if using a subdomain? subdomain.example.com is same as www.
Be careful with capitalization: browsers might not be case sensitive but
nginx and certbot wants things nice and clean and matching DNS settings.

If this is your first time running certbot, you will be prompted to enter an
email address and agree to the terms of service. After doing so, certbot will
communicate with the Let’s Encrypt server, then run a challenge to verify that
you control the domain you’re requesting a certificate for.

#### Verifying Certbot Auto-Renewal

`sudo certbot renew --dry-run`

## Enabling HTTPS for webhook

Add `-secure` flag to watch over https. This requires also passing the certificate:
check name of certificate and private key in the dir `/etc/letsencrypt/live/example.com/`,
the add `-secure -cert /etc/letsencrypt/live/test.side-r.com/cert.pem -key /etc/letsencrypt/live/test.side-r.com/privkey.pem` to the `/etc/systemd/system/webhook.service` service file.
Use private key (`privkey.pem`) and `fullchain.pem` which is concatenation of the public key
(`cert.pem`) and the certificate chain (`chain.pem`).

Use `crontab -e` and uncomment the line `0 2 * * * systemctl restart webhook.service`:
we need to restart the webhook daemon regularly (daily in this case)
because it is not updating when the TLS certificate is renewed.

### Testing the webhook with curl

Test it in `-verbose` mode: change example.com to your domain.
Have to open up another port, here 9001, because 9000 is taken by the daemon:
`/var/www/webhooks/webhook -hooks /var/www/webhooks/hooks.json -hotreload -verbose -secure -cert /etc/letsencrypt/live/test.side-r.com/fullchain.pem -key /etc/letsencrypt/live/test.side-r.com/privkey.pem -port 9001 `

See more parameter settings here:
https://github.com/adnanh/webhook/blob/master/docs/Webhook-Parameters.md

Note: we are testing over port 9001, but the real webhook is listening on port 9000.

#### GitLab

We use `curl -i` to get the response headers: 200 is what we want. Make sure to use http
protocol (and not https) if SSL certificate is not set up and used.

```bash
curl -i --header "X-Gitlab-Token: secret_token_1234" https://YOUR_IP_OR_DOMAIN:9000/hooks/pull-all-gitlab
```

Using form data (url encoded, default header "Content-Type: application/x-www-form-urlencoded"):

```bash
curl -i --header "X-Gitlab-Token: secret_token_1234" \
  -X POST -d 'image_name=analythium/shinyproxy-demo:latest' \
  https://YOUR_IP_OR_DOMAIN:9000/hooks/pull-one-gitlab
```

Need to declare content-type header, payload is treated as form data by curl

```bash
curl -i --header "X-Gitlab-Token: secret_token_1234" \
  --header "Content-Type: application/json" \
  --request POST \
  --data '{"image_name":"analythium/shinyproxy-demo:latest"}' \
  https://YOUR_IP_OR_DOMAIN:9000/hooks/pull-one-gitlab
```

#### Docker Hub

This is how the simplified Docker Hub payload looks like: we can use it to get the
image name and the tag.

```json
{
  "push_data": {
    "pusher": "trustedbuilder",
    "tag": "latest"
  },
  "repository": {
    "name": "testhook",
    "namespace": "svendowideit",
    "owner": "svendowideit",
    "repo_name": "svendowideit/testhook",
    "repo_url": "https://registry.hub.docker.com/u/svendowideit/testhook/",
    "star_count": 0,
    "status": "Active"
  }
}
```

Set webhook url as https://YOUR_IP_OR_DOMAIN:9000/hooks/pull-one-dockerhub

