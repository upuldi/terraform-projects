#!/bin/bash
set -e
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "my public server 1" > /var/www/html/index.html
