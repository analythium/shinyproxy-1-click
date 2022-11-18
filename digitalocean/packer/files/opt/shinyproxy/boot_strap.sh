#!/bin/bash

# Scripts in this directory will be executed by cloud-init on the first boot of droplets
# created from your image.  Things like generating passwords, configuration requiring IP address
# or other items that will be unique to each instance should be done in scripts here.

# based on https://github.com/TryGhost/digitalocean-1-click/blob/main/files/opt/digitalocean/boot_strap.sh

export TERM=xterm-256color

myip=$(hostname -I | awk '{print$1}')

echo
echo "Welcome to your ShinyProxy server!"
echo
echo "Would you like to set up HTTPS with Let's Encrypt now (Y/N)?"

read answer

if [ "$answer" != "${answer#[Yy]}" ]
then
    echo
    echo "This setup will prompt you to to provide the following info:"
    echo "1. Your domain"
    echo "- Add an A Record -> $(tput setaf 6)${myip}$(tput sgr0) & ensure the DNS has fully propagated"
    echo "- This can be a comma separated list of domain names:"
    echo "  e.g. $(tput setaf 6)example.com,www.example.com$(tput sgr0)"
    echo "2. Your email address (only used for important account notifications)"
    echo "$(tput setaf 2)Press enter when you're ready to get started!$(tput sgr0)"
    echo

    read wait

    echo "Your domain name(s): "

    read domain

    echo "Your email: "

    read email

    echo
    echo "Certbot is now setting up Let's Encrypt certificates and configuring Nginx ..."
    echo

    # See https://eff-certbot.readthedocs.io/en/stable/using.html#certbot-command-line-options
    # --nginx Use the Nginx plugin for authentication & installation
    # --non-interactive Run without ever asking for user input
    # --agree-tos Agree to the ACME server's Subscriber Agreement
    # -m $email Email address for important account notifications
    # -d $domain A comma separated list of domain names
    certbot --nginx --non-interactive --agree-tos -m $email -d $domain
    systemctl restart nginx

    echo ""
    echo "You are all set!"
    echo ""

else

    echo
    echo "When you are ready:"
    echo
    echo "1. Add an A Record -> $(tput setaf 6)${myip}$(tput sgr0) & ensure the DNS has fully propagated"
    echo "2. Run $(tput setaf 6)certbot --nginx -d yourdomain.com$(tput sgr0) and follow the prompts"
    echo "3. Restart Nginx: $(tput setaf 6)systemctl restart nginx$(tput sgr0)"
    echo

fi

cp -f /etc/skel/.bashrc /root/.bashrc

cp /opt/shinyproxy/99-one-click /etc/update-motd.d/99-one-click
chmod 0755 /etc/update-motd.d/99-one-click
