#!/bin/bash

##################
# I. Global vars #
##################
RED="\e[31m"
GREEN="\e[32m"
NULL="\e[0m"
BACKTITLE="beehive-Installer"

CONF_FILE="/root/installer/iso.conf"

PROGRESSBOXCONF=" --backtitle "$BACKTITLE" --progressbox 24 80"

SITES="https://hub.docker.com https://gitlab.com"

beehiveCOMPOSE="/opt/beehive/etc/beehive.yml"

LSB_STABLE_SUPPORTED="ubuntu"

REMOTESITES="https://hub.docker.com https://gitlab.com"

PREINSTALLPACKAGES="aria2 apache2-utils curl dialog figlet grc libcrack2 libpq-dev lsb-release net-tools software-properties-common toilet"

INSTALLPACKAGES="aria2 apache2-utils apparmor apt-transport-https aufs-tools bash-completion build-essential ca-certificates cgroupfs-mount cockpit cockpit-docker console-setup console-setup-linux curl debconf-utils dialog dnsutils docker.io docker-compose dstat ethtool fail2ban figlet genisoimage git glances grc haveged html2text htop iptables iw jq kbd libcrack2 libltdl7 man mosh multitail net-tools npm ntp openssh-server openssl pass prips software-properties-common syslinux psmisc pv python-pip toilet unattended-upgrades unzip vim wget"


UPDATECHECK="apt-get::Periodic::Update-Package-Lists \"1\";
apt-get::Periodic::Download-Upgradeable-Packages \"0\";
apt-get::Periodic::AutocleanInterval \"7\";
"

SYSCTLCONF="
# Reboot after kernel panic, check via /proc/sys/kernel/panic[_on_oops]
# Set required map count for ELK
kernel.panic = 1
kernel.panic_on_oops = 1
vm.max_map_count = 262144
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
net.ipv6.conf.lo.disable_ipv6 = 1
"

FAIL2BANCONF="[DEFAULT]
ignore-ip = 127.0.0.1/8
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled  = true
filter   = nginx-http-auth
port     = 64297
logpath  = /data/nginx/log/error.log

[pam-generic]
enabled = true
port    = 64294
filter  = pam-generic
logpath = /var/log/auth.log

[sshd]
enabled = true
port    = 64295
filter  = sshd
logpath = /var/log/auth.log
"
SYSTEMDFIX="[Link]
NamePolicy=kernel database onboard slot path
MACAddressPolicy=none
"
COCKPIT_SOCKET="[Socket]
ListenStream=
ListenStream=64294
"
SSHPORT="
Port 64295
"
CRONJOBS="
# Check if updated images are available and download them
27 1 * * *      root    docker-compose -f /opt/beehive/etc/beehive.yml pull

# Delete elasticsearch logstash indices older than 90 days
27 4 * * *      root    curator --config /opt/beehive/etc/curator/curator.yml /opt/beehive/etc/curator/actions.yml

