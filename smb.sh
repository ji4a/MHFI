#!/bin/bash

# INSTALL SMB AND CREATE SHARE FOLDER

dnf install -y samba samba-client

mkdir /SERVER
chmod -R 777 /SERVER

echo "[SERVER]
   path = /SERVER
   writable = yes
   guest ok = no
   create mask = 0777
   directory mask = 0777
   valid users = @MHBT_GROUP" >> /etc/samba/smb.conf

systemctl restart smb

systemctl enable smb
systemctl start smb

firewall-cmd --permanent --add-service=samba
firewall-cmd --reload

echo "File server setup completed. SERVER folder is shared via SMB."


# ADD USER and give SMB ACCESS
USERNAME="roy"
PASSWORD="Money22"

useradd $USERNAME

echo -e "$PASSWORD\n$PASSWORD" | passwd $USERNAME

(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a $USERNAME

chown -R $USERNAME:$USERNAME /SERVER
chmod -R 755 /SERVER

echo "User $USERNAME created and set up for sharing the folder."


# CREATE THE MHBT_GROUP AND SET PERMISSIONS FOR THE SHARED FOLDER
groupadd MHBT_GROUP

chown :MHBT_GROUP /SERVER
chmod g+rw /SERVER

# ADD USERS TO GROUP
usermod -aG MHBT_GROUP admin
usermod -aG MHBT_GROUP roy

echo "GROUP created and users added to the group with read and write permissions on /SERVER folder."

sudo systemctl restart smb


# DISBALE SEL LINUX
echo "Disabling SELinux..."
cp /etc/selinux/config /etc/selinux/config.bak

# Change SELINUX setting to disabled
sed -i 's/^SELINUX=.*/SELINUX=disabled/' /etc/selinux/config


# REBOOT SYSTEM
COUNTDOWN=3

echo "Rebooting in $COUNTDOWN seconds..."
for ((i = COUNTDOWN; i > 0; i--)); do
    echo "$i..."
    sleep 1
done

echo "Rebooting now!"
sudo reboot
