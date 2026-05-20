# mailcow-auto-backup
this is a mailcow auto backup script

install apt install swaks -y
den nano /root/mailcow_backup.sh

note i am using onedrive in this exsampel you need to install rclone and grant access to your one drive account first 

need to run this on a windows pc that has a browser 

rclone authorize "onedrive"

run this to start the setup for rclone as well

rclone config



to install it 
curl https://rclone.org/install.sh | bash

do not install the apt-get install rclone as this virsion in out of dated
