#!/bin/bash

# Function to validate input
validate() {
    if [[ -n $1 ]]; then
        return 0
    else
        echo "Please enter a value."
        return 1
    fi
}

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

# Prompt user for database name
while true; do
    read -p "Enter MySQL database name: " database_name

    if validate "$database_name"; then
        break
    fi
done

# Prompt user for database host
while true; do 
    read -p "Enter MySQL host (e.g., localhost or if it is Docker, please provide container IP): " host

    if validate "$host"; then
        break
    fi
done

# Generate backup file name with date and time
backup_file="${database_name}_$(date +'%Y-%m-%d_%H-%M-%S').sql.gz"

# Perform database backup and capture the exit status
{ mysqldump -u "${mysql_user}" -p"${mysql_password}" --single-transaction -h"${host}" "${database_name}" | gzip > "${backup_file}"; } 2>&1
exit_status=${PIPESTATUS[0]}

# Check the exit status
if [[ $exit_status -eq 0 ]]; then
    echo "Database backup completed. Backup file: ${backup_file}"
else
    echo "Database backup failed with exit status ${exit_status}. Please check your MySQL credentials and try again."
fi
