#!/bin/bash

set -e

# based on https://github.com/TryGhost/digitalocean-1-click/blob/main/files/opt/digitalocean/boot_strap.sh

export TERM=xterm-256color

myip=$(hostname -I | awk '{print$1}')

echo "$(tput setaf 2)Welcome to your ShinyProxy server!$(tput sgr0)"
echo
echo "$(tput setaf 2)Would you like to set up HTTPS with Let's Encrypt now (Y/N)?$(tput sgr0)"

read answer

if [ "$answer" != "${answer#[Yy]}" ]; then
    echo
    echo "This setup will prompt you to to provide the following info:"
    echo "1. Your domain"
    echo "- Add an A Record -> $(tput setaf 6)${myip}$(tput sgr0) & ensure the DNS has fully propagated"
    echo "- This can be a comma separated list of domain names:"
    echo "  e.g. $(tput setaf 6)example.com,www.example.com$(tput sgr0)"
    echo "2. Your email address (only used for important account notifications)"
    echo
    echo "$(tput setaf 2)Press enter when you're ready to get started!$(tput sgr0)"

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

    echo -e "\nserver:\n  forward-headers-strategy: native" >> /etc/shinyproxy/application.yml
    systemctl restart shinyproxy

    echo
    echo "You are all set!"
    echo
    echo "Verify auto-renewal with $(tput setaf 6)certbot renew --dry-run$(tput sgr0)"
    echo

else

    echo "When you are ready:"
    echo
    echo "1. Add an A Record -> $(tput setaf 6)${myip}$(tput sgr0) & ensure the DNS has fully propagated"
    echo "2. Run $(tput setaf 6)certbot --nginx -d yourdomain.com$(tput sgr0) and follow the prompts"
    echo "3. Restart Nginx: $(tput setaf 6)systemctl restart nginx$(tput sgr0)"
    echo "4. Set $(tput setaf 6)forward-headers-strategy: native$(tput sgr0) in /etc/shinyproxy/application.yml"
    echo

    echo -e "\n# server:\n#   forward-headers-strategy: native" >> /etc/shinyproxy/application.yml

fi

# remove bootstrap line
cp -f /etc/skel/.bashrc /root/.bashrc

# set message fo the day
cp /opt/shinyproxy/99-one-click /etc/update-motd.d/99-one-click
chmod 0755 /etc/update-motd.d/99-one-click
