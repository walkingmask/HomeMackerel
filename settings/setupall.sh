#!/bin/bash
set -eu

# このスクリプトはそれっぽく書かれていますが
# 期待通りの動作を保証するものではありません
# 参照程度にご利用ください
# Created by walkingmask at 2017/03/04

# Usage: sudo bash setupall.sh

if ! ls . | grep -E ".*.pub" >/dev/null 2>&1; then
  echo "> Put the rsa.pub file in this directory." 1>&2
  exit 1
fi

WORKUSER=""     # Work user name
SSHUSER=""      # SSH user name
SSHPASS=""      # SSH user password
DOCKERUSER=""   # Docker user name
DOCKERPASS=""   # Docker user password
NICDEVNAME=""   # NIC device name (ex. enp3s0)
FIXEDIPADDR=""  # Static private IP address (ex. 192.168.0.10/24)
GATEWAY=""      # Gateway IP address (ex. 192.168.0.1)
ALLOWEDIP=""    # Allowed IP address for UFW (ex. 216.58.0.0/16)
SSHPORT=""      # SSH port
JLPORT=""       # jupyter lab port
TBPORT=""       # tensorboard port
NOMDOMAIN=""    # Global domain (no SSL)
SSLDOMAIN=""    # Global domain (SSL)
ORGANIZATION="" # Organization name (ex. OREORE.inc)
COUNTRY=""      # Country code (ex. JP)

# locale
echo 'export LC_ALL=en_US.UTF-8' >>~/.bashrc
source ~/.bashrc

# network
mkdir ./defaults
cp /etc/sysctl.conf ./defaults/sysctl.conf.default
sed -i -e "$ a net.ipv6.conf.all.disable_ipv6 = 1" /etc/sysctl.conf
sed -i -e "$ a net.ipv6.conf.default.disable_ipv6 = 1" /etc/sysctl.conf
sudo sysctl -p
# lshw -short -class network
cp /etc/network/interfaces ./defaults/interfaces.default
sed -i -e "/iface lo inet loopback/G" \
-e "$ a # auto $NICDEVNAME" \
-e "$ a # iface $NICDEVNAME inet static" \
-e "$ a # address $FIXEDIPADDR" \
-e "$ a # gateway $GATEWAY" \
-e "$ a # dns-nameservers 8.8.8.8 $GATEWAY" \
/etc/network/interfaces
systemctl restart networking

# update all
apt -y update
apt -y upgrade

# sshd
apt install -y openssh-server

# user settings
# pass prompt
sh -c 'cat << EOF >/etc/sudoers.d/myOverrides
Defaults passprompt = "%u@%h PaSsWoRd: "
EOF'
chmod 0440 /etc/sudoers.d/myOverrides
# directory permission
cp /etc/login.defs ./defaults/login.defs.default
sed -i -e "s/^UMASK\(\t*\)022/UMASK\1027/g" /etc/login.defs
# work user's directory permission
chmod 750 /home/$WORKUSER
# ssd
cp /etc/ssh/sshd_config ./defaults/sshd_config.default
sed -i -e "s/Port 22/Port $SSHPORT/g" \
-e "s/LogLevel INFO/LogLevel VERBOSE/g" \
-e "/^LoginGraceTime/i MaxAuthTries 3" \
-e "s/LoginGraceTime 120/LoginGraceTime 30/g" \
-e "s/prohibit-password/no/g" \
-e "s/#PasswordAuthentication yes/PasswordAuthentication no/g" \
/etc/ssh/sshd_config
# ufw
cp /etc/default/ufw ./defaults/ufw.default
sed -i -e "s/IPV6=yes/IPV6=no/g" /etc/default/ufw
ufw default DENY
ufw limit from $ALLOWEDIP to any port $SSHPORT proto tcp
#ufw limit from $ALLOWEDIP2 to any port $SSHPORT proto tcp
# add ssh user
adduser $SSHUSER
PUBKEY="`ls . | grep -E *.pub`"
cp ./$PUBKEY /home/$SSHUSER/
chown $SSHUSER:$SSHUSER /home/$SSHUSER/$PUBKEY
su $SSHUSER
# for docker
mkdir /home/$SSHUSER/Workspace
chmod 777 /home/$SSHUSER/Workspace
# ssh
mkdir /home/$SSHUSER/.ssh
chmod 700 /home/$SSHUSER/.ssh
cd /home/$SSHUSER/.ssh
touch /home/$SSHUSER/.ssh/authorized_keys
chmod 600 /home/$SSHUSER/.ssh/authorized_keys
cat /home/$SSHUSER/$PUBKEY >>authorized_keys
rm /home/$SSHUSER/$PUBKEY
exit
sed -i -e '$ a AllowUsers $SSHUSER' /etc/ssh/sshd_config
# execute permissions
sh -c 'cat << EOF >/etc/sudoers.d/$SSHUSER
$SSHUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker ps -a
$SSHUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker start $DOCKERUSER
$SSHUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker restart $DOCKERUSER
$SSHUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker stop $DOCKERUSER
$SSHUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker logs -ft $DOCKERUSER
$SSHUSER    ALL=(ALL) NOPASSWD: /sbin/shutdown now
$SSHUSER    ALL=(ALL) NOPASSWD: /sbin/reboot now
EOF'
chmod 0440 /etc/sudoers.d/$SSHUSER
sh -c 'cat << EOF >/etc/sudoers.d/$WORKUSER
$WORKUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker ps -a
$WORKUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker start $DOCKERUSER
$WORKUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker restart $DOCKERUSER
$WORKUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker stop $DOCKERUSER
$WORKUSER    ALL=(ALL) NOPASSWD: /usr/bin/docker logs -ft $DOCKERUSER
$WORKUSER    ALL=(ALL) NOPASSWD: /sbin/shutdown now
$WORKUSER    ALL=(ALL) NOPASSWD: /sbin/reboot now
EOF'
chmod 0440 /etc/sudoers.d/$WORKUSER
# update
systemctl restart sshd
ufw enable

