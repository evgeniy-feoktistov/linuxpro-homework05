#!/bin/bash
sudo -i
echo "RUN utils install"
yum install nfs-utils -y
echo "RUN firewall step..."
systemctl enable firewalld --now
echo "RUN fstab"
echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
echo "RUN configurations / or just need restart"
systemctl daemon-reload
systemctl restart remote-fs.target

