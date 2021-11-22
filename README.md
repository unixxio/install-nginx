# Install NGINX

This installer should work on any Debian based OS. This also includes Ubuntu. If it detects a webserver (Apache/NGINX) running on port 80, it will abort installation.

**Install CURL first**
```
apt-get install curl -y
```

### Run the installer with the following command
```
bash <( curl -sSL https://raw.githubusercontent.com/unixxio/install-nginx/main/install-nginx.sh )
```

**Requirements**
* Execute as root

**What does it do**
* Install the latest NGINX version from APT (official repository)
* Generate Diffie-Hellman (DH) parameters (1024, 2048, 4096 or 8192 bits)
* Support TLSv1.2 and TLSv1.3
* Enable OCSP

**Locations**
* nginx.conf: /etc/nginx/nginx.conf
* vhosts: /etc/nginx/vhosts/
* default webroot: /srv/www/
* dhparam.pem: /etc/ssl/private/dhparam.pem

**NGINX Commands**

NGINX status
```
systemctl status nginx
```
Stop NGINX
```
systemctl stop nginx
```
Start NGINX
```
systemctl start nginx
```
Reload NGINX
```
systemctl reload nginx
```
Check configuration on syntax errors
```
nginx -t
```
Check NGINX version
```
nginx -V
```

**Tested on**
* Debian 10 Buster
* Debian 11 Bullseye

## Support
Feel free to [buy me a beer](https://paypal.me/sonnymeijer)! ;-)

## DISCLAIMER
Use at your own risk and always make sure you have backups!
