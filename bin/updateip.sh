#!/bin/bash
# Let's add the first local ip to the /etc/issue and external ip to ews.ip file
# If the external IP cannot be detected, the internal IP will be inherited.
source /etc/environment
LOCALIP=$(hostname -I | awk '{ print $1 }')
EXTIP=$(/opt/beehive/bin/ip.sh)
if [ "$EXTIP" = "" ]; then
  EXTIP=$LOCALIP
fi
SSHUSER=$(cat /etc/passwd | grep 1000 | cut -d ':' -f1)
sed -i "s#IP:.*#IP: $LOCALIP ($EXTIP)[0m#" /etc/issue
sed -i "s#SSH:.*#SSH: ssh -l tsec -p 64295 $LOCALIP[0m#" /etc/issue
sed -i "s#WEB:.*#WEB: https://$LOCALIP:64297[0m#" /etc/issue
sed -i "s#ADMIN:.*#ADMIN: https://$LOCALIP:64294[0m#" /etc/issue
tee /data/ews/conf/ews.ip <<EOF
[MAIN]
ip = $EXTIP
EOF
tee /opt/beehive/etc/compose/elk_environment <<EOF
EXTIP=$EXTIP
INTIP=$LOCALIP
HOSTNAME=$HOSTNAME
EOF
chown beehive:beehive /data/ews/conf/ews.ip
chmod 760 /data/ews/conf/ews.ip
