# ADD USER and give SMB ACCESS
USERNAME="sava"
PASSWORD="Money22"

useradd $USERNAME

echo -e "$PASSWORD\n$PASSWORD" | passwd $USERNAME

(echo "$PASSWORD"; echo "$PASSWORD") | smbpasswd -a $USERNAME

usermod -aG MHBT_GROUP $USERNAME

echo "User $USERNAME created and and added to the MHBT_GROUP."


