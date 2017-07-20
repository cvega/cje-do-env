#!/usr/bin/env bash

adduser $1
usermod -aG wheel $1
mkdir -p /home/$1/.ssh
cp /root/.ssh/* /home/$1/.ssh
chown $1:$1 -R /home/$1/.ssh
sed -i '/^#.*NOPASSWD/s/^# //' /etc/sudoers
