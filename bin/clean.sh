#!/bin/bash
# T-Pot Container Data Cleaner & Log Rotator

# Set colors
RED="[0;31m"
GREEN="[0;32m"
WHITE="[0;0m"

# Set persistence
PERSISTENCE=$1

# Let's create a nction to check if folder is empty
EMPTY() {
  local FOLDER=$1

  echo $(ls $FOLDER | wc -l)
}

# Let's create a nction to rotate and compress logs
LOGROTATE() {
  local STATUS="/opt/beehive/etc/logrotate/status"
  local CONF="/opt/beehive/etc/logrotate/logrotate.conf"
  local ADBHONEYTGZ="/data/adbhoney/downloads.tgz"
  local ADBHONEYDL="/data/adbhoney/downloads/"
  local COWRIETTYLOGS="/data/cowrie/log/tty/"
  local COWRIETTYTGZ="/data/cowrie/log/ttylogs.tgz"
  local COWRIEDL="/data/cowrie/downloads/"
  local COWRIEDLTGZ="/data/cowrie/downloads.tgz"
  local DIONAEABI="/data/dionaea/bistreams/"
  local DIONAEABITGZ="/data/dionaea/bistreams.tgz"
  local DIONAEABIN="/data/dionaea/binaries/"
  local DIONAEABINTGZ="/data/dionaea/binaries.tgz"
  local HONEYTRAPATTACKS="/data/honeytrap/attacks/"
  local HONEYTRAPATTACKSTGZ="/data/honeytrap/attacks.tgz"
  local HONEYTRAPDL="/data/honeytrap/downloads/"
  local HONEYTRAPDLTGZ="/data/honeytrap/downloads.tgz"
  local TANNERF="/data/tanner/files/"
  local TANNERFTGZ="/data/tanner/files.tgz"

  # Ensure correct permissions and ownerships for logrotate to run without issues
  chmod 760 /data/ -R
  chown beehive:beehive /data -R
  chmod 644 /data/nginx/conf -R
  chmod 644 /data/nginx/cert -R

  # Run logrotate with force (-f) first, so the status file can be written and race conditions (with tar) be avoided
  logrotate -f -s $STATUS $CONF

  # Compressing some folders first and rotate them later
  if [ "$(EMPTY $ADBHONEYDL)" != "0" ]; then tar cvfz $ADBHONEYTGZ $ADBHONEYDL; fi
  if [ "$(EMPTY $COWRIETTYLOGS)" != "0" ]; then tar cvfz $COWRIETTYTGZ $COWRIETTYLOGS; fi
  if [ "$(EMPTY $COWRIEDL)" != "0" ]; then tar cvfz $COWRIEDLTGZ $COWRIEDL; fi
  if [ "$(EMPTY $DIONAEABI)" != "0" ]; then tar cvfz $DIONAEABITGZ $DIONAEABI; fi
  if [ "$(EMPTY $DIONAEABIN)" != "0" ]; then tar cvfz $DIONAEABINTGZ $DIONAEABIN; fi
  if [ "$(EMPTY $HONEYTRAPATTACKS)" != "0" ]; then tar cvfz $HONEYTRAPATTACKSTGZ $HONEYTRAPATTACKS; fi
  if [ "$(EMPTY $HONEYTRAPDL)" != "0" ]; then tar cvfz $HONEYTRAPDLTGZ $HONEYTRAPDL; fi
  if [ "$(EMPTY $TANNERF)" != "0" ]; then tar cvfz $TANNERFTGZ $TANNERF; fi

  # Ensure correct permissions and ownership for previously created archives
  chmod 760 $ADBHONEYTGZ $COWRIETTYTGZ $COWRIEDLTGZ $DIONAEABITGZ $DIONAEABINTGZ $HONEYTRAPATTACKSTGZ $HONEYTRAPDLTGZ $TANNERFTGZ
  chown beehive:beehive $ADBHONEYTGZ $COWRIETTYTGZ $COWRIEDLTGZ $DIONAEABITGZ $DIONAEABINTGZ $HONEYTRAPATTACKSTGZ $HONEYTRAPDLTGZ $TANNERFTGZ

  # Need to remove subfolders since too many files cause rm to exit with errors
  rm -rf $ADBHONEYDL $COWRIETTYLOGS $COWRIEDL $DIONAEABI $DIONAEABIN $HONEYTRAPATTACKS $HONEYTRAPDL $TANNERF

  # Recreate subfolders with correct permissions and ownership
  mkdir -p $ADBHONEYDL $COWRIETTYLOGS $COWRIEDL $DIONAEABI $DIONAEABIN $HONEYTRAPATTACKS $HONEYTRAPDL $TANNERF
  chmod 760 $ADBHONEYDL $COWRIETTYLOGS $COWRIEDL $DIONAEABI $DIONAEABIN $HONEYTRAPATTACKS $HONEYTRAPDL $TANNERF
  chown beehive:beehive $ADBHONEYDL $COWRIETTYLOGS $COWRIEDL $DIONAEABI $DIONAEABIN $HONEYTRAPATTACKS $HONEYTRAPDL $TANNERF

  # Run logrotate again to account for previously created archives - DO NOT FORCE HERE!
  logrotate -s $STATUS $CONF
}

