#!/bin/bash

#####################################################
#                                                   #
#  Description : Install Nginx from APT             #
#  Author      : Unixx.io                           #
#  E-mail      : github@unixx.io                    #
#  GitHub      : https://www.github.com/unixxio     #
#  Last Update : November 22, 2021                  #
#                                                   #
#####################################################
clear

# Variables
distro="$(lsb_release -sd | awk '{print tolower ($1)}')"
release="$(lsb_release -sc)"
version="$(lsb_release -sr)"
kernel="$(uname -r)"
uptime="$(uptime -p | cut -d " " -f2-)"

packages="lsof wget curl openssl gnupg2 ca-certificates lsb-release debian-archive-keyring"

# Check if script is run as root
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root"
   exit 1
fi

# Show the current distribution and version
echo -e "\nDistribution : ${distro}"
echo -e "Release      : ${release}"
echo -e "Version      : ${version}"
echo -e "Kernel       : ${kernel}"
echo -e "Uptime       : ${uptime}"

# Check if a webserver (Nginx/Apache) is already running on port 80
if [[ $(lsof -i TCP:80) ]]; then
    echo -e "\n[ Error ] A webserver is already running on port 80.\n"
    exit 1
fi

# Script feedback
echo -e "\nInstalling required packages and NGINX. Please wait...\n"

# Add APT repository for latest release
tee /etc/apt/sources.list.d/nginx.list <<EOF > /dev/null 2>&1
deb [arch=amd64] https://nginx.org/packages/mainline/${distro}/ ${release} nginx
deb-src https://nginx.org/packages/mainline/${distro}/ ${release} nginx
EOF

# Add GPG key to OS
wget -O /etc/apt/trusted.gpg.d/nginx.asc https://nginx.org/keys/nginx_signing.key > /dev/null 2>&1

# Update packages
apt-get update > /dev/null 2>&1 && apt-get upgrade -y > /dev/null 2>&1

# Install required packages
apt-get install ${packages} -y > /dev/null 2>&1

# Install nginx
apt-get install nginx -y > /dev/null 2>&1

# Fetch DH param bit size
echo -e "Please choose Diffie-Hellman (DH) parameters length."
echo -e "Recommended length is 4096 bits (option 3).\n"
echo -e "Generating DH parameters can take a long time depending on the hardware."
echo -e "A bit size of 4096 can take up to 10 minutes or even longer.\n"

PS="$(echo -e "\nOption : ")"
PS3=${PS}
options=("1024" "2048" "4096" "8192" "Quit")
select dhparam in "${options[@]}"
do
    case ${dhparam} in
        "1024")
            break
            ;;
        "2048")
            break
            ;;
        "4096")
            break
            ;;
        "8192")
            break
            ;;
        "Quit")
            echo -e "\nYou choose to quit. Script will abort.\n"
            exit 0
            ;;
        *) echo -e "\n[ ERROR ] Invalid option $REPLY. Please choose again." ;;
    esac
done

# Generate DH param
echo -e "\nGenerating Diffie-Hellman (DH) parameters (${dhparam}). Please wait...\n"
openssl dhparam -out /etc/ssl/private/dhparam.pem ${dhparam} > /dev/null 2>&1

# Generate a selfsigned certificate
echo ""
openssl req -new -newkey rsa:4096 -days 3650 -nodes -x509 -keyout selfsigned.tmp.key -out selfsigned.tmp.crt
cat selfsigned.tmp.key selfsigned.tmp.crt > /etc/ssl/private/selfsigned.pem
rm selfsigned.tmp*

# Remove old init
rm /etc/init.d/nginx > /dev/null 2>&1

# Remove folders
rm -rf /etc/nginx/sites-available > /dev/null 2>&1
rm -rf /etc/nginx/sites-enabled > /dev/null 2>&1
rm -rf /etc/nginx/conf.d > /dev/null 2>&1

# Create folder
mkdir -p /etc/nginx/vhosts

# Remove old nginx config
rm /etc/nginx/nginx.conf

# Generate new nginx.conf
tee /etc/nginx/nginx.conf <<'EOF' > /dev/null 2>&1
user www-data;
pid /run/nginx.pid;
worker_processes auto;
include /etc/nginx/modules-enabled/*.conf;

events {
  worker_connections 1024;
  multi_accept on;
  use epoll;
}

http {
  include /etc/nginx/mime.types;
  default_type text/html;
  charset UTF-8;

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  server_tokens off;
  server_names_hash_bucket_size 128;

  keepalive_timeout 20s;
  client_header_timeout 20s;
  client_body_timeout 20s;
  send_timeout 20s;
  reset_timedout_connection on;
  client_max_body_size 64m;
  map_hash_bucket_size 64;

  gzip on;
  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 4;
  gzip_min_length 256;
  gzip_types text/css text/javascript text/xml text/plain text/x-component application/javascript application/x-javascript application/json application/xml application/rss+xml font/truetype font/opentype application/vnd.ms-fontobject image/svg+xml;
  gzip_disable "msie6";

  ssl_protocols TLSv1.2 TLSv1.3;
  ssl_ciphers "ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305";
  ssl_prefer_server_ciphers off;
  ssl_session_cache shared:SSL:50m;
  ssl_session_tickets off;
  ssl_session_timeout 1d;
  ssl_dhparam /etc/ssl/private/dhparam.pem;
  ssl_stapling on;
  ssl_stapling_verify on;
  resolver 1.1.1.1 8.8.8.8 [2606:4700:4700::1111] [2001:4860:4860::8888];

  access_log /var/log/nginx/access.log combined;
  error_log /var/log/nginx/error.log;

  map $http_x_forwarded_proto $fastcgi_https {
    default $https;
    https on;
  }

  map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
  }
  index index.php index.html;

  include vhosts/*.conf;
}
EOF

# Generate default vhost
tee /etc/nginx/vhosts/default.conf <<'EOF' > /dev/null 2>&1
server {
  listen [::]:80 default_server ipv6only=off;
  listen [::]:443 default_server ipv6only=off ssl http2;

  server_name _;

  ssl_certificate /etc/ssl/private/selfsigned.pem;
  ssl_certificate_key /etc/ssl/private/selfsigned.pem;

  access_log /var/log/nginx/default.access.log combined;
  error_log /var/log/nginx/default.error.log;

  root /srv/www/;

  location / {
    try_files $uri $uri/ /index.php?$args;
  }
}
EOF

# Rename default nginx index.html
mv /var/www/html/index.nginx-debian.html /var/www/html/index.html > /dev/null 2>&1

# Start nginx
systemctl daemon-reload
systemctl start nginx

echo -e "\nNGINX is now installed and running. Enjoy! ;-)\n"

# End script
exit 0