# Uploaded binaries are not supposed to be downloaded
*/1 * * * *     root    mv --backup=numbered /data/dionaea/roots/ftp/* /data/dionaea/binaries/

# Daily reboot
27 3 * * *      root    systemctl stop beehive && docker stop \$(docker ps -aq) || docker rm \$(docker ps -aq) || reboot

# Check for updated packages every sunday, upgrade and reboot
27 16 * * 0     root    apt-get autoclean -y && apt-get autoremove -y && apt-get update -y && apt-get upgrade -y && sleep 10 && reboot
"
ROOTPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;1m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;1m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
USERPROMPT='PS1="\[\033[38;5;8m\][\[$(tput sgr0)\]\[\033[38;5;2m\]\u\[$(tput sgr0)\]\[\033[38;5;6m\]@\[$(tput sgr0)\]\[\033[38;5;4m\]\h\[$(tput sgr0)\]\[\033[38;5;6m\]:\[$(tput sgr0)\]\[\033[38;5;5m\]\w\[$(tput sgr0)\]\[\033[38;5;8m\]]\[$(tput sgr0)\]\[\033[38;5;2m\]\\$\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"'
ROOTCOLORS="export LS_OPTIONS='--color=auto'
eval \"\`dircolors\`\"
alias ls='ls \$LS_OPTIONS'
alias ll='ls \$LS_OPTIONS -l'
alias l='ls \$LS_OPTIONS -lA'"


#################
# II. Functions #
#################

# Create funny words for hostnames
function RANDOMWORD {
  local WORDFILE="$1"
  local LINES=$(cat $WORDFILE | wc -l)
  local RANDOM=$((RANDOM % $LINES))
  local NUM=$((RANDOM * RANDOM % $LINES + 1))
  echo -e -n $(sed -n "$NUM p" $WORDFILE | tr -d \' | tr A-Z a-z)
}

# Do we have root?
function GOT_ROOT {
echo -e
echo -e -n "### Checking for root: "
if [ "$(whoami)" != "root" ];
  then
    echo -e "[ NOT OK ]"
    echo -e "### Please run as root."
    echo -e "### Example: sudo $0"
    exit
  else
    echo -e "${GREEN}✓${NULL} [ ${GREEN} OK ${NULL} ]"
fi
}

# Check for pre-installer package requirements.
# If not present install them
function CHECKPACKAGES {
  export DEBIAN_FRONTEND=noninteractive
  # Make sure dependencies for apt-get are installed
  CURL=$(which curl)
  WGET=$(which wget)
  if [ "$CURL" == "" ] || [ "$WGET" == "" ]
    then
      echo -e "${GREEN}✓${NULL} [ ${GREEN} Installing deps for apt-get ${NULL} ]\n"
      apt-get-get -y update
      apt-get-get -y install curl wget
  fi
  echo -e "${GREEN}✓${NULL} [${GREEN} Checking for installer dependencies: ${NULL}]"
  local PACKAGES="$1"
  for DEPS in $PACKAGES;
    do
      OK=$(dpkg -s $DEPS 2>&1 | grep -w ok | awk '{ print $3 }' | head -n 1)
      if [ "$OK" != "ok" ];
        then
          echo -e "${GREEN}✓${NULL} [${GREEN} Now installing... ${NULL}]"
          apt-get update -y
          apt-get install -y $PACKAGES
          break
      fi
  done
  if [ "$OK" = "ok" ];
    then
      echo -e "${GREEN}✓${NULL} [ ${GREEN} OK ${NULL} ]"
  fi
}

# Check if remote sites are available
function CHECKNET {
  if [ "$beehive_DEPLOYMENT_TYPE" == "iso" ] || [ "$beehive_DEPLOYMENT_TYPE" == "user" ];
    then
      local SITES="$1"
      SITESCOUNT=$(echo -e $SITES | wc -w)
      j=0
      for i in $SITES;
        do
          echo -e $(expr 100 \* $j / $SITESCOUNT) | dialog --title "[ Availability check ]" --backtitle "$BACKTITLE" --gauge "\n  Now checking: $i\n" 8 80
          curl --connect-timeout 30 -IsS $i 2>&1>/dev/null
          if [ $? -ne 0 ];
            then
              dialog --keep-window --backtitle "$BACKTITLE" --title "[ Continue? ]" --yesno "\nAvailability check failed. You can continue, but the installation might fail." 10 50
              if [ $? = 1 ];
                then
                  dialog --keep-window --backtitle "$BACKTITLE" --title "[ Abort ]" --msgbox "\nInstallation aborted. Exiting the installer." 7 50
                  exit
                else
                  break;
              fi;
          fi;
        let j+=1
        echo -e $(expr 100 \* $j / $SITESCOUNT) | dialog --keep-window --title "[ Availability check ]" --backtitle "$BACKTITLE" --gauge "\n  Now checking: $i\n" 8 80
      done;
  fi
}

# Check for other services
function fuCHECK_PORTS {
if [ "$beehive_DEPLOYMENT_TYPE" == "user" ];
  then
    echo -e
    echo -e "### Checking for active services."
    echo -e
    grc netstat -tulpen
    echo -e
    echo -e "### Please review your running services."
    echo -e "### We will take care of SSH (22), but other services i.e. FTP (21), TELNET (23), SMTP (25), HTTP (80), HTTPS (443), etc."
    echo -e "### might collide with beehive's honeypots and prevent beehive from starting successfully."
    echo -e
    echo -e "Sleeping 20 second, then carrying on..."
    sleep 20
    echo -e "Ok lets do this!"
fi
}

############################
# III. Pre-Installer phase #
############################
GOT_ROOT
CHECKPACKAGES "$PREINSTALLPACKAGES"

#####################################
# IV. Prepare installer environment #
#####################################

# Check for Debian release and extract command line arguments
LSB=$(lsb_release -c | awk '{ print $2 }')
if [ "$1" == "" ];
  then
    echo -e "$INFO"
    exit
fi
for i in "$@"
  do
    case $i in
      --conf=*)
        beehive_CONF_FILE="${i#*=}"
        shift
      ;;
      --type=user)
        beehive_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --type=auto)
        beehive_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --type=iso)
        beehive_DEPLOYMENT_TYPE="${i#*=}"
        shift
      ;;
      --help)
        echo -e
  exit
      ;;
      *)
        echo -e "$INFO"
  exit
      ;;
    esac
  done

# Validate command line arguments and load config
# If a valid config file exists, set deployment type to "auto" and load the configuration
if [ "$beehive_DEPLOYMENT_TYPE" == "auto" ] && [ "$beehive_CONF_FILE" == "" ];
  then
    echo -e "Aborting. No configuration file given."
    exit
fi
if [ -s "$beehive_CONF_FILE" ] && [ "$beehive_CONF_FILE" != "" ];
  then
    beehive_DEPLOYMENT_TYPE="auto"
    if [ "$(head -n 1 $beehive_CONF_FILE | grep -c "# beehive")" == "1" ];
      then
        source "$beehive_CONF_FILE"
      else
  echo -e "Aborting. Config file \"$beehive_CONF_FILE\" not a beehive configuration file."
        exit
      fi
  elif ! [ -s "$beehive_CONF_FILE" ] && [ "$beehive_CONF_FILE" != "" ];
    then
      echo -e "Aborting. Config file \"$beehive_CONF_FILE\" not found."
      exit
fi

# Prepare running the installer
echo -e "$INFO" | head -n 3
fuCHECK_PORTS


#######################################
# V. Installer user interaction phase #
#######################################

# Set TERM
export TERM=linux

# If this is a ISO installation we need to wait a few seconds to avoid interference with service messages
if [ "$beehive_DEPLOYMENT_TYPE" == "iso" ];
  then
    sleep 5
    dialog --keep-window --no-ok --no-cancel --backtitle "$BACKTITLE" --title "[ Wait to avoid interference with service messages ]" --pause "" 6 80 7
fi

# Check if remote sites are available
CHECKNET "$REMOTESITES"

# Let' s load the iso config file if there is one
if [ -f $CONF_FILE ];
  then
    dialog --keep-window --backtitle "$BACKTITLE" --title "[ Found personalized iso.config ]" --msgbox "\nYour personalized settings will be applied!" 7 47
    source $CONF_FILE
  else
    # dialog logic considers 1=false, 0=true
    CONF_PROXY_USE="1"
    CONF_PFX_USE="1"
    CONF_NTP_USE="1"
fi

# Let's ask the user for install flavor
if [ "$beehive_DEPLOYMENT_TYPE" == "iso" ] || [ "$beehive_DEPLOYMENT_TYPE" == "user" ];
  then
    CONF_beehive_FLAVOR=$(dialog --keep-window --no-cancel --backtitle "$BACKTITLE" --title "[ Choose Your beehive NG Edition ]" --menu \
    "\nRequired: 6GB RAM, 128GB SSD\nRecommended: 8GB RAM, 256GB SSD" 14 70 6 \
    "STANDARD" "Honeypots, ELK, NSM & Tools" \
    "SENSOR" "Just Honeypots, EWS Poster & NSM" \
    "INDUSTRIAL" "Conpot, RDPY, Vnclowpot, ELK, NSM & Tools" \
    "COLLECTOR" "Heralding, ELK, NSM & Tools" \
    "NEXTGEN" "NextGen (Glutton, HoneyPy)" 3>&1 1>&2 2>&3 3>&-)
fi

# Let's ask for web user credentials if deployment type is iso or user
# In case of auto, credentials are created from config values
# Skip this step entirely if SENSOR flavor
if [ "$beehive_DEPLOYMENT_TYPE" == "iso" ] || [ "$beehive_DEPLOYMENT_TYPE" == "user" ];
  then
    OK="1"
    CONF_WEB_USER="webuser"
    CONF_WEB_PW="pass1"
    CONF_WEB_PW2="pass2"
    SECURE="0"
    while [ 1 != 2 ]
      do
        CONF_WEB_USER=$(dialog --keep-window --backtitle "$BACKTITLE" --title "[ Enter your web user name ]" --inputbox "\n" 9 50 3>&1 1>&2 2>&3 3>&-)
        CONF_WEB_USER=$(echo -e $CONF_WEB_USER | tr -cd "[:alnum:]_.-")
        dialog --keep-window --backtitle "$BACKTITLE" --title "[ Your username is ]" --yesno "\n$CONF_WEB_USER" 7 50
        OK=$?
      if [ "$OK" = "0" ] && [ "$CONF_WEB_USER" != "" ];
        then
          break
      fi
    done
    while [ "$CONF_WEB_PW" != "$CONF_WEB_PW2"  ] && [ "$SECURE" == "0" ]
      do
        while [ "$CONF_WEB_PW" == "pass1"  ] || [ "$CONF_WEB_PW" == "" ]
          do
            CONF_WEB_PW=$(dialog --keep-window --insecure --backtitle "$BACKTITLE" \
                            --title "[ Enter password for your web user ]" \
                            --passwordbox "\nPassword" 9 60 3>&1 1>&2 2>&3 3>&-)
          done
        CONF_WEB_PW2=$(dialog --keep-window --insecure --backtitle "$BACKTITLE" \
                        --title "[ Repeat password for your web user ]" \
                        --passwordbox "\nPassword" 9 60 3>&1 1>&2 2>&3 3>&-)
        if [ "$CONF_WEB_PW" != "$CONF_WEB_PW2" ];
          then
            dialog --keep-window --backtitle "$BACKTITLE" --title "[ Passwords do not match. ]" \
                  --msgbox "\nPlease re-enter your password." 7 60
            CONF_WEB_PW="pass1"
            CONF_WEB_PW2="pass2"
        fi
        SECURE=$(printf "%s" "$CONF_WEB_PW" | cracklib-check | grep -c "OK")
        if [ "$SECURE" == "0" ] && [ "$CONF_WEB_PW" == "$CONF_WEB_PW2" ];
          then
            dialog --keep-window --backtitle "$BACKTITLE" --title "[ Password is not secure ]" --defaultno --yesno "\nKeep insecure password?" 7 50
            OK=$?
            if [ "$OK" == "1" ];
              then
                CONF_WEB_PW="pass1"
                CONF_WEB_PW2="pass2"
            fi
        fi
      done
fi

dialog --clear

##########################
# VI. Installation phase #
##########################

exec 2> >(tee "/install.err")
exec > >(tee "/install.log")

echo -e "${GREEN}✓${NULL}"  "Installing ..."
export DEBIAN_FRONTEND=noninteractive
echo -e "${GREEN}✓${NULL}"  "[ ${GREEN} Getting update information. ${NULL} ]"
echo -e
apt-get -y update
echo -e
echo -e "${GREEN}✓${NULL}"  "[ ${GREEN} Upgrading packages. ${NULL} ]"
echo -e
# Downlaod and upgrade packages, but silently keep existing configs
echo -e "docker.io docker.io/restart       boolean true" | debconf-set-selections -v
echo -e "debconf debconf/frontend select noninteractive" | debconf-set-selections -v
apt-get -y dist-upgrade -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" --force-yes
echo -e
echo -e "${GREEN}✓${NULL}"  "[ ${GREEN} Installing dependencies. ${NULL} ]"
echo -e
apt-get -y install $INSTALLPACKAGES

# Remove exim4
apt-get -y purge exim4-base mailutils
apt-get -y autoremove
apt-mark hold exim4-base mailutils

# If flavor is SENSOR do not write credentials
if ! [ "$CONF_beehive_FLAVOR" == "SENSOR" ];
  then
    echo -e "${GREEN}✓${NULL}"  "Webuser creds"
    mkdir -p /data/nginx/conf
    htpasswd -b -c /data/nginx/conf/nginxpasswd "$CONF_WEB_USER" "$CONF_WEB_PW"
    echo -e
fi

# Let's generate a SSL self-signed certificate without interaction (browsers will see it invalid anyway)
if ! [ "$CONF_beehive_FLAVOR" == "SENSOR" ];
then
  echo -e "${GREEN}✓${NULL}"  "NGINX Certificate"
  mkdir -p /data/nginx/cert
  openssl req \
          -nodes \
          -x509 \
          -sha512 \
          -newkey rsa:8192 \
          -keyout "/data/nginx/cert/nginx.key" \
          -out "/data/nginx/cert/nginx.crt" \
          -days 3650 \
          -subj '/C=AU/ST=Some-State/O=Internet Widgits Pty Ltd'
fi

# Let's setup the ntp server
if [ "$CONF_NTP_USE" == "0" ];
  then
    echo -e "${GREEN}✓${NULL}"  "Setup NTP"
    cp $CONF_NTP_CONF_FILE /etc/ntp.conf
fi

# Let's setup 802.1x networking
if [ "CONF_PFX_USE" == "0" ];
  then
    echo -e "${GREEN}✓${NULL}"  "Setup 802.1x"
    cp $CONF_PFX_FILE /etc/wpa_supplicant/
    echo -e "$NETWORK_INTERFACES" | tee -a /etc/network/interfaces
    echo -e "$NETWORK_WIRED8021x" | tee /etc/wpa_supplicant/wired8021x.conf
    echo -e "$NETWORK_WLAN8021x" | tee /etc/wpa_supplicant/wireless8021x.conf
fi

# Let's provide a wireless example config ...
echo -e "${GREEN}✓${NULL}"  "Example config"
echo -e "$NETWORK_WLANEXAMPLE" | tee -a /etc/network/interfaces

# Let's make sure SSH roaming is turned off (CVE-2016-0777, CVE-2016-0778)
echo -e "${GREEN}✓${NULL}"  "SSH roaming off"
echo -e "UseRoaming no" | tee -a /etc/ssh/ssh_config

# Installing elasticdump, yq
echo -e "${GREEN}✓${NULL}"  "Installing pkgs"
npm install https://github.com/taskrabbit/elasticsearch-dump -g
pip install --upgrade pip
hash -r
pip install elasticsearch-curator yq

# Let's create the beehive user
echo -e "${GREEN}✓${NULL}"  "Create user"
addgroup --gid 2000 beehive
adduser --system --no-create-home --uid 2000 --disabled-password --disabled-login --gid 2000 beehive

# Let's set the hostname
a=$(RANDOMWORD /opt/beehive/host/usr/share/dict/a.txt)
n=$(RANDOMWORD /opt/beehive/host/usr/share/dict/n.txt)
HOST=$a$n
echo -e "${GREEN}✓${NULL}"  "Set hostname"
hostnamectl set-hostname $HOST
sed -i 's#127.0.1.1.*#127.0.1.1\t'"$HOST"'#g' /etc/hosts

# Let's patch cockpit.socket, sshd_config
echo -e "${GREEN}✓${NULL}"  "Adjust ports"
mkdir -p /etc/systemd/system/cockpit.socket.d
echo -e "$COCKPIT_SOCKET" | tee /etc/systemd/system/cockpit.socket.d/listen.conf
sed -i '/^port/Id' /etc/ssh/sshd_config
echo -e "$SSHPORT" | tee -a /etc/ssh/sshd_config

# Do not allow root login for cockpit
sed -i '2i\auth requisite pam_succeed_if.so uid >= 1000' /etc/pam.d/cockpit

# Let's make sure only CONF_beehive_FLAVOR images will be downloaded and started
case $CONF_beehive_FLAVOR in
  STANDARD)
    echo -e "${GREEN}✓${NULL}"  "STANDARD"
    ln -s /opt/beehive/etc/compose/standard.yml $beehiveCOMPOSE
  ;;
esac

# Let's load docker images in parallel
function PULLIMAGES {
for name in $(cat $beehiveCOMPOSE | grep -v '#' | grep image | cut -d'"' -f2 | uniq)
  do
    docker pull $name &
done
wait
}
echo -e "${GREEN}✓${NULL}"  "Pull images"
PULLIMAGES

# Let's add the daily update check with a weekly clean interval
echo -e "${GREEN}✓${NULL}"  "Modify checks"
echo -e "$UPDATECHECK" | tee /etc/apt-get/apt-get.conf.d/10periodic

# Let's make sure to reboot the system after a kernel panic
echo -e "${GREEN}✓${NULL}"  "Tweak sysctl"
echo -e "$SYSCTLCONF" | tee -a /etc/sysctl.conf

# Let's setup fail2ban config
echo -e "${GREEN}✓${NULL}"  "Setup fail2ban"
echo -e "$FAIL2BANCONF" | tee /etc/fail2ban/jail.d/beehive.conf

# Fix systemd error https://github.com/systemd/systemd/issues/3374
echo -e "${GREEN}✓${NULL}"  "Systemd fix"
echo -e "$SYSTEMDFIX" | tee /etc/systemd/network/99-default.link

# Let's add some cronjobs
echo -e "${GREEN}✓${NULL}"  "Add cronjobs"
echo -e "$CRONJOBS" | tee -a /etc/crontab

# Let's create some files and folders
echo -e "${GREEN}✓${NULL}"  "Files & folders"
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
        /data/honeypy/log \
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
touch /data/spiderfoot/spiderfoot.db
touch /data/nginx/log/error.log

# Let's copy some files
echo -e "${GREEN}✓${NULL}"  "Copy configs"
tar xvfz /opt/beehive/etc/objects/elkbase.tgz -C /
cp /opt/beehive/host/etc/systemd/* /etc/systemd/system/
systemctl enable beehive

# Let's take care of some files and permissions
echo -e "${GREEN}✓${NULL}"  "Permissions"
chmod 760 -R /data
chown beehive:beehive -R /data
chmod 644 -R /data/nginx/conf
chmod 644 -R /data/nginx/cert

# Let's replace "quiet splash" options, set a console font for more screen canvas and update grub
echo -e "${GREEN}✓${NULL}"  "Options"
sed -i 's#GRUB_CMDLINE_LINUX_DEFAULT="quiet"#GRUB_CMDLINE_LINUX_DEFAULT="quiet consoleblank=0"#' /etc/default/grub
sed -i 's#GRUB_CMDLINE_LINUX=""#GRUB_CMDLINE_LINUX="cgroup_enable=memory swapaccount=1"#' /etc/default/grub
update-grub

# Let's enable a color prompt and add /opt/beehive/bin to path
echo -e "${GREEN}✓${NULL}"  "Setup prompt"
tee -a /root/.bashrc <<EOF
$ROOTPROMPT
$ROOTCOLORS
PATH="$PATH:/opt/beehive/bin"
EOF
for i in $(ls -d /home/*/)
  do
tee -a $i.bashrc <<EOF
$USERPROMPT
PATH="$PATH:/opt/beehive/bin"
EOF
done

# Let's create ews.ip before reboot and prevent race condition for first start
echo -e "${GREEN}✓${NULL}"  "Update IP"
/opt/beehive/bin/updateip.sh

# Let's clean up apt-get
echo -e "${GREEN}✓${NULL}"  "Clean up"
apt-get autoclean -y
apt-get autoremove -y

# Final steps
cp /opt/beehive/host/etc/rc.local /etc/rc.local && \
rm -rf /root/installer && \
rm -rf /etc/issue.d/cockpit.issue && \
rm -rf /etc/motd.d/cockpit && \
rm -rf /etc/issue.net && \
rm -rf /etc/motd && \
systemctl restart console-setup.service

if [ "$beehive_DEPLOYMENT_TYPE" == "auto" ];
  then
    echo -e "Done. Please reboot."
  else
    echo -e "${GREEN}✓${NULL}"  "Rebooting ..."
    sleep 2
    reboot
fi