# Let's create a nction to clean up and prepare honeytrap data
ADBHONEY() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/adbhoney/*; fi
  mkdir -p /data/adbhoney/log/ /data/adbhoney/downloads/
  chmod 760 /data/adbhoney/ -R
  chown beehive:beehive /data/adbhoney/ -R
}

# Let's create a nction to clean up and prepare ciscoasa data
CISCOASA() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/ciscoasa/*; fi
  mkdir -p /data/ciscoasa/log
  chmod 760 /data/ciscoasa -R
  chown beehive:beehive /data/ciscoasa -R
}

# Let's create a nction to clean up and prepare conpot data
CONPOT() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/conpot/*; fi
  mkdir -p /data/conpot/log
  chmod 760 /data/conpot -R
  chown beehive:beehive /data/conpot -R
}

# Let's create a nction to clean up and prepare cowrie data
COWRIE() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/cowrie/*; fi
  mkdir -p /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/
  chmod 760 /data/cowrie -R
  chown beehive:beehive /data/cowrie -R
}

# Let's create a nction to clean up and prepare dionaea data
DIONAEA() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/dionaea/*; fi
  mkdir -p /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/roots/ftp /data/dionaea/roots/tftp /data/dionaea/roots/www /data/dionaea/roots/upnp
  chmod 760 /data/dionaea -R
  chown beehive:beehive /data/dionaea -R
}

# Let's create a nction to clean up and prepare elasticpot data
ELASTICPOT() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/elasticpot/*; fi
  mkdir -p /data/elasticpot/log
  chmod 760 /data/elasticpot -R
  chown beehive:beehive /data/elasticpot -R
}

# Let's create a nction to clean up and prepare elk data
ELK() {
  # ELK data will be kept for <= 90 days, check /etc/crontab for curator modification
  # ELK daemon log files will be removed
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/elk/log/*; fi
  mkdir -p /data/elk
  chmod 760 /data/elk -R
  chown beehive:beehive /data/elk -R
}

# Let's create a nction to clean up and prepare glastopf data
GLASTOPF() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/glastopf/*; fi
  mkdir -p /data/glastopf/db /data/glastopf/log
  chmod 760 /data/glastopf -R
  chown beehive:beehive /data/glastopf -R
}

# Let's create a nction to clean up and prepare glastopf data
GLUTTON() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/glutton/*; fi
  mkdir -p /data/glutton/log
  chmod 760 /data/glutton -R
  chown beehive:beehive /data/glutton -R
}

# Let's create a nction to clean up and prepare heralding data
HERALDING() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/heralding/*; fi
  mkdir -p /data/heralding/log
  chmod 760 /data/heralding -R
  chown beehive:beehive /data/heralding -R
}

# Let's create a nction to clean up and prepare honeytrap data
HONEYTRAP() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/honeytrap/*; fi
  mkdir -p /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/
  chmod 760 /data/honeytrap/ -R
  chown beehive:beehive /data/honeytrap/ -R
}

# Let's create a nction to clean up and prepare mailoney data
MAILONEY() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/mailoney/*; fi
  mkdir -p /data/mailoney/log/
  chmod 760 /data/mailoney/ -R
  chown beehive:beehive /data/mailoney/ -R
}

# Let's create a nction to clean up and prepare mailoney data
MEDPOT() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/medpot/*; fi
  mkdir -p /data/medpot/log/
  chmod 760 /data/medpot/ -R
  chown beehive:beehive /data/medpot/ -R
}

# Let's create a nction to clean up nginx logs
NGINX() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/nginx/log/*; fi
  touch /data/nginx/log/error.log
  chmod 644 /data/nginx/conf -R
  chmod 644 /data/nginx/cert -R
}

# Let's create a nction to clean up and prepare rdpy data
RDPY() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/rdpy/*; fi
  mkdir -p /data/rdpy/log/
  chmod 760 /data/rdpy/ -R
  chown beehive:beehive /data/rdpy/ -R
}

# Let's create a nction to prepare spiderfoot db
SPIDERFOOT() {
  mkdir -p /data/spiderfoot
  touch /data/spiderfoot/spiderfoot.db
  chmod 760 -R /data/spiderfoot
  chown beehive:beehive -R /data/spiderfoot
}

# Let's create a nction to clean up and prepare suricata data
SURICATA() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/suricata/*; fi
  mkdir -p /data/suricata/log
  chmod 760 -R /data/suricata
  chown beehive:beehive -R /data/suricata
}

# Let's create a nction to clean up and prepare p0f data
P0F() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/p0f/*; fi
  mkdir -p /data/p0f/log
  chmod 760 -R /data/p0f
  chown beehive:beehive -R /data/p0f
}

# Let's create a nction to clean up and prepare p0f data
TANNER() {
  if [ "$PERSISTENCE" != "on" ]; then rm -rf /data/tanner/*; fi
  mkdir -p /data/tanner/log /data/tanner/files
  chmod 760 -R /data/tanner
  chown beehive:beehive -R /data/tanner
}

# Avoid unwanted cleaning
if [ "$PERSISTENCE" = "" ]; then
  echo $RED"!!! WARNING !!! - This will delete ALL honeypot logs. "$WHITE
  while [ "$QST" != "y" ] && [ "$QST" != "n" ]; do
    read -p "Continue? (y/n) " QST
  done
  if [ "$QST" = "n" ]; then
    echo $GREEN"Puuh! That was close! Aborting!"$WHITE
    exit
  fi
fi

# Check persistence, if enabled compress and rotate logs
if [ "$PERSISTENCE" = "on" ]; then
  echo "Persistence enabled, now rotating and compressing logs."
  LOGROTATE
else
  echo "Cleaning up and preparing data folders."
  ADBHONEY
  CISCOASA
  CONPOT
  COWRIE
  DIONAEA
  ELASTICPOT
  ELK
  GLASTOPF
  GLUTTON
  HERALDING
  HONEYTRAP
  MAILONEY
  MEDPOT
  NGINX
  RDPY
  SPIDERFOOT
  SURICATA
  P0F
  TANNER
fi
