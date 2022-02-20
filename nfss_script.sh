#!/bin/bash
sudo -i
echo "RUN Utils install"
yum install nfs-utils -y
echo "RUN firewall steps"
systemctl enable firewalld.service
systemctl start firewalld.service
firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent
firewall-cmd --reload
echo "RUN NFS"
systemctl enable nfs --now
mkdir -p /srv/share/upload
chown -R nfsnobody:nfsnobody /srv/share
chmod 0777 /srv/share/upload
echo "/srv/share 192.168.50.11/32(rw,sync,root_squash)" >> /etc/exports
exportfs -r
