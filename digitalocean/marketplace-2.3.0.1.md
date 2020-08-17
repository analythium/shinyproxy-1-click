# DigitalOcean Marketplace submission

> ShinyProxy 2.3.0.1 - in development and not yet published

[![](https://raw.githubusercontent.com/analythium/shinyproxy-1-click/master/digitalocean/images/do-btn-blue.svg)](https://marketplace.digitalocean.com/apps/shinyproxy)

OS version: Ubuntu 18.04

Category: Data Science

Minimum resource: 1 CPU, 1G RAM, 25G SSD

## Software Included

- OpenJDK 11.0.7 (GPL 2 with the Classpath Exception)
- Docker CE 19.03.6 (Apache 2)
- Docker Compose 1.17.1 (Apache 2)
- ShinyProxy 2.3.0 (Apache 2)
- Nginx 1.14.0 (2-clause BSD)
- Certbot 0.31.0 (Apache 2)
- Webhook 2.7.0 (MIT)

## Application summary

ShinyProxy is an open source platform to deploy R Shiny applications at scale in companies and
larger organizations. Shiny applications are interactive web applications for bringing data
science to end users.

ShinyProxy builds on enterprise Java and Docker technology to meet corporate needs in deploying
Shiny applications, such as authentication, authorization (LDAP, ActiveDirectory,
Social login, etc.) and secure traffic, allocating resources (CPU, memory limits) per
Shiny application, usage statistics and administrator views for monitoring,
API for integrating of Shiny apps in larger applications.

The 1-Click option makes it easier than ever to deploy ShinyProxy on DigitalOcean droplets
in fully-tested app environments.

## Application Description

Deploy interactive R Shiny applications at scale with ease using the 1-Click ShinyProxy app.
ShinyProxy builds on enterprise Java and Docker technology to provide authentication,
authorization, resource allocation, and monitoring.

## Getting started instructions

### Log in using ShinyProxy UI

Once your new droplet with the ShinyProxy 1-Click app is up and running, you can visit your
droplet's IP address. Use `admin`/`password` or `user`/`password` as user name and password
to log into your ShinyProxy instance. You'll see two demo
[R](https://www.r-project.org/) [Shiny](https://shiny.rstudio.com/) applications.

### Log in through SSH

Use your SSH key you set up with your droplet to log in. Edit `/etc/shinyproxy/application.yml`
to [configure](https://shinyproxy.io/configuration/) your instance. Pay special attention
to authentication: it is set to `simple`. You should change user names and passwords,
possibly the authentication type.

Pull Docker images and add those to the configuration file to
[deploy your Shiny apps](https://shinyproxy.io/deploying-apps/).

Then restart ShinyProxy to take effect using `sudo service shinyproxy restart`.

### Advanced configuration

Follow the [1-Click App documentation](https://github.com/analythium/shinyproxy-1-click/blob/master/digitalocean/secure.md)
to set up SSL certificate to serve the Shiny apps over HTTPS.

Continuous integration and continuous delivery (CI/CD) can be added via webhooks.
A daemon process listens on port 9000 for GET and POST requests.
The [1-Click App documentation](https://github.com/analythium/shinyproxy-1-click/blob/master/digitalocean/secure.md) explains
how to set up CI/CD with GitLab pipelines and container registry,
or with a combination of GitHub and Docker Hub (public or private repositories).
The hooks can be run for all or individual images.

The following curl command pulls all Docker images:
`curl -i --header "X-Gitlab-Token: secret_token_1234" http://YOUR_IP:9000/hooks/pull-all-gitlab`

Change webhook rules in `/var/www/webhooks/hooks.json`, or delete the firewall rule
for port 9000 if webhooks are not needed using `ufw delete allow 9000`.

Docker image updates can be performed using cron jobs. Uncomment and edit
some predefined jobs using `crontab -e`.

## Support

https://github.com/analythium/shinyproxy-1-click/issues

## Additional links

Analythium Hub: https://hub.analythium.io/docs/ Detailed 1-Click App Documentation

ShinyProxy website: https://shinyproxy.io/ ShinyProxy configuration

ShinyProxy forum: https://support.openanalytics.eu/ Q&A website under the ShinyProxy category
