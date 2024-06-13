#!/bin/bash

old_hostname="$(hostname)"
ip_address=$(ip addr show vmbr0 | grep 'inet ' | awk '{print $2}' | cut -d'/' -f1)

echo "Current hostname  : ${old_hostname}"
echo "Current IP address: ${ip_address}"
echo ""

read -p "Enter new hostname: " new_hostname

hostnamectl set-hostname "$new_hostname"

cat <<EOF | tee /etc/hosts
127.0.0.1	localhost.localdomain localhost
${ip_address}	${new_hostname}.lan ${new_hostname}
EOF

echo "Hostname has been changed to: $new_hostname"

service_names="pve-cluster.service pve-firewall.service pve-guests.service pve-ha-crm.service pve-ha-lrm.service pvedaemon.service pvefw-logger.service pveproxy.service pvescheduler.service pvestatd.service"

for name in ${service_names}; do
	systemctl enable $name
done

for name in ${service_names}; do
	systemctl start $name
done

echo "Rebooting..."
reboot

