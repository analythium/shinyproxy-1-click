# DigitalOcean Marketplace submission

> ShinyProxy 2.3.0

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

## Application summary

ShinyProxy is an open source platform to deploy R Shiny applications at scale in companies and larger organizations. Shiny applications are interactive web applications for bringing data science to end users.

ShinyProxy builds on enterprise Java and Docker technology to meet corporate needs in deploying Shiny applications, such as authentication, authorization (LDAP, ActiveDirectory, Social login, etc) and secure traffic, allocating resources (CPU, memory limits) per Shiny application,
usage statistics and administrator views for monitoring, API for integrating of Shiny apps in larger applications.

The 1-Click option makes it easier than ever to deploy ShinyProxy on DigitalOcean droplets in fully-tested app environments.

## Application Description

Deploy interactive R Shiny applications at scale with ease using the 1-Click ShinyProxy app. ShinyProxy builds on enterprise Java and Docker technology to provide authentication, authorization, resource allocation and monitoring.

## Getting started instructions

### Log in using ShinyProxy UI

Once your new droplet with the ShinyProxy 1-Click app is up and running, you can visit your droplet's IP address. Use `admin`/`password` as user name and password to log into your ShinyProxy instance. You'll see two demo applications.

### Log in through SSH

Use your SSH key you set up with your droplet to log in. Edit `/etc/shinyproxy/application.yml` to [configure](<https://shinyproxy.io/configuration/>) your instance. Pay special attention to authentication: it is set to `simple`. You should change user names and passwords, possibly the authentication type.<br>

 Pull Docker images and add those to the configuration file to [deploy your Shiny apps](<https://shinyproxy.io/deploying-apps/>).<br>

 Then restart ShinyProxy to take effect using `sudo service shinyproxy restart`.

## Support

https://github.com/analythium/shinyproxy-1-click/issues

## Additional links

ShinyProxy forum: https://support.openanalytics.eu/ Q&A website under the ShinyProxy category
