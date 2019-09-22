#!/bin/bash

# Some global vars
CONFIGFILE="/opt/beehive/etc/beehive.yml"
COMPOSEPATH="/opt/beehive/etc/compose"
RED="[0;31m"
GREEN="[0;32m"
WHITE="[0;0m"
BLUE="[0;34m"


# Check for existing beehive.yml
function fuCONFIGCHECK () {
  echo "### Checking for beehive configuration file ..."
  echo -n "###### $BLUE$CONFIGFILE$WHITE "
  if ! [ -f $CONFIGFILE ];
    then
      echo
      echo "[ $RED""NOT OK""$WHITE ] - No beehive configuration found."
      echo "Please create a link to your desired config i.e. 'ln -s /opt/beehive/etc/compose/standard.yml /opt/beehive/etc/beehive.yml'."
      echo
      exit 1
    else
      echo "[ $GREEN""OK""$WHITE ]"
  fi
echo
}

# Let's test the internet connection
function fuCHECKINET () {
SITES=$1
  echo "### Now checking availability of ..."
  for i in $SITES;
    do
      echo -n "###### $BLUE$i$WHITE "
      curl --connect-timeout 5 -IsS $i 2>&1>/dev/null
        if [ $? -ne 0 ];
          then
	    echo
            echo "###### $BLUE""Error - Internet connection test failed.""$WHITE"" [ $RED""NOT OK""$WHITE ]"
            echo "Exiting.""$WHITE"
            echo
            exit 1
          else
            echo "[ $GREEN"OK"$WHITE ]"
        fi
  done;
echo
}

# Update
function fuSELFUPDATE () {
  echo "### Now checking for newer files in repository ..."
  git fetch --all
  REMOTESTAT=$(git status | grep -c "up-to-date")
  if [ "$REMOTESTAT" != "0" ];
    then
      echo "###### $BLUE""No updates found in repository.""$WHITE"
      return
  fi
  RESULT=$(git diff --name-only origin/master | grep update.sh)
  if [ "$RESULT" == "update.sh" ];
    then
      echo "###### $BLUE""Found newer version, will be pulling updates and restart self.""$WHITE"
      git reset --hard
      git pull --force
      exec "$1" "$2"
      exit 1
    else
      echo "###### $BLUE""Pulling updates from repository.""$WHITE"
      git reset --hard
      git pull --force
  fi
echo
}

# Stop beehive to avoid race conditions with running containers with regard to the current beehive config
function fuSTOP_beehive () {
echo "### Need to stop beehive ..."
echo -n "###### $BLUE Now stopping beehive.$WHITE "
systemctl stop beehive
if [ $? -ne 0 ];
  then
    echo " [ $RED""NOT OK""$WHITE ]"
    echo "###### $BLUE""Could not stop beehive.""$WHITE"" [ $RED""NOT OK""$WHITE ]"
    echo "Exiting.""$WHITE"
    echo
    exit 1
  else
    echo "[ $GREEN"OK"$WHITE ]"
    echo "###### $BLUE Now cleaning up containers.$WHITE "
    if [ "$(docker ps -aq)" != "" ];
      then
        docker stop $(docker ps -aq)
        docker rm $(docker ps -aq)
    fi
fi
echo
}

# Let's load docker images in parallel
function fuPULLIMAGES {
local beehiveCOMPOSE="/opt/beehive/etc/beehive.yml"
for name in $(cat $beehiveCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2 | uniq)
  do
    docker pull $name &
  done
wait
echo
}

function fuUPDATER () {
local PACKAGES="apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount cockpit cockpit-docker curl debconf-utils dialog dnsutils docker.io docker-compose dstat ethtool fail2ban genisoimage git glances grc html2text htop iptables iw jq libcrack2 libltdl7 lm-sensors man mosh multitail net-tools npm ntp openssh-server openssl pass prips software-properties-common syslinux psmisc pv python-pip unattended-upgrades unzip vim wireless-tools wpasupplicant"
echo "### Now upgrading packages ..."
dpkg --configure -a
apt-get -y autoclean
apt-get -y autoremove
apt-get update
apt-get -y install $PACKAGES

# Some updates require interactive attention, and the following settings will override that.
echo "docker.io docker.io/restart       boolean true" | debconf-set-selections -v
echo "debconf debconf/frontend select noninteractive" | debconf-set-selections -v
apt-get -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
dpkg --configure -a
npm install "https://github.com/taskrabbit/elasticsearch-dump" -g
pip install --upgrade pip
hash -r
pip install --upgrade elasticsearch-curator yq
wget https://github.com/bcicen/ctop/releases/download/v0.7.1/ctop-0.7.1-linux-amd64 -O /usr/bin/ctop && chmod +x /usr/bin/ctop
echo

echo "### Now replacing beehive related config files on host"
cp host/etc/systemd/* /etc/systemd/system/
cp host/etc/issue /etc/
systemctl daemon-reload
echo

# Ensure some defaults
echo "### Ensure some beehive defaults with regard to some folders, permissions and configs."
sed -i 's#ListenStream=9090#ListenStream=64294#' /lib/systemd/system/cockpit.socket
sed -i '/^port/Id' /etc/ssh/sshd_config
echo "Port 64295" >> /etc/ssh/sshd_config
echo

### Ensure creation of beehive related folders, just in case
mkdir -p /data/adbhoney/downloads /data/adbhoney/log \
         /data/ciscoasa/log \
         /data/conpot/log \
         /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/ \
         /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/roots/ftp /data/dionaea/roots/tftp /data/dionaea/roots/www /data/dionaea/roots/upnp \
         /data/elasticpot/log \
         /data/elk/data /data/elk/log \
         /data/glastopf/log /data/glastopf/db \
         /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/ \
         /data/glutton/log \
         /data/heralding/log \
         /data/mailoney/log \
         /data/medpot/log \
         /data/nginx/log \
         /data/emobility/log \
         /data/ews/conf \
         /data/rdpy/log \
         /data/spiderfoot \
         /data/suricata/log /home/tsec/.ssh/ \
         /data/tanner/log /data/tanner/files \
         /data/p0f/log

### Let's take care of some files and permissions
chmod 760 -R /data
chown beehive:beehive -R /data
chmod 644 -R /data/nginx/conf
chmod 644 -R /data/nginx/cert

echo "### Now pulling latest docker images"
echo "######$BLUE This might take a while, please be patient!$WHITE"
fuPULLIMAGES 2>&1>/dev/null

fuREMOVEOLDIMAGES "1804"
echo "### If you made changes to beehive.yml please ensure to add them again."
echo "### We stored the previous version as backup in /root/."
echo "### Done, please reboot."
echo
}


################
# Main section #
################

# Got root?
WHOAMI=$(whoami)
if [ "$WHOAMI" != "root" ]
  then
    echo "Need to run as root ..."
    sudo ./$0
    exit
fi

# Only run with command switch
if [ "$1" != "-y" ]; then
  echo "This script will update / upgrade all beehive related scripts, tools and packages to the latest versions."
  echo "A backup of /opt/beehive will be written to /root. If you are unsure, you should save your work."
  echo "This is a beta feature and only recommended for experienced users."
  echo "If you understand the involved risks feel free to run this script with the '-y' switch."
  echo
  exit
fi

fuCHECK_VERSION
fuCONFIGCHECK
fuCHECKINET "https://index.docker.io https://github.com"
fuSTOP_beehive
fuBACKUP
fuSELFUPDATE "$0" "$@"
fuUPDATER
