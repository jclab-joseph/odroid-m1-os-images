#!/bin/bash

old_hostname="$(hostname)"

echo "Current hostname: ${old_hostname}"

read -p "Enter new hostname: " new_hostname

hostnamectl set-hostname "$new_hostname"

sed -i "s/${old_hostname}/$new_hostname/g" /etc/hosts

echo "Hostname has been changed to: $new_hostname"

for name in pvedaemon.service pve-cluster.service pve-firewall.service pve-ha-crm.service pve-ha-lrm.service pve-lxc-syscalld.service pveproxy.service; do
	systemctl enable $name
	systemctl start $name
done

