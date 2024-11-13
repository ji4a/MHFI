################################################################################################################################################
#### SPECIAL FOR ALMALINUX 8 #### --------------------------------------------------------------------------------------------------- ##_2024_##
################################################################################################################################################

#!/bin/bash

source tokens.sh

send_message() {
    local text="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$text"
}

IP=$(hostname -I | cut -d' ' -f1)
MESSAGE="VNC server installation started on $IP ....."
send_message "$MESSAGE"

################################################################################################################################################
#### STARTING NOWW -----------------------------------------------------------------------------------------------------------------------------
################################################################################################################################################

TOTAL_STEPS=3
COMPLETED_STEPS=0

send_progress_message() {
    local percentage="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=VNC Progress: $percentage%" >/dev/null
}

################################################################################################################################################
#### INSTALL SOME DEPENDENCIES:) #### -------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

# sudo dnf update -y
# sudo dnf upgrade -y

/usr/bin/crb enable 

yum -y install epel-release
yum -y install terminator
yum -y install expect
yum -y install curl
yum -y install wget
yum -y install git
yum -y install jq

sudo timedatectl set-timezone Europe/Paris

sudo dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/x86_64/
sudo rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc
sudo dnf install brave-browser -y

((COMPLETED_STEPS++))
send_progress_message "$((COMPLETED_STEPS * 100 / TOTAL_STEPS))"

################################################################################################################################################
#### CHANGE SSH PORT TO 4477 AND SET HOSTNAME #### ------------------------------------------------------------------------------------- #######
################################################################################################################################################

NEW_SSH_PORT=4477

cp /etc/ssh/sshd_config /etc/ssh/sshd_config_backup
sed -i "s/#Port 22/Port $NEW_SSH_PORT/g" /etc/ssh/sshd_config

firewall-cmd --zone=public --add-port=$NEW_SSH_PORT/tcp --permanent
firewall-cmd --reload

service firewalld restart

####### SET HOSTNAME #######
SERVER_IP=$(hostname -I | awk '{print $1}')
sudo hostnamectl set-hostname ${SERVER_IP}.myworld.com
sudo systemctl restart systemd-hostnamed

((COMPLETED_STEPS++))
send_progress_message "$((COMPLETED_STEPS * 100 / TOTAL_STEPS))"

################################################################################################################################################
#### INSTALL VNC SERVER #### ----------------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

sudo dnf groupinstall "server with GUI" -y
sudo dnf install tigervnc-server -y

mkdir -p ~/.vnc/

content=$(cat <<END
session=gnome
geometry=1280x800
localhost
alwaysshared
END
)

echo "$content" > ~/.vnc/config

# Configure the firewall to allow VNC
sudo firewall-cmd --add-service=vnc-server --permanent
sudo firewall-cmd --reload

# Create a new user 'admin' with a predefined password
sudo adduser admin
echo "admin:Money22" | sudo chpasswd  # Set the password for 'admin'

# Grant the 'admin' user passwordless sudo access for specific commands
echo "admin ALL=(ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/admin_no_password
sudo chmod 440 /etc/sudoers.d/admin_no_password
sudo visudo -c  # Check syntax of sudoers files

# Switch to the 'admin' user environment to configure VNC
sudo -i -u admin bash <<'EOF'

# Ensure .vnc directory exists
mkdir -p ~/.vnc

# Set the VNC password directly
echo "Money22" | vncpasswd -f > ~/.vnc/passwd
chmod 600 ~/.vnc/passwd

# Start the VNC server with specified geometry
vncserver :1 -geometry 1280x800

# Create a systemd service for the VNC server
cat <<SERVICE_EOF | sudo tee /etc/systemd/system/vncserver@:1.service >/dev/null
[Unit]
Description=VNC Server
After=network.target

[Service]
Type=forking
User=admin
ExecStart=/usr/bin/vncserver :1 -geometry 1280x800
ExecStop=/usr/bin/vncserver -kill :1

[Install]
WantedBy=multi-user.target
SERVICE_EOF

####### Enable VNC to start on reboot #######
sudo systemctl daemon-reload
sudo systemctl enable vncserver@:1.service

EOF


sudo systemctl daemon-reload
sudo systemctl enable --now vncserver@:1.service

################################################################################################################################################
#### SELINUX SSHD #### ----------------------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

semanage port -a -t ssh_port_t -p tcp 4477
systemctl restart sshd.service

####### FINAL MESSAGE 100% SETUP COMPLETE!!! #######
((COMPLETED_STEPS++))
send_progress_message "100"

################################################################################################################################################
#### FINAL SETUP MESSAGE TO TG #### ---------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

send_message() {
    local text="$1"
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$text"
}

IP=$(hostname -I | cut -d' ' -f1)

MESSAGE="
Installation successfully done!!! %0A
You can login now with VNC: $IP:1
Password: Money22


Enjoyyy!!! :)"

send_message "$MESSAGE"

################################################################################################################################################
#### INSTALL SOME SOFTWARE #### -------------------------------------------------------------------------------------------------------- #######
################################################################################################################################################

###### CCRYPT INSTALL ######
wget https://ccrypt.sourceforge.net/download/1.11/ccrypt-1.11-1.x86_64.rpm
rpm -Uvh ccrypt-1.11-1.x86_64.rpm

rm -rf ccrypt-1.11-1.x86_64.rpm

###### SUBLIME TEXT ######
sudo rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
sudo dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
sudo dnf install sublime-text -y

###### LIBRE OFFICE ######
yum install -y libreoffice

###### GEANY ######
sudo dnf install geany -y

###### GOOGLE CHROME ######
sudo dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm

###### VSCODE ######
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install code -y

####### INSTALL SPEEDTEST #######
curl -s https://packagecloud.io/install/repositories/ookla/speedtest-cli/script.rpm.sh | sudo bash
sudo yum -y install speedtest

mdkir /root/vscode

################################################################################################################################################
#### EXECUTE VESTA CP INSTALLATION WITH YES / NO  #### --------------------------------------------------------------------------------- #######
################################################################################################################################################

chmod 777 v_cp.sh
bash v_cp.sh

################################################################################################################################################
#### DELETE ALL SCRIPTS AND CLEAN UP  #### --------------------------------------------------------------------------------------------- #######
################################################################################################################################################

rm -rf /root/vnc
rm -rf /root/StackScript
rm -rf /home/admin/set_vnc_password.exp