# install docker
apt -y install curl linux-image-extra-$(uname -r) linux-image-extra-virtual
apt -y install apt-transport-https ca-certificates
curl -fsSL https://yum.dockerproject.org/gpg | apt-key add -
apt-key fingerprint 58118E89F3A912897C070ADBF76221572C52609D
apt -y install software-properties-common
add-apt-repository "deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs) main"
apt -y update
apt -y install docker-engine

# install nvidia-driver
add-apt-repository ppa:graphics-drivers/ppa
apt -y update
apt -y install nvidia-378
#apt -y install ubuntu-drivers-common
nvidia-smi

# install nvidia-docker
wget -P /tmp https://github.com/NVIDIA/nvidia-docker/releases/download/v1.0.0/nvidia-docker_1.0.0-1_amd64.deb
dpkg -i /tmp/nvidia-docker*.deb && rm /tmp/nvidia-docker*.deb

# build docker image from Dockerfile
sed -i -e "s/DOCKERUSER/$DOCKERUSER/g" ./Dockerfile
sed -i -e "s/SSLDOMAIN/$SSLDOMAIN/g" ./Dockerfile
sed -i -e "s/ORGANIZATION/$ORGANIZATION/g" ./Dockerfile
sed -i -e "s/COUNTRY/$COUNTRY/g" ./Dockerfile
sed -i -e "s/DOCKERUSER/$DOCKERUSER/g" ./jupyter_notebook_config.py
sed -i -e "s/DOCKERUSER/$DOCKERUSER/g" ./jl
sed -i -e "s/DOCKERUSER/$DOCKERUSER/g" ./tb
nvidia-docker build -t $DOCKERUSER:latest .

# run docker container
sudo nvidia-docker run \
-e PASSWORD=$DOCKERPASS \
-p $JLPORT:8888 \
-p $TBPORT:6006 \
-v /home/$SSHUSER/Workspace:/home/$DOCKERUSER/Workspace \
--name $DOCKERUSER \
-u $DOCKERUSER \
-d $DOCKERUSER:latest /usr/local/bin/jl

# docker auto start setting
sudo sh -c 'cat << EOF > /etc/systemd/system/docker_autostart.service
[Unit]
Description=auto start of docker containers
After=docker.service
Requires=docker.service

[Service]
ExecStart=/bin/bash -c "/usr/bin/docker start $DOCKERUSER"

[Install]
WantedBy=multi-user.target
EOF'
sudo systemctl enable docker_autostart.service

# postfix
sed -i -e "s/NOMDOMAIN/$NOMDOMAIN/g" ./main.cf
sed -i -e "s/SSLDOMAIN/$SSLDOMAIN/g" ./main.cf
apt -y install postfix
if [ -f /etc/postfix/main.cf ]; then
  cp /etc/postfix/main.cf ./defaults/mail.cf.default
  rm /etc/postfix/main.cf
fi
mv ./main.cf /etc/postfix/main.cf
chown root:root /etc/postfix/main.cf
chmod 644 /etc/postfix/main.cf
newaliases
systemctl restart postfix

