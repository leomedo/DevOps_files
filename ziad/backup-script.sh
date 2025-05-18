#!/bin/bash

# Set variables
NAMESPACE="frappe-men"
BACKUP_DIR="/opt/frappe-backups"
DATE=$(date +%Y%m%d-%H%M%S)

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR
mkdir -p $BACKUP_DIR/db
mkdir -p $BACKUP_DIR/sites

# Get the database pod name
DB_POD=$(kubectl get pods -n $NAMESPACE -l app=frappe-db -o jsonpath="{.items[0].metadata.name}")

# Backup the database
echo "Backing up database..."
kubectl exec -n $NAMESPACE $DB_POD -- mysqldump -u root -p$(kubectl get secret -n $NAMESPACE frappe-secrets -o jsonpath="{.data.MYSQL_ROOT_PASSWORD}" | base64 --decode) --all-databases > $BACKUP_DIR/db/frappe-db-$DATE.sql

# Backup the sites directory
echo "Backing up sites directory..."
kubectl cp $NAMESPACE/$(kubectl get pods -n $NAMESPACE -l app=frappe-backend -o jsonpath="{.items[0].metadata.name}"):/home/frappe/frappe-bench/sites $BACKUP_DIR/sites/sites-$DATE

echo "Backup completed successfully."
echo "Database backup: $BACKUP_DIR/db/frappe-db-$DATE.sql"
echo "Sites backup: $BACKUP_DIR/sites/sites-$DATE"

# Set up cron job for daily backups
if [ ! -f /etc/cron.d/frappe-backup ]; then
  echo "Setting up daily backup cron job..."
  echo "0 2 * * * root $BACKUP_DIR/backup-script.sh > /var/log/frappe-backup.log 2>&1" > /etc/cron.d/frappe-backup
  chmod 644 /etc/cron.d/frappe-backup
fi
