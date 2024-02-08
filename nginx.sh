#!/bin/bash
echo "MAKE SURE NGINX IS RUNNING ON PORT 80 BEFORE RUNNING THE SCRIPT"
# Function to validate PHP version
validate_php_version() {
    if [[ $1 =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate Magento project path
validate_project_path() {
    if [[ -d $1 && -e "$1/nginx.conf.sample" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate domain
validate_domain() {
    if [[ -n $1 ]]; then
        return 0
    else
        return 1
    fi
}

# Prompt user for PHP version
while true; do
    read -p "Enter PHP version (e.g., 8.1): " php_version
    if validate_php_version "$php_version"; then
        break
    else
        echo "Invalid PHP version. Please enter a valid numeric version."
    fi
done

# Prompt user for domain
while true; do
    read -p "Enter domain (e.g., example.com): " domain
    if validate_domain "$domain"; then
        break
    else
        echo "Invalid domain. Please enter a valid domain."
    fi
done

# Prompt user for project path
while true; do
    read -p "Enter the absolute path of the Magento project: " project_path
    if validate_project_path "$project_path"; then
        break
    else
        echo "Invalid Magento project path. Make sure it is a valid directory containing Magento code."
    fi
done

# Rest of the script remains unchanged
config_file="/etc/nginx/sites-available/${domain}"
echo "upstream fastcgi_backend {
     server  unix:/run/php/php${php_version}-fpm.sock;
 }

server {
    listen 80;
    server_name ${domain};
    set \$MAGE_ROOT ${project_path};
    set \$MAGE_RUN_TYPE website;
    index index.html index.php;
    include ${project_path}/nginx.conf.sample;
    proxy_cookie_path / \"/; SameSite=None; HTTPOnly; Secure\";
}" | sudo tee "${config_file}" > /dev/null

sudo ln -s "${config_file}" "/etc/nginx/sites-enabled/"
sudo systemctl reload nginx

echo "Nginx configuration for ${domain} has been created and enabled."