# mail
apt -y install mailutils
echo 'export MAIL=$HOME/Maildir' >>~/.bashrc
echo 'alias mailr="sudo mail -f /root/Maildir"' >>~/.bashrc
source ~/.bashrc
echo 'test.' | mail -s 'test' $WORKUSER@localhost

# dovecot
apt -y install dovecot-common dovecot-imapd dovecot-pop3d
cp /etc/dovecot/dovecot.conf ./defaults/dovecot.conf.default
cp /etc/dovecot/conf.d/10-auth.conf ./defaults/10-auth.conf.default
cp /etc/dovecot/conf.d/10-mail.conf ./defaults/10-mail.conf.default
cp /etc/dovecot/conf.d/10-master.conf ./defaults/10-master.conf.default
sed -i -e "s|#listen = \*, ::|listen = *|g" /etc/dovecot/dovecot.conf
sed -i -e "s|#disable_plaintext_auth = yes|disable_plaintext_auth = no|g" \
-e "s|^auth_mechanisms = plain$|auth_mechanisms = plain login|g" /etc/dovecot/conf.d/10-auth.conf
sed -i -e "s|mail_location = mbox:~/mail:INBOX=/var/mail/%u|mail_location = maildir:~/Maildir|g" /etc/dovecot/conf.d/10-mail.conf
sed -i -e "/^  # Postfix smtp-auth$/a\  unix_listener /var/spool/postfix/private/auth {" \
-e "/^  # Postfix smtp-auth$/a\    mode = 0666" \
-e "/^  # Postfix smtp-auth$/a\    group = postfix" \
-e "/^  # Postfix smtp-auth$/a\    user = postfix" \
-e "/^  # Postfix smtp-auth$/a\  }" \
/etc/dovecot/conf.d/10-master.conf
systemctl restart dovecot

# ddns
mkdir /etc/ddns
touch '/etc/ddns/current-ip'
touch '/etc/ddns/account-info'
mkdir /var/log/ddns
touch '/var/log/ddns/update.log'
if [ -f /etc/ddns/account-info ]; then
  while true
  do
    read -p '> Do you want to add more account info? [y/(n)]: ' ans
    
    if [ "$ans" = "y" ]; then

      read -p 'ACCOUNT: ' ACCOUNT
      read -p 'DOMAIN: ' DOMAIN
      read -sp 'PASSWORD: ' PASSWORD

      if [ $ACCOUNT ] && [ $DOMAIN ] && [ $PASSWORD ] ; then
        echo "$ACCOUNT $DOMAIN $PASSWORD" >>/etc/ddns/account-info
      else
        echo '> please specified informations correctly.' 1>&2
      fi

      echo ''

    else
      echo '' >>/etc/ddns/account-info
      break
    fi
  done
fi
cp ./update-ddns /etc/cron.hourly/update-ddns
chmod +x /etc/cron.hourly/update-ddns
/etc/cron.hourly/update-ddns

# clamav
apt -y install clamav
cp /etc/clamav/freshclam.conf ./defaults/freshclam.conf.default
sed -i -e "s/^NotifyClamd/#NotifyClamd/g" /etc/clamav/freshclam.conf
freshclam >/dev/null 2>&1 || rm /var/log/clamav/freshclam.log
cp ./virusscan /etc/cron.daily/
chmod 700 /etc/cron.daily/virusscan
wget http://www.eicar.org/download/eicar.com
/etc/cron.daily/virusscan

# rkhunter
apt -y install rkhunter
cp /etc/default/rkhunter ./defaults/rkhunter.default
sed -i -e 's/CRON_DAILY_RUN=""/CRON_DAILY_RUN="true"/g' \
-e 's/CRON_DB_UPDATE=""/CRON_DB_UPDATE="true"/g' \
-e 's/DB_UPDATE_EMAIL="false"/DB_UPDATE_EMAIL="true"/g' \
/etc/default/rkhunter
cp /etc/rkhunter.conf ./defaults/rkhunter.conf.default
sed -i -e 's/^#MAIL-ON-WARNING=/^MAIL-ON-WARNING=/g' \
-e 's/^#MAIL_CMD=/MAIL_CMD=/g' \
-e 's/#PKGMGR=NONE/PKGMGR=DPKG/g' \
-e 's,#ALLOWDEVFILE=/dev/shm/pulse,ALLOWDEVFILE=/dev/shm/pulse,g' \
/etc/rkhunter.conf
rkhunter --update
rkhunter --propupd
rkhunter --check --sk

# cleanup all
apt autoremove -y
apt autoclean -y

exit 0
