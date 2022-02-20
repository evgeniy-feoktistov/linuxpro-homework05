# linuxpro-homework05

# Vagrant стенд для NFS

1. [Создаем тестовые виртуальные машины](#1)
2. [Настраиваем сервер NFSS](#2)
3. [Настраиваем клиента NFSC](#3)
4. [Проверяем работоспособность сервера/клиента](#4)
5. [Создаем автоматизированный Vagrantfile](#5)

* * *
<a name="1"/>

## Создаём тестовые виртуальные машины
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
        config.vm.box = "centos/7"
        config.vm.box_version = "2004.01"
        config.vm.provider "virtualbox" do |v|
        v.memory = 256
        v.cpus = 1
        end
        config.vm.define "nfss" do |nfss|
        nfss.vm.network "private_network", ip: "192.168.50.10",
        virtualbox__intnet: "net1"
        nfss.vm.hostname = "nfss"
        end
        config.vm.define "nfsc" do |nfsc|
        nfsc.vm.network "private_network", ip: "192.168.50.11",
        virtualbox__intnet: "net1"
        nfsc.vm.hostname = "nfsc"
        end
end
```
Запускаем, и имеем 2 запущенные ВМ.
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      running (virtualbox)
nfsc                      running (virtualbox)
```

* * *
<a name="2"/>

## Настраиваем сервер NFSS
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo -i
```
Устанавливаем nfs-utils
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo -i
[root@nfss ~]# yum install nfs-utils -y
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.reconn.ru
 * extras: mirror.docker.ru
 * updates: mirror.docker.ru
base                                                                                                        | 3.6 kB  00:00:00
extras                                                                                                      | 2.9 kB  00:00:00
updates                                                                                                     | 2.9 kB  00:00:00
(1/4): base/7/x86_64/group_gz                                                                               | 153 kB  00:00:00
(2/4): extras/7/x86_64/primary_db                                                                           | 243 kB  00:00:00
(3/4): base/7/x86_64/primary_db                                                                             | 6.1 MB  00:00:01
(4/4): updates/7/x86_64/primary_db                                                                          |  13 MB  00:00:02
Resolving Dependencies
--> Running transaction check
---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

===================================================================================================================================
 Package                       Arch                       Version                                Repository                   Size
===================================================================================================================================
Updating:
 nfs-utils                     x86_64                     1:1.3.0-0.68.el7.2                     updates                     413 k

Transaction Summary
===================================================================================================================================
Upgrade  1 Package

Total download size: 413 k
Downloading packages:
No Presto metadata available for updates
warning: /var/cache/yum/x86_64/7/updates/packages/nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm                                                                       | 413 kB  00:00:00
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Importing GPG key 0xF4A80EB5:
 Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
 Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
 Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             1/2
  Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               2/2
  Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             1/2
  Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               2/2

Updated:
  nfs-utils.x86_64 1:1.3.0-0.68.el7.2

Complete!
```
Включаем firewall и настраиваем правила для NFS3
```bash
[root@nfss ~]# systemctl enable firewalld.service
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@nfss ~]# systemctl start firewalld.service
[root@nfss ~]# firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent
success
[root@nfss ~]# firewall-cmd --reload
success
[root@nfss ~]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-02-20 14:08:16 UTC; 1min 7s ago
     Docs: man:firewalld(1)
 Main PID: 3384 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3384 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 20 14:08:15 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 20 14:08:16 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Feb 20 14:08:16 nfss firewalld[3384]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration...it now.
Feb 20 14:09:16 nfss firewalld[3384]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration...it now.
Hint: Some lines were ellipsized, use -l to show in full.

```
Включаем сервер NFS (для конфигурации NFSv3 over UDP он не требует
дополнительнойнастройки)
```bash
[root@nfss ~]# systemctl enable nfs --now
Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
[root@nfss ~]# systemctl status nfs --now
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
   Active: active (exited) since Sun 2022-02-20 14:12:41 UTC; 28s ago
  Process: 3563 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 3547 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 3546 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 3547 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Feb 20 14:12:41 nfss systemd[1]: Starting NFS server and services...
Feb 20 14:12:41 nfss systemd[1]: Started NFS server and services.
```
проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp, 20048/tcp, 111/udp, 111/tcp (не все они будут использоваться далее, но их наличие сигнализирует о том, что необходимые сервисы готовы принимать внешние подключения)
```bash
[root@nfss ~]# ss -tnplu
Netid State      Recv-Q Send-Q                  Local Address:Port                                 Peer Address:Port
udp   UNCONN     0      0                                   *:1007                                            *:*                   users:(("rpcbind",pid=411,fd=7))
udp   UNCONN     0      0                           127.0.0.1:755                                             *:*                   users:(("rpc.statd",pid=3539,fd=14))
udp   UNCONN     0      0                                   *:60159                                           *:*                   users:(("rpc.statd",pid=3539,fd=7))
udp   UNCONN     0      0                                   *:2049                                            *:*
udp   UNCONN     0      0                           127.0.0.1:323                                             *:*                   users:(("chronyd",pid=348,fd=5))
udp   UNCONN     0      0                                   *:68                                              *:*                   users:(("dhclient",pid=2359,fd=6))
udp   UNCONN     0      0                                   *:20048                                           *:*                   users:(("rpc.mountd",pid=3545,fd=7))
udp   UNCONN     0      0                                   *:111                                             *:*                   users:(("rpcbind",pid=411,fd=6))
udp   UNCONN     0      0                                   *:55448                                           *:*
udp   UNCONN     0      0                                [::]:1007                                         [::]:*                   users:(("rpcbind",pid=411,fd=10))
udp   UNCONN     0      0                                [::]:2049                                         [::]:*
udp   UNCONN     0      0                                [::]:45872                                        [::]:*
udp   UNCONN     0      0                               [::1]:323                                          [::]:*                   users:(("chronyd",pid=348,fd=6))
udp   UNCONN     0      0                                [::]:20048                                        [::]:*                   users:(("rpc.mountd",pid=3545,fd=9))
udp   UNCONN     0      0                                [::]:111                                          [::]:*                   users:(("rpcbind",pid=411,fd=9))
udp   UNCONN     0      0                                [::]:56499                                        [::]:*                   users:(("rpc.statd",pid=3539,fd=9))
tcp   LISTEN     0      64                                  *:2049                                            *:*
tcp   LISTEN     0      128                                 *:111                                             *:*                   users:(("rpcbind",pid=411,fd=8))
tcp   LISTEN     0      128                                 *:20048                                           *:*                   users:(("rpc.mountd",pid=3545,fd=8))
tcp   LISTEN     0      128                                 *:22                                              *:*                   users:(("sshd",pid=612,fd=3))
tcp   LISTEN     0      64                                  *:39481                                           *:*
tcp   LISTEN     0      100                         127.0.0.1:25                                              *:*                   users:(("master",pid=699,fd=13))
tcp   LISTEN     0      128                                 *:48669                                           *:*                   users:(("rpc.statd",pid=3539,fd=8))
tcp   LISTEN     0      64                               [::]:2049                                         [::]:*
tcp   LISTEN     0      64                               [::]:44071                                        [::]:*
tcp   LISTEN     0      128                              [::]:111                                          [::]:*                   users:(("rpcbind",pid=411,fd=11))
tcp   LISTEN     0      128                              [::]:20048                                        [::]:*                   users:(("rpc.mountd",pid=3545,fd=10))
tcp   LISTEN     0      128                              [::]:50769                                        [::]:*                   users:(("rpc.statd",pid=3539,fd=10))
tcp   LISTEN     0      128                              [::]:22                                           [::]:*                   users:(("sshd",pid=612,fd=4))
tcp   LISTEN     0      100                             [::1]:25                                           [::]:*                   users:(("master",pid=699,fd=14))
```
Cоздаём и настраиваем директорию, которая будет экспортирована в будущем
```bash
[root@nfss ~]# mkdir -p /srv/share/upload
[root@nfss ~]# chown -R nfsnobody:nfsnobody /srv/share
[root@nfss ~]# chmod 0777 /srv/share/upload
```
Создаём в файле **/etc/exports** структуру, которая позволит экспортировать ранее созданную директорию
```bash
[root@nfss ~]# cat << EOF > /etc/exports
> /srv/share 192.168.50.11/32(rw,sync,root_squash)
> EOF
[root@nfss ~]# cat /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)
```
Экспортируем ранее созданную директорию
```bash
[root@nfss ~]# exportfs -r
```
Проверяем экспортированную директорию следующейкомандои
```bash
[root@nfss ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
* * *
<a name="3"/>

## Настраиваем клиент NFSC
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfsc
[vagrant@nfsc ~]$ sudo -i
```
Установим вспомогательные утилиты
```bash
[root@nfsc ~]# yum install nfs-utils net-tools
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.sale-dedic.com
 * extras: mirror.sale-dedic.com
 * updates: mirror.reconn.ru
base                                                                                                        | 3.6 kB  00:00:00
extras                                                                                                      | 2.9 kB  00:00:00
updates                                                                                                     | 2.9 kB  00:00:00
(1/4): base/7/x86_64/group_gz                                                                               | 153 kB  00:00:00
(2/4): extras/7/x86_64/primary_db                                                                           | 243 kB  00:00:00
(3/4): base/7/x86_64/primary_db                                                                             | 6.1 MB  00:00:01
(4/4): updates/7/x86_64/primary_db                                                                          |  13 MB  00:00:02
Resolving Dependencies
--> Running transaction check
---> Package net-tools.x86_64 0:2.0-0.25.20131004git.el7 will be installed
---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

===================================================================================================================================
 Package                     Arch                     Version                                      Repository                 Size
===================================================================================================================================
Installing:
 net-tools                   x86_64                   2.0-0.25.20131004git.el7                     base                      306 k
Updating:
 nfs-utils                   x86_64                   1:1.3.0-0.68.el7.2                           updates                   413 k

Transaction Summary
===================================================================================================================================
Install  1 Package
Upgrade  1 Package

Total download size: 719 k
Is this ok [y/d/N]: y
Downloading packages:
No Presto metadata available for updates
warning: /var/cache/yum/x86_64/7/base/packages/net-tools-2.0-0.25.20131004git.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Public key for net-tools-2.0-0.25.20131004git.el7.x86_64.rpm is not installed
(1/2): net-tools-2.0-0.25.20131004git.el7.x86_64.rpm                                                        | 306 kB  00:00:00
Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
(2/2): nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm                                                                | 413 kB  00:00:00
-----------------------------------------------------------------------------------------------------------------------------------
Total                                                                                              1.3 MB/s | 719 kB  00:00:00
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Importing GPG key 0xF4A80EB5:
 Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
 Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
 Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Is this ok [y/N]: y
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             1/3
  Installing : net-tools-2.0-0.25.20131004git.el7.x86_64                                                                       2/3
  Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               3/3
  Verifying  : net-tools-2.0-0.25.20131004git.el7.x86_64                                                                       1/3
  Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             2/3
  Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               3/3

Installed:
  net-tools.x86_64 0:2.0-0.25.20131004git.el7

Updated:
  nfs-utils.x86_64 1:1.3.0-0.68.el7.2

Complete!
```
Включаем firewall и проверяем, что он работает:
```bash
[root@nfsc ~]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@nfsc ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-02-20 14:28:03 UTC; 2s ago
     Docs: man:firewalld(1)
 Main PID: 3375 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3375 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 20 14:28:02 nfsc systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 20 14:28:03 nfsc systemd[1]: Started firewalld - dynamic firewall daemon.
Feb 20 14:28:03 nfsc firewalld[3375]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration...it now.
Hint: Some lines were ellipsized, use -l to show in full.
```
добавляем в **/etc/fstab** строку
```bash
[root@nfsc ~]# echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
[root@nfsc ~]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Thu Apr 30 22:04:55 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /                       xfs     defaults        0 0
/swapfile none swap defaults 0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0
```
Перегружаем настройки и перезапускаем службу:
```bash
[root@nfsc ~]# systemctl daemon-reload
[root@nfsc ~]# systemctl restart remote-fs.target
```
Проверяем успешность монтирования (но обязательно необходимо обратиться к каталогу, так как у нас в настройках указано автомонтирование при обращении)
```bash
[root@nfsc ~]# cd /mnt
[root@nfsc mnt]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=31,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=27012)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
```
Проверим работоспособность:
на сервере **NFSS**
```bash
[root@nfss ~]# cd /srv/share/upload
[root@nfss upload]# touch check_file
[root@nfss upload]# ll
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
```
на клиенте **NFSC**
```bash
[root@nfsc mnt]# cd /mnt/upload/
[root@nfsc upload]# ll
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
```

* * *
<a name="4"/>

## Проверяем работоспособность сервера / клиента

Проверяем клиент **NFSC**: перезагрузим, и проверим, что все работает
```bash
[root@nfsc upload]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfsc
Last login: Sun Feb 20 14:23:15 2022 from 10.0.2.2
[vagrant@nfsc ~]$ sudo -i
[root@nfsc ~]# ll /mnt/upload/
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
[root@nfsc ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[root@nfsc ~]# ll /mnt/upload
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
[root@nfsc ~]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=28,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=10993)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[root@nfsc ~]# touch /mnt/upload/final_check
[root@nfsc ~]# ll /mnt/upload
total 0
-rw-r--r--. 1 root      root      0 Feb 20 14:34 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb 20 14:50 final_check

```
Проверяем сервер **NFSS**:
```bash
[root@nfss upload]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
Last login: Sun Feb 20 14:05:03 2022 from 10.0.2.2
[vagrant@nfss ~]$ sudo -i
[root@nfss ~]# ll /srv/share/upload/
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
[root@nfss ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Sun 2022-02-20 14:40:12 UTC; 7min ago
  Process: 822 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 785 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 783 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 785 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Feb 20 14:40:12 nfss systemd[1]: Starting NFS server and services...
Feb 20 14:40:12 nfss systemd[1]: Started NFS server and services.
[root@nfss ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-02-20 14:40:09 UTC; 7min ago
     Docs: man:firewalld(1)
 Main PID: 398 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─398 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 20 14:40:09 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 20 14:40:09 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Feb 20 14:40:10 nfss firewalld[398]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration ...it now.
Hint: Some lines were ellipsized, use -l to show in full.
[root@nfss ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfss ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
```
Итого: службы запущены, файл на месте, клиента видим, сервер видим, на клиенте новый файл создается. Можно все записывать в Vagrantfile

* * *
<a name="5"/>

## Создаем автоматизированный Vagrantfile
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
        config.vm.box = "centos/7"
        config.vm.box_version = "2004.01"
        config.vm.provider "virtualbox" do |v|
        v.memory = 256
        v.cpus = 1
        end
        config.vm.define "nfss" do |nfss|
        nfss.vm.network "private_network", ip: "192.168.50.10",
        virtualbox__intnet: "net1"
        nfss.vm.hostname = "nfss"
        nfss.vm.provision "shell", path: "nfss_script.sh"
        end
        config.vm.define "nfsc" do |nfsc|
        nfsc.vm.network "private_network", ip: "192.168.50.11",
        virtualbox__intnet: "net1"
        nfsc.vm.hostname = "nfsc"
        nfsc.vm.provision "shell", path: "nfsc_script.sh"
        end
end
```
И создаем 2 скрипта для сервера и клиента соответственно
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat nfss_script.sh
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
```
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat nfsc_script.sh
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
```
Удаляем обе ВМ и поднимаем заново, после будем проверять
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant halt nfss nfsc
==> nfsc: Attempting graceful shutdown of VM...
==> nfss: Attempting graceful shutdown of VM...
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      poweroff (virtualbox)
nfsc                      poweroff (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant destroy nfss nfsc
    nfsc: Are you sure you want to destroy the 'nfsc' VM? [y/N] y
==> nfsc: Destroying VM and associated drives...
    nfss: Are you sure you want to destroy the 'nfss' VM? [y/N] y
==> nfss: Destroying VM and associated drives...
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      not created (virtualbox)
nfsc                      not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant up
Bringing machine 'nfss' up with 'virtualbox' provider...
Bringing machine 'nfsc' up with 'virtualbox' provider...
==> nfss: Importing base box 'centos/7'...
==> nfss: Matching MAC address for NAT networking...
==> nfss: Checking if box 'centos/7' version '2004.01' is up to date...
==> nfss: Setting the name of the VM: linuxpro-homework05_nfss_1645370772829_24325
==> nfss: Clearing any previously set network interfaces...
==> nfss: Preparing network interfaces based on configuration...
    nfss: Adapter 1: nat
    nfss: Adapter 2: intnet
==> nfss: Forwarding ports...
    nfss: 22 (guest) => 2222 (host) (adapter 1)
==> nfss: Running 'pre-boot' VM customizations...
==> nfss: Booting VM...
==> nfss: Waiting for machine to boot. This may take a few minutes...
    nfss: SSH address: 127.0.0.1:2222
    nfss: SSH username: vagrant
    nfss: SSH auth method: private key
    nfss:
    nfss: Vagrant insecure key detected. Vagrant will automatically replace
    nfss: this with a newly generated keypair for better security.
    nfss:
    nfss: Inserting generated public key within guest...
    nfss: Removing insecure key from the guest if it's present...
    nfss: Key inserted! Disconnecting and reconnecting using new SSH key...
==> nfss: Machine booted and ready!
==> nfss: Checking for guest additions in VM...
    nfss: No guest additions were detected on the base box for this VM! Guest
    nfss: additions are required for forwarded ports, shared folders, host only
    nfss: networking, and more. If SSH fails on this machine, please install
    nfss: the guest additions and repackage the box to continue.
    nfss:
    nfss: This is not an error message; everything may continue to work properly,
    nfss: in which case you may ignore this message.
==> nfss: Setting hostname...
==> nfss: Configuring and enabling network interfaces...
==> nfss: Rsyncing folder: /home/ujack/linuxpro-homework05/ => /vagrant
==> nfss: Running provisioner: shell...
    nfss: Running: /tmp/vagrant-shell20220220-91573-cryifu.sh
    nfss: RUN Utils install
    nfss: Loaded plugins: fastestmirror
    nfss: Determining fastest mirrors
    nfss:  * base: mirror.reconn.ru
    nfss:  * extras: mirror.reconn.ru
    nfss:  * updates: mirror.reconn.ru
    nfss: Resolving Dependencies
    nfss: --> Running transaction check
    nfss: ---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
    nfss: ---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
    nfss: --> Finished Dependency Resolution
    nfss:
    nfss: Dependencies Resolved
    nfss:
    nfss: ================================================================================
    nfss:  Package          Arch          Version                    Repository      Size
    nfss: ================================================================================
    nfss: Updating:
    nfss:  nfs-utils        x86_64        1:1.3.0-0.68.el7.2         updates        413 k
    nfss:
    nfss: Transaction Summary
    nfss: ================================================================================
    nfss: Upgrade  1 Package
    nfss:
    nfss: Total download size: 413 k
    nfss: Downloading packages:
    nfss: No Presto metadata available for updates
    nfss: Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
    nfss: warning: /var/cache/yum/x86_64/7/updates/packages/nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
    nfss: Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfss: Importing GPG key 0xF4A80EB5:
    nfss:  Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
    nfss:  Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
    nfss:  Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
    nfss:  From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfss: Running transaction check
    nfss: Running transaction test
    nfss: Transaction test succeeded
    nfss: Running transaction
    nfss:   Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfss:   Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfss:   Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfss:   Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfss:
    nfss: Updated:
    nfss:   nfs-utils.x86_64 1:1.3.0-0.68.el7.2
    nfss:
    nfss: Complete!
    nfss: RUN firewall steps
    nfss: Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
    nfss: Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
    nfss: success
    nfss: success
    nfss: RUN NFS
    nfss: Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
==> nfsc: Importing base box 'centos/7'...
==> nfsc: Matching MAC address for NAT networking...
==> nfsc: Checking if box 'centos/7' version '2004.01' is up to date...
==> nfsc: Setting the name of the VM: linuxpro-homework05_nfsc_1645370841687_69866
==> nfsc: Fixed port collision for 22 => 2222. Now on port 2200.
==> nfsc: Clearing any previously set network interfaces...
==> nfsc: Preparing network interfaces based on configuration...
    nfsc: Adapter 1: nat
    nfsc: Adapter 2: intnet
==> nfsc: Forwarding ports...
    nfsc: 22 (guest) => 2200 (host) (adapter 1)
==> nfsc: Running 'pre-boot' VM customizations...
==> nfsc: Booting VM...
==> nfsc: Waiting for machine to boot. This may take a few minutes...
    nfsc: SSH address: 127.0.0.1:2200
    nfsc: SSH username: vagrant
    nfsc: SSH auth method: private key
    nfsc:
    nfsc: Vagrant insecure key detected. Vagrant will automatically replace
    nfsc: this with a newly generated keypair for better security.
    nfsc:
    nfsc: Inserting generated public key within guest...
    nfsc: Removing insecure key from the guest if it's present...
    nfsc: Key inserted! Disconnecting and reconnecting using new SSH key...
==> nfsc: Machine booted and ready!
==> nfsc: Checking for guest additions in VM...
    nfsc: No guest additions were detected on the base box for this VM! Guest
    nfsc: additions are required for forwarded ports, shared folders, host only
    nfsc: networking, and more. If SSH fails on this machine, please install
    nfsc: the guest additions and repackage the box to continue.
    nfsc:
    nfsc: This is not an error message; everything may continue to work properly,
    nfsc: in which case you may ignore this message.
==> nfsc: Setting hostname...
==> nfsc: Configuring and enabling network interfaces...
==> nfsc: Rsyncing folder: /home/ujack/linuxpro-homework05/ => /vagrant
==> nfsc: Running provisioner: shell...
    nfsc: Running: /tmp/vagrant-shell20220220-91573-se0un.sh
    nfsc: RUN utils install
    nfsc: Loaded plugins: fastestmirror
    nfsc: Determining fastest mirrors
    nfsc:  * base: mirror.reconn.ru
    nfsc:  * extras: mirror.reconn.ru
    nfsc:  * updates: mirror.reconn.ru
    nfsc: Resolving Dependencies
    nfsc: --> Running transaction check
    nfsc: ---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
    nfsc: ---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
    nfsc: --> Finished Dependency Resolution
    nfsc:
    nfsc: Dependencies Resolved
    nfsc:
    nfsc: ================================================================================
    nfsc:  Package          Arch          Version                    Repository      Size
    nfsc: ================================================================================
    nfsc: Updating:
    nfsc:  nfs-utils        x86_64        1:1.3.0-0.68.el7.2         updates        413 k
    nfsc:
    nfsc: Transaction Summary
    nfsc: ================================================================================
    nfsc: Upgrade  1 Package
    nfsc:
    nfsc: Total download size: 413 k
    nfsc: Downloading packages:
    nfsc: No Presto metadata available for updates
    nfsc: Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
    nfsc: warning: /var/cache/yum/x86_64/7/updates/packages/nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
    nfsc: Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfsc: Importing GPG key 0xF4A80EB5:
    nfsc:  Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
    nfsc:  Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
    nfsc:  Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
    nfsc:  From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfsc: Running transaction check
    nfsc: Running transaction test
    nfsc: Transaction test succeeded
    nfsc: Running transaction
    nfsc:   Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfsc:   Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfsc:   Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfsc:   Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfsc:
    nfsc: Updated:
    nfsc:   nfs-utils.x86_64 1:1.3.0-0.68.el7.2
    nfsc:
    nfsc: Complete!
    nfsc: RUN firewall step...
    nfsc: Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
    nfsc: Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
    nfsc: RUN fstab
    nfsc: RUN configurations / or just need restart

```
Проверяем работоспособность
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      running (virtualbox)
nfsc                      running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfsc
[vagrant@nfsc ~]$ sudo -i
[root@nfsc ~]# ll /mnt/upload/
total 0
[root@nfsc ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[root@nfsc ~]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=49,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=26475)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[root@nfsc ~]# touch /mnt/upload/final_check
[root@nfsc ~]# ll /mnt/upload
total 0
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb 20 15:29 final_check
```
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo -i
[root@nfss ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
   Active: active (exited) since Sun 2022-02-20 15:27:13 UTC; 5min ago
  Process: 3587 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 3570 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 3569 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 3570 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Feb 20 15:27:13 nfss systemd[1]: Starting NFS server and services...
Feb 20 15:27:13 nfss systemd[1]: Started NFS server and services.
[root@nfss ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfss ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[root@nfss ~]# ll /srv/share/
total 0
drwxrwxrwx. 2 nfsnobody nfsnobody 25 Feb 20 15:29 upload
[root@nfss ~]# ll /srv/share/upload/
total 0
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb 20 15:29 final_check
```# linuxpro-homework05

# Vagrant стенд для NFS

1. [Создаем тестовые виртуальные машины](#1)
2. [Настраиваем сервер NFSS](#2)
3. [Настраиваем клиента NFSC](#3)
4. [Проверяем работоспособность сервера/клиента](#4)
5. [Создаем автоматизированный Vagrantfile](#5)

* * *
<a name="1"/>

## Создаём тестовые виртуальные машины
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
        config.vm.box = "centos/7"
        config.vm.box_version = "2004.01"
        config.vm.provider "virtualbox" do |v|
        v.memory = 256
        v.cpus = 1
        end
        config.vm.define "nfss" do |nfss|
        nfss.vm.network "private_network", ip: "192.168.50.10",
        virtualbox__intnet: "net1"
        nfss.vm.hostname = "nfss"
        end
        config.vm.define "nfsc" do |nfsc|
        nfsc.vm.network "private_network", ip: "192.168.50.11",
        virtualbox__intnet: "net1"
        nfsc.vm.hostname = "nfsc"
        end
end
```
Запускаем, и имеем 2 запущенные ВМ.
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      running (virtualbox)
nfsc                      running (virtualbox)
```

* * *
<a name="2"/>

## Настраиваем сервер NFSS
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo -i
```
Устанавливаем nfs-utils
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo -i
[root@nfss ~]# yum install nfs-utils -y
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.reconn.ru
 * extras: mirror.docker.ru
 * updates: mirror.docker.ru
base                                                                                                        | 3.6 kB  00:00:00
extras                                                                                                      | 2.9 kB  00:00:00
updates                                                                                                     | 2.9 kB  00:00:00
(1/4): base/7/x86_64/group_gz                                                                               | 153 kB  00:00:00
(2/4): extras/7/x86_64/primary_db                                                                           | 243 kB  00:00:00
(3/4): base/7/x86_64/primary_db                                                                             | 6.1 MB  00:00:01
(4/4): updates/7/x86_64/primary_db                                                                          |  13 MB  00:00:02
Resolving Dependencies
--> Running transaction check
---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

===================================================================================================================================
 Package                       Arch                       Version                                Repository                   Size
===================================================================================================================================
Updating:
 nfs-utils                     x86_64                     1:1.3.0-0.68.el7.2                     updates                     413 k

Transaction Summary
===================================================================================================================================
Upgrade  1 Package

Total download size: 413 k
Downloading packages:
No Presto metadata available for updates
warning: /var/cache/yum/x86_64/7/updates/packages/nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm                                                                       | 413 kB  00:00:00
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Importing GPG key 0xF4A80EB5:
 Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
 Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
 Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             1/2
  Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               2/2
  Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             1/2
  Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               2/2

Updated:
  nfs-utils.x86_64 1:1.3.0-0.68.el7.2

Complete!
```
Включаем firewall и настраиваем правила для NFS3
```bash
[root@nfss ~]# systemctl enable firewalld.service
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@nfss ~]# systemctl start firewalld.service
[root@nfss ~]# firewall-cmd --add-service="nfs3" --add-service="rpc-bind" --add-service="mountd" --permanent
success
[root@nfss ~]# firewall-cmd --reload
success
[root@nfss ~]# systemctl status firewalld.service
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-02-20 14:08:16 UTC; 1min 7s ago
     Docs: man:firewalld(1)
 Main PID: 3384 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3384 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 20 14:08:15 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 20 14:08:16 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Feb 20 14:08:16 nfss firewalld[3384]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration...it now.
Feb 20 14:09:16 nfss firewalld[3384]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration...it now.
Hint: Some lines were ellipsized, use -l to show in full.

```
Включаем сервер NFS (для конфигурации NFSv3 over UDP он не требует
дополнительнойнастройки)
```bash
[root@nfss ~]# systemctl enable nfs --now
Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
[root@nfss ~]# systemctl status nfs --now
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
   Active: active (exited) since Sun 2022-02-20 14:12:41 UTC; 28s ago
  Process: 3563 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 3547 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 3546 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 3547 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Feb 20 14:12:41 nfss systemd[1]: Starting NFS server and services...
Feb 20 14:12:41 nfss systemd[1]: Started NFS server and services.
```
проверяем наличие слушаемых портов 2049/udp, 2049/tcp, 20048/udp, 20048/tcp, 111/udp, 111/tcp (не все они будут использоваться далее, но их наличие сигнализирует о том, что необходимые сервисы готовы принимать внешние подключения)
```bash
[root@nfss ~]# ss -tnplu
Netid State      Recv-Q Send-Q                  Local Address:Port                                 Peer Address:Port
udp   UNCONN     0      0                                   *:1007                                            *:*                   users:(("rpcbind",pid=411,fd=7))
udp   UNCONN     0      0                           127.0.0.1:755                                             *:*                   users:(("rpc.statd",pid=3539,fd=14))
udp   UNCONN     0      0                                   *:60159                                           *:*                   users:(("rpc.statd",pid=3539,fd=7))
udp   UNCONN     0      0                                   *:2049                                            *:*
udp   UNCONN     0      0                           127.0.0.1:323                                             *:*                   users:(("chronyd",pid=348,fd=5))
udp   UNCONN     0      0                                   *:68                                              *:*                   users:(("dhclient",pid=2359,fd=6))
udp   UNCONN     0      0                                   *:20048                                           *:*                   users:(("rpc.mountd",pid=3545,fd=7))
udp   UNCONN     0      0                                   *:111                                             *:*                   users:(("rpcbind",pid=411,fd=6))
udp   UNCONN     0      0                                   *:55448                                           *:*
udp   UNCONN     0      0                                [::]:1007                                         [::]:*                   users:(("rpcbind",pid=411,fd=10))
udp   UNCONN     0      0                                [::]:2049                                         [::]:*
udp   UNCONN     0      0                                [::]:45872                                        [::]:*
udp   UNCONN     0      0                               [::1]:323                                          [::]:*                   users:(("chronyd",pid=348,fd=6))
udp   UNCONN     0      0                                [::]:20048                                        [::]:*                   users:(("rpc.mountd",pid=3545,fd=9))
udp   UNCONN     0      0                                [::]:111                                          [::]:*                   users:(("rpcbind",pid=411,fd=9))
udp   UNCONN     0      0                                [::]:56499                                        [::]:*                   users:(("rpc.statd",pid=3539,fd=9))
tcp   LISTEN     0      64                                  *:2049                                            *:*
tcp   LISTEN     0      128                                 *:111                                             *:*                   users:(("rpcbind",pid=411,fd=8))
tcp   LISTEN     0      128                                 *:20048                                           *:*                   users:(("rpc.mountd",pid=3545,fd=8))
tcp   LISTEN     0      128                                 *:22                                              *:*                   users:(("sshd",pid=612,fd=3))
tcp   LISTEN     0      64                                  *:39481                                           *:*
tcp   LISTEN     0      100                         127.0.0.1:25                                              *:*                   users:(("master",pid=699,fd=13))
tcp   LISTEN     0      128                                 *:48669                                           *:*                   users:(("rpc.statd",pid=3539,fd=8))
tcp   LISTEN     0      64                               [::]:2049                                         [::]:*
tcp   LISTEN     0      64                               [::]:44071                                        [::]:*
tcp   LISTEN     0      128                              [::]:111                                          [::]:*                   users:(("rpcbind",pid=411,fd=11))
tcp   LISTEN     0      128                              [::]:20048                                        [::]:*                   users:(("rpc.mountd",pid=3545,fd=10))
tcp   LISTEN     0      128                              [::]:50769                                        [::]:*                   users:(("rpc.statd",pid=3539,fd=10))
tcp   LISTEN     0      128                              [::]:22                                           [::]:*                   users:(("sshd",pid=612,fd=4))
tcp   LISTEN     0      100                             [::1]:25                                           [::]:*                   users:(("master",pid=699,fd=14))
```
Cоздаём и настраиваем директорию, которая будет экспортирована в будущем
```bash
[root@nfss ~]# mkdir -p /srv/share/upload
[root@nfss ~]# chown -R nfsnobody:nfsnobody /srv/share
[root@nfss ~]# chmod 0777 /srv/share/upload
```
Создаём в файле **/etc/exports** структуру, которая позволит экспортировать ранее созданную директорию
```bash
[root@nfss ~]# cat << EOF > /etc/exports
> /srv/share 192.168.50.11/32(rw,sync,root_squash)
> EOF
[root@nfss ~]# cat /etc/exports
/srv/share 192.168.50.11/32(rw,sync,root_squash)
```
Экспортируем ранее созданную директорию
```bash
[root@nfss ~]# exportfs -r
```
Проверяем экспортированную директорию следующейкомандои
```bash
[root@nfss ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
```
* * *
<a name="3"/>

## Настраиваем клиент NFSC
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfsc
[vagrant@nfsc ~]$ sudo -i
```
Установим вспомогательные утилиты
```bash
[root@nfsc ~]# yum install nfs-utils net-tools
Loaded plugins: fastestmirror
Determining fastest mirrors
 * base: mirror.sale-dedic.com
 * extras: mirror.sale-dedic.com
 * updates: mirror.reconn.ru
base                                                                                                        | 3.6 kB  00:00:00
extras                                                                                                      | 2.9 kB  00:00:00
updates                                                                                                     | 2.9 kB  00:00:00
(1/4): base/7/x86_64/group_gz                                                                               | 153 kB  00:00:00
(2/4): extras/7/x86_64/primary_db                                                                           | 243 kB  00:00:00
(3/4): base/7/x86_64/primary_db                                                                             | 6.1 MB  00:00:01
(4/4): updates/7/x86_64/primary_db                                                                          |  13 MB  00:00:02
Resolving Dependencies
--> Running transaction check
---> Package net-tools.x86_64 0:2.0-0.25.20131004git.el7 will be installed
---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
--> Finished Dependency Resolution

Dependencies Resolved

===================================================================================================================================
 Package                     Arch                     Version                                      Repository                 Size
===================================================================================================================================
Installing:
 net-tools                   x86_64                   2.0-0.25.20131004git.el7                     base                      306 k
Updating:
 nfs-utils                   x86_64                   1:1.3.0-0.68.el7.2                           updates                   413 k

Transaction Summary
===================================================================================================================================
Install  1 Package
Upgrade  1 Package

Total download size: 719 k
Is this ok [y/d/N]: y
Downloading packages:
No Presto metadata available for updates
warning: /var/cache/yum/x86_64/7/base/packages/net-tools-2.0-0.25.20131004git.el7.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
Public key for net-tools-2.0-0.25.20131004git.el7.x86_64.rpm is not installed
(1/2): net-tools-2.0-0.25.20131004git.el7.x86_64.rpm                                                        | 306 kB  00:00:00
Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
(2/2): nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm                                                                | 413 kB  00:00:00
-----------------------------------------------------------------------------------------------------------------------------------
Total                                                                                              1.3 MB/s | 719 kB  00:00:00
Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Importing GPG key 0xF4A80EB5:
 Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
 Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
 Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
 From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
Is this ok [y/N]: y
Running transaction check
Running transaction test
Transaction test succeeded
Running transaction
  Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             1/3
  Installing : net-tools-2.0-0.25.20131004git.el7.x86_64                                                                       2/3
  Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               3/3
  Verifying  : net-tools-2.0-0.25.20131004git.el7.x86_64                                                                       1/3
  Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                                                                             2/3
  Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                                                                               3/3

Installed:
  net-tools.x86_64 0:2.0-0.25.20131004git.el7

Updated:
  nfs-utils.x86_64 1:1.3.0-0.68.el7.2

Complete!
```
Включаем firewall и проверяем, что он работает:
```bash
[root@nfsc ~]# systemctl enable firewalld --now
Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
[root@nfsc ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-02-20 14:28:03 UTC; 2s ago
     Docs: man:firewalld(1)
 Main PID: 3375 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─3375 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 20 14:28:02 nfsc systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 20 14:28:03 nfsc systemd[1]: Started firewalld - dynamic firewall daemon.
Feb 20 14:28:03 nfsc firewalld[3375]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration...it now.
Hint: Some lines were ellipsized, use -l to show in full.
```
добавляем в **/etc/fstab** строку
```bash
[root@nfsc ~]# echo "192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0" >> /etc/fstab
[root@nfsc ~]# cat /etc/fstab

#
# /etc/fstab
# Created by anaconda on Thu Apr 30 22:04:55 2020
#
# Accessible filesystems, by reference, are maintained under '/dev/disk'
# See man pages fstab(5), findfs(8), mount(8) and/or blkid(8) for more info
#
UUID=1c419d6c-5064-4a2b-953c-05b2c67edb15 /                       xfs     defaults        0 0
/swapfile none swap defaults 0 0
#VAGRANT-BEGIN
# The contents below are automatically generated by Vagrant. Do not modify.
#VAGRANT-END
192.168.50.10:/srv/share/ /mnt nfs vers=3,proto=udp,noauto,x-systemd.automount 0 0
```
Перегружаем настройки и перезапускаем службу:
```bash
[root@nfsc ~]# systemctl daemon-reload
[root@nfsc ~]# systemctl restart remote-fs.target
```
Проверяем успешность монтирования (но обязательно необходимо обратиться к каталогу, так как у нас в настройках указано автомонтирование при обращении)
```bash
[root@nfsc ~]# cd /mnt
[root@nfsc mnt]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=31,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=27012)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
```
Проверим работоспособность:
на сервере **NFSS**
```bash
[root@nfss ~]# cd /srv/share/upload
[root@nfss upload]# touch check_file
[root@nfss upload]# ll
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
```
на клиенте **NFSC**
```bash
[root@nfsc mnt]# cd /mnt/upload/
[root@nfsc upload]# ll
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
```

* * *
<a name="4"/>

## Проверяем работоспособность сервера / клиента

Проверяем клиент **NFSC**: перезагрузим, и проверим, что все работает
```bash
[root@nfsc upload]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfsc
Last login: Sun Feb 20 14:23:15 2022 from 10.0.2.2
[vagrant@nfsc ~]$ sudo -i
[root@nfsc ~]# ll /mnt/upload/
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
[root@nfsc ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[root@nfsc ~]# ll /mnt/upload
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
[root@nfsc ~]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=28,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=10993)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[root@nfsc ~]# touch /mnt/upload/final_check
[root@nfsc ~]# ll /mnt/upload
total 0
-rw-r--r--. 1 root      root      0 Feb 20 14:34 check_file
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb 20 14:50 final_check

```
Проверяем сервер **NFSS**:
```bash
[root@nfss upload]# reboot
Connection to 127.0.0.1 closed by remote host.
Connection to 127.0.0.1 closed.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
Last login: Sun Feb 20 14:05:03 2022 from 10.0.2.2
[vagrant@nfss ~]$ sudo -i
[root@nfss ~]# ll /srv/share/upload/
total 0
-rw-r--r--. 1 root root 0 Feb 20 14:34 check_file
[root@nfss ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
  Drop-In: /run/systemd/generator/nfs-server.service.d
           └─order-with-mounts.conf
   Active: active (exited) since Sun 2022-02-20 14:40:12 UTC; 7min ago
  Process: 822 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 785 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 783 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 785 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Feb 20 14:40:12 nfss systemd[1]: Starting NFS server and services...
Feb 20 14:40:12 nfss systemd[1]: Started NFS server and services.
[root@nfss ~]# systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sun 2022-02-20 14:40:09 UTC; 7min ago
     Docs: man:firewalld(1)
 Main PID: 398 (firewalld)
   CGroup: /system.slice/firewalld.service
           └─398 /usr/bin/python2 -Es /usr/sbin/firewalld --nofork --nopid

Feb 20 14:40:09 nfss systemd[1]: Starting firewalld - dynamic firewall daemon...
Feb 20 14:40:09 nfss systemd[1]: Started firewalld - dynamic firewall daemon.
Feb 20 14:40:10 nfss firewalld[398]: WARNING: AllowZoneDrifting is enabled. This is considered an insecure configuration ...it now.
Hint: Some lines were ellipsized, use -l to show in full.
[root@nfss ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfss ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
```
Итого: службы запущены, файл на месте, клиента видим, сервер видим, на клиенте новый файл создается. Можно все записывать в Vagrantfile

* * *
<a name="5"/>

## Создаем автоматизированный Vagrantfile
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat Vagrantfile
# -*- mode: ruby -*-
# vi: set ft=ruby :
Vagrant.configure(2) do |config|
        config.vm.box = "centos/7"
        config.vm.box_version = "2004.01"
        config.vm.provider "virtualbox" do |v|
        v.memory = 256
        v.cpus = 1
        end
        config.vm.define "nfss" do |nfss|
        nfss.vm.network "private_network", ip: "192.168.50.10",
        virtualbox__intnet: "net1"
        nfss.vm.hostname = "nfss"
        nfss.vm.provision "shell", path: "nfss_script.sh"
        end
        config.vm.define "nfsc" do |nfsc|
        nfsc.vm.network "private_network", ip: "192.168.50.11",
        virtualbox__intnet: "net1"
        nfsc.vm.hostname = "nfsc"
        nfsc.vm.provision "shell", path: "nfsc_script.sh"
        end
end
```
И создаем 2 скрипта для сервера и клиента соответственно
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat nfss_script.sh
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
```
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ cat nfsc_script.sh
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
```
Удаляем обе ВМ и поднимаем заново, после будем проверять
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant halt nfss nfsc
==> nfsc: Attempting graceful shutdown of VM...
==> nfss: Attempting graceful shutdown of VM...
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      poweroff (virtualbox)
nfsc                      poweroff (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant destroy nfss nfsc
    nfsc: Are you sure you want to destroy the 'nfsc' VM? [y/N] y
==> nfsc: Destroying VM and associated drives...
    nfss: Are you sure you want to destroy the 'nfss' VM? [y/N] y
==> nfss: Destroying VM and associated drives...
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      not created (virtualbox)
nfsc                      not created (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant up
Bringing machine 'nfss' up with 'virtualbox' provider...
Bringing machine 'nfsc' up with 'virtualbox' provider...
==> nfss: Importing base box 'centos/7'...
==> nfss: Matching MAC address for NAT networking...
==> nfss: Checking if box 'centos/7' version '2004.01' is up to date...
==> nfss: Setting the name of the VM: linuxpro-homework05_nfss_1645370772829_24325
==> nfss: Clearing any previously set network interfaces...
==> nfss: Preparing network interfaces based on configuration...
    nfss: Adapter 1: nat
    nfss: Adapter 2: intnet
==> nfss: Forwarding ports...
    nfss: 22 (guest) => 2222 (host) (adapter 1)
==> nfss: Running 'pre-boot' VM customizations...
==> nfss: Booting VM...
==> nfss: Waiting for machine to boot. This may take a few minutes...
    nfss: SSH address: 127.0.0.1:2222
    nfss: SSH username: vagrant
    nfss: SSH auth method: private key
    nfss:
    nfss: Vagrant insecure key detected. Vagrant will automatically replace
    nfss: this with a newly generated keypair for better security.
    nfss:
    nfss: Inserting generated public key within guest...
    nfss: Removing insecure key from the guest if it's present...
    nfss: Key inserted! Disconnecting and reconnecting using new SSH key...
==> nfss: Machine booted and ready!
==> nfss: Checking for guest additions in VM...
    nfss: No guest additions were detected on the base box for this VM! Guest
    nfss: additions are required for forwarded ports, shared folders, host only
    nfss: networking, and more. If SSH fails on this machine, please install
    nfss: the guest additions and repackage the box to continue.
    nfss:
    nfss: This is not an error message; everything may continue to work properly,
    nfss: in which case you may ignore this message.
==> nfss: Setting hostname...
==> nfss: Configuring and enabling network interfaces...
==> nfss: Rsyncing folder: /home/ujack/linuxpro-homework05/ => /vagrant
==> nfss: Running provisioner: shell...
    nfss: Running: /tmp/vagrant-shell20220220-91573-cryifu.sh
    nfss: RUN Utils install
    nfss: Loaded plugins: fastestmirror
    nfss: Determining fastest mirrors
    nfss:  * base: mirror.reconn.ru
    nfss:  * extras: mirror.reconn.ru
    nfss:  * updates: mirror.reconn.ru
    nfss: Resolving Dependencies
    nfss: --> Running transaction check
    nfss: ---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
    nfss: ---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
    nfss: --> Finished Dependency Resolution
    nfss:
    nfss: Dependencies Resolved
    nfss:
    nfss: ================================================================================
    nfss:  Package          Arch          Version                    Repository      Size
    nfss: ================================================================================
    nfss: Updating:
    nfss:  nfs-utils        x86_64        1:1.3.0-0.68.el7.2         updates        413 k
    nfss:
    nfss: Transaction Summary
    nfss: ================================================================================
    nfss: Upgrade  1 Package
    nfss:
    nfss: Total download size: 413 k
    nfss: Downloading packages:
    nfss: No Presto metadata available for updates
    nfss: Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
    nfss: warning: /var/cache/yum/x86_64/7/updates/packages/nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
    nfss: Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfss: Importing GPG key 0xF4A80EB5:
    nfss:  Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
    nfss:  Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
    nfss:  Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
    nfss:  From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfss: Running transaction check
    nfss: Running transaction test
    nfss: Transaction test succeeded
    nfss: Running transaction
    nfss:   Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfss:   Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfss:   Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfss:   Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfss:
    nfss: Updated:
    nfss:   nfs-utils.x86_64 1:1.3.0-0.68.el7.2
    nfss:
    nfss: Complete!
    nfss: RUN firewall steps
    nfss: Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
    nfss: Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
    nfss: success
    nfss: success
    nfss: RUN NFS
    nfss: Created symlink from /etc/systemd/system/multi-user.target.wants/nfs-server.service to /usr/lib/systemd/system/nfs-server.service.
==> nfsc: Importing base box 'centos/7'...
==> nfsc: Matching MAC address for NAT networking...
==> nfsc: Checking if box 'centos/7' version '2004.01' is up to date...
==> nfsc: Setting the name of the VM: linuxpro-homework05_nfsc_1645370841687_69866
==> nfsc: Fixed port collision for 22 => 2222. Now on port 2200.
==> nfsc: Clearing any previously set network interfaces...
==> nfsc: Preparing network interfaces based on configuration...
    nfsc: Adapter 1: nat
    nfsc: Adapter 2: intnet
==> nfsc: Forwarding ports...
    nfsc: 22 (guest) => 2200 (host) (adapter 1)
==> nfsc: Running 'pre-boot' VM customizations...
==> nfsc: Booting VM...
==> nfsc: Waiting for machine to boot. This may take a few minutes...
    nfsc: SSH address: 127.0.0.1:2200
    nfsc: SSH username: vagrant
    nfsc: SSH auth method: private key
    nfsc:
    nfsc: Vagrant insecure key detected. Vagrant will automatically replace
    nfsc: this with a newly generated keypair for better security.
    nfsc:
    nfsc: Inserting generated public key within guest...
    nfsc: Removing insecure key from the guest if it's present...
    nfsc: Key inserted! Disconnecting and reconnecting using new SSH key...
==> nfsc: Machine booted and ready!
==> nfsc: Checking for guest additions in VM...
    nfsc: No guest additions were detected on the base box for this VM! Guest
    nfsc: additions are required for forwarded ports, shared folders, host only
    nfsc: networking, and more. If SSH fails on this machine, please install
    nfsc: the guest additions and repackage the box to continue.
    nfsc:
    nfsc: This is not an error message; everything may continue to work properly,
    nfsc: in which case you may ignore this message.
==> nfsc: Setting hostname...
==> nfsc: Configuring and enabling network interfaces...
==> nfsc: Rsyncing folder: /home/ujack/linuxpro-homework05/ => /vagrant
==> nfsc: Running provisioner: shell...
    nfsc: Running: /tmp/vagrant-shell20220220-91573-se0un.sh
    nfsc: RUN utils install
    nfsc: Loaded plugins: fastestmirror
    nfsc: Determining fastest mirrors
    nfsc:  * base: mirror.reconn.ru
    nfsc:  * extras: mirror.reconn.ru
    nfsc:  * updates: mirror.reconn.ru
    nfsc: Resolving Dependencies
    nfsc: --> Running transaction check
    nfsc: ---> Package nfs-utils.x86_64 1:1.3.0-0.66.el7 will be updated
    nfsc: ---> Package nfs-utils.x86_64 1:1.3.0-0.68.el7.2 will be an update
    nfsc: --> Finished Dependency Resolution
    nfsc:
    nfsc: Dependencies Resolved
    nfsc:
    nfsc: ================================================================================
    nfsc:  Package          Arch          Version                    Repository      Size
    nfsc: ================================================================================
    nfsc: Updating:
    nfsc:  nfs-utils        x86_64        1:1.3.0-0.68.el7.2         updates        413 k
    nfsc:
    nfsc: Transaction Summary
    nfsc: ================================================================================
    nfsc: Upgrade  1 Package
    nfsc:
    nfsc: Total download size: 413 k
    nfsc: Downloading packages:
    nfsc: No Presto metadata available for updates
    nfsc: Public key for nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm is not installed
    nfsc: warning: /var/cache/yum/x86_64/7/updates/packages/nfs-utils-1.3.0-0.68.el7.2.x86_64.rpm: Header V3 RSA/SHA256 Signature, key ID f4a80eb5: NOKEY
    nfsc: Retrieving key from file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfsc: Importing GPG key 0xF4A80EB5:
    nfsc:  Userid     : "CentOS-7 Key (CentOS 7 Official Signing Key) <security@centos.org>"
    nfsc:  Fingerprint: 6341 ab27 53d7 8a78 a7c2 7bb1 24c6 a8a7 f4a8 0eb5
    nfsc:  Package    : centos-release-7-8.2003.0.el7.centos.x86_64 (@anaconda)
    nfsc:  From       : /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7
    nfsc: Running transaction check
    nfsc: Running transaction test
    nfsc: Transaction test succeeded
    nfsc: Running transaction
    nfsc:   Updating   : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfsc:   Cleanup    : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfsc:   Verifying  : 1:nfs-utils-1.3.0-0.68.el7.2.x86_64                          1/2
    nfsc:   Verifying  : 1:nfs-utils-1.3.0-0.66.el7.x86_64                            2/2
    nfsc:
    nfsc: Updated:
    nfsc:   nfs-utils.x86_64 1:1.3.0-0.68.el7.2
    nfsc:
    nfsc: Complete!
    nfsc: RUN firewall step...
    nfsc: Created symlink from /etc/systemd/system/dbus-org.fedoraproject.FirewallD1.service to /usr/lib/systemd/system/firewalld.service.
    nfsc: Created symlink from /etc/systemd/system/multi-user.target.wants/firewalld.service to /usr/lib/systemd/system/firewalld.service.
    nfsc: RUN fstab
    nfsc: RUN configurations / or just need restart

```
Проверяем работоспособность
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant status
Current machine states:

nfss                      running (virtualbox)
nfsc                      running (virtualbox)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfsc
[vagrant@nfsc ~]$ sudo -i
[root@nfsc ~]# ll /mnt/upload/
total 0
[root@nfsc ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[root@nfsc ~]# mount | grep mnt
systemd-1 on /mnt type autofs (rw,relatime,fd=49,pgrp=1,timeout=0,minproto=5,maxproto=5,direct,pipe_ino=26475)
192.168.50.10:/srv/share/ on /mnt type nfs (rw,relatime,vers=3,rsize=32768,wsize=32768,namlen=255,hard,proto=udp,timeo=11,retrans=3,sec=sys,mountaddr=192.168.50.10,mountvers=3,mountport=20048,mountproto=udp,local_lock=none,addr=192.168.50.10)
[root@nfsc ~]# touch /mnt/upload/final_check
[root@nfsc ~]# ll /mnt/upload
total 0
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb 20 15:29 final_check
```
```bash
ujack@ubuntu2004:~/linuxpro-homework05$ vagrant ssh nfss
[vagrant@nfss ~]$ sudo -i
[root@nfss ~]# systemctl status nfs
● nfs-server.service - NFS server and services
   Loaded: loaded (/usr/lib/systemd/system/nfs-server.service; enabled; vendor preset: disabled)
   Active: active (exited) since Sun 2022-02-20 15:27:13 UTC; 5min ago
  Process: 3587 ExecStartPost=/bin/sh -c if systemctl -q is-active gssproxy; then systemctl reload gssproxy ; fi (code=exited, status=0/SUCCESS)
  Process: 3570 ExecStart=/usr/sbin/rpc.nfsd $RPCNFSDARGS (code=exited, status=0/SUCCESS)
  Process: 3569 ExecStartPre=/usr/sbin/exportfs -r (code=exited, status=0/SUCCESS)
 Main PID: 3570 (code=exited, status=0/SUCCESS)
   CGroup: /system.slice/nfs-server.service

Feb 20 15:27:13 nfss systemd[1]: Starting NFS server and services...
Feb 20 15:27:13 nfss systemd[1]: Started NFS server and services.
[root@nfss ~]# exportfs -s
/srv/share  192.168.50.11/32(sync,wdelay,hide,no_subtree_check,sec=sys,rw,secure,root_squash,no_all_squash)
[root@nfss ~]# showmount -a 192.168.50.10
All mount points on 192.168.50.10:
192.168.50.11:/srv/share
[root@nfss ~]# ll /srv/share/
total 0
drwxrwxrwx. 2 nfsnobody nfsnobody 25 Feb 20 15:29 upload
[root@nfss ~]# ll /srv/share/upload/
total 0
-rw-r--r--. 1 nfsnobody nfsnobody 0 Feb 20 15:29 final_check
```
