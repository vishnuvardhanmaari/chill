#!/bin/bash

# Function to validate Magento project path
validate_project_path() {
    if [[ -d $1 && -e "$1/nginx.conf.sample" ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate input
validate() {
    if [[ -n $1 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to validate file extension
validate_file_extension() {
    if [[ $1 == *.sql ]]; then
        return 0
    else
        echo "Invalid file format. Please provide a valid .sql file."
        return 1
    fi
}

# Create new database to import db
while true; do
    read -p "Enter New database name to import db: " database_name
    if validate "$database_name"; then
        break
    fi
done

# Prompt user for MySQL user
while true; do
    read -p "Enter MySQL user: " mysql_user
    if validate "$mysql_user"; then
        break
    fi
done

# Prompt user for MySQL password
while true; do
    read -s -p "Enter MySQL password: " mysql_password
    echo
    if validate "$mysql_password"; then
        break
    fi
done

# Prompt user for the path to the database dump file
while true; do
    echo # Add a newline
    read -p "Enter the file path for the database backup (.sql): " backup_file

    validate_file_extension "${backup_file}"
    if [[ $? -eq 0 ]]; then
        break
    fi

    echo "Please enter a valid file path with .sql extension."
done

# Prompt user for MySQL host
while true; do 
    read -p "Enter MySQL host (e.g., localhost or if it is Docker, please provide container IP): " host

    if validate "$host"; then
        break
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

# Import MySQL database
mysql -u $mysql_user -p$mysql_password -h $host -e "create database $database_name"
mysql -u $mysql_user -p$mysql_password -h $host $database_name  < $backup_file
# Navigate to Magento installation directory
cd "${project_path}" || exit
sed -i "s/'dbname' => '[^']*'/'dbname' => '$database_name'/g" app/etc/env.php

# Run Magento commands (e.g., clear cache, reindex)
if php bin/magento se:up && php bin/magento se:st:de -f && php bin/magento se:di:com && php bin/magento indexer:reindex && php bin/magento cache:flush; then
    echo "Database import and Magento commands completed successfully."
else
    echo "Error running Magento commands. Check the logs for more details."
    exit 1
fi

sudo chmod -R 777 var/ pub/ generated/
