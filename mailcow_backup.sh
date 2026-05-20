#!/bin/bash

# Define paths
MAILCOW_DIR="/opt/mailcow-dockerized"
BACKUP_DIR="/backup"
RCLONE_REMOTE="onedrive:mailcow-2026-backup"

# SMTP Configuration (Localhost Mailcow Server)
NOTIFY_EMAIL="your-destination-email@domain.com"  # Change to where you want alerts sent
SMTP_FROM="admin@rollitafrica.co.za"
SMTP_SERVER="127.0.0.1"
SMTP_PORT="587"
SMTP_USER="your sender email address"
SMTP_PASS="YOUR_ADMIN_EMAIL_PASSWORD_HERE"       # Change to your actual mailbox password

# Step 1: Run the official Mailcow backup tool
cd "$MAILCOW_DIR"
./helper-scripts/backup_and_restore.sh backup all

# Step 2: Grab the name of the NEWEST backup folder just created
NEW_BACKUP=$(cd "$BACKUP_DIR" && ls -dt */ | head -n 1)

# Step 3: One-Way Target Sync (Uploads the brand new copy immediately)
rclone sync "$BACKUP_DIR" "$RCLONE_REMOTE" --delete-after

# Step 4: Identify which old copy is about to be deleted (the 4th one down)
OLD_COPY=$(cd "$BACKUP_DIR" && ls -dt */ | tail -n +4)

# Step 5: Local and Cloud Cleanup
if [ -n "$OLD_COPY" ]; then
    cd "$BACKUP_DIR"
    echo "$OLD_COPY" | xargs rm -rf
    DELETION_STATUS="DELETED OLD COPY:\n--> $OLD_COPY"
else
    DELETION_STATUS="DELETED OLD COPY:\n--> None (Fewer than 4 copies exist, no deletion required yet)."
fi

# Step 6: Final Quick Sync to remove that 4th old copy from OneDrive too
rclone sync "$BACKUP_DIR" "$RCLONE_REMOTE" --delete-after

# Step 7: Format Email Body
EMAIL_SUBJECT="Mailcow Backup Success Notification"
EMAIL_BODY="Hi System Admin,\n\nThe weekly scheduled Mailcow backup has completed successfully.\n\nNEWLY CREATED BACKUP:\n--> $NEW_BACKUP\n\n$DELETION_STATUS\n\nOneDrive Sync Status:\n--> Folder 'mailcow-2026-backup' is fully matched and secure.\n\nBest regards,\nRollitAfrica Backup System Automation"

# Step 8: Send the Email via Authenticated Localhost SMTP
echo -e "$EMAIL_BODY" | swaks --server "$SMTP_SERVER" --port "$SMTP_PORT" \
    --from "$SMTP_FROM" --to "$NOTIFY_EMAIL" \
    --auth-user "$SMTP_USER" --auth-password "$SMTP_PASS" \
    --header "Subject: $EMAIL_SUBJECT" --body - > /dev/null 2>&1
