#!/bin/bash

#Fail on error.
set -Eeuo pipefail

DB_NAME=postgres-cluster
PATRONI_API_ENDPOINT='https://127.0.0.1:8008/patroni'
STANZA=postgres-cluster
BACKUP_TYPE=diff
LOGFILE='/var/log/pgbackrest_backup.log'
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=ranul.techtest@gmail.com
SMTP_PASS=pcqjwckcxybeoket
MAIL_FROM=ranul.techtest@gmail.com
MAIL_TO=ranuldeepanayake@outlook.com
MAIL_SUBJECT="PostgreSQL Backup Status - ${DB_NAME} - ${BACKUP_TYPE}"

#Logging function.
log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

send_success_mail() {
 log "INFO: Sending success email notification..."

 mailx -s "$MAIL_SUBJECT" "$MAIL_TO" <<EOF
PostgreSQL Backup Completed Successfully

Database    : $DB_NAME
Backup Type : $BACKUP_TYPE
Timestamp   : $(date)

This is an automated message.
EOF
}

#Catch script errors (on ERR) and print the line number.
trap 'log "ERROR: Script failed at line $LINENO"; exit 1' ERR

log "INFO: Backup script started"

#Check if jq is installed
if ! command -v jq &> /dev/null; then
    log "ERROR: jq not installed"
    exit 1
fi

#Determine the node role.
NODE_ROLE=$(curl -ks "$PATRONI_API_ENDPOINT" | jq -r '.role')
log "Node role: $NODE_ROLE"

if [[ "$NODE_ROLE" == "primary" ]]; then
    log "INFO: This node is the leader. Starting pgBackRest backup..."
    
    #Run pgBackRest backup
    sudo -u postgres pgbackrest --stanza="$STANZA" --type="$BACKUP_TYPE" backup
    
    if [[ $? -eq 0 ]]; then
        log "INFO: Backup completed successfully."
        #send_success_mail
    else
        log "ERROR: Backup failed!"
        exit 1
    fi
else
    echo log "WARN: This node is not the leader. Skipping backup."
fi

log "INFO: Backup script ended"

#Root cron job.
#*/15 * * * * ~/scripts/backup-diff.sh >> /var/log/pgbackrest-diff-backup.log 2>&1



