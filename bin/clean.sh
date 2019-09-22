#!/bin/bash
# T-Pot Container Data Cleaner & Log Rotator

# Set colors
myRED="[0;31m"
myGREEN="[0;32m"
myWHITE="[0;0m"

# Set persistence
myPERSISTENCE=$1

# Let's create a function to check if folder is empty
fuEMPTY() {
  local myFOLDER=$1

  echo $(ls $myFOLDER | wc -l)
}

# Let's create a function to rotate and compress logs
fuLOGROTATE() {
  local mySTATUS="/opt/beehive/etc/logrotate/status"
  local myCONF="/opt/beehive/etc/logrotate/logrotate.conf"
  local myADBHONEYTGZ="/data/adbhoney/downloads.tgz"
  local myADBHONEYDL="/data/adbhoney/downloads/"
  local myCOWRIETTYLOGS="/data/cowrie/log/tty/"
  local myCOWRIETTYTGZ="/data/cowrie/log/ttylogs.tgz"
  local myCOWRIEDL="/data/cowrie/downloads/"
  local myCOWRIEDLTGZ="/data/cowrie/downloads.tgz"
  local myDIONAEABI="/data/dionaea/bistreams/"
  local myDIONAEABITGZ="/data/dionaea/bistreams.tgz"
  local myDIONAEABIN="/data/dionaea/binaries/"
  local myDIONAEABINTGZ="/data/dionaea/binaries.tgz"
  local myHONEYTRAPATTACKS="/data/honeytrap/attacks/"
  local myHONEYTRAPATTACKSTGZ="/data/honeytrap/attacks.tgz"
  local myHONEYTRAPDL="/data/honeytrap/downloads/"
  local myHONEYTRAPDLTGZ="/data/honeytrap/downloads.tgz"
  local myTANNERF="/data/tanner/files/"
  local myTANNERFTGZ="/data/tanner/files.tgz"

  # Ensure correct permissions and ownerships for logrotate to run without issues
  chmod 760 /data/ -R
  chown beehive:beehive /data -R
  chmod 644 /data/nginx/conf -R
  chmod 644 /data/nginx/cert -R

  # Run logrotate with force (-f) first, so the status file can be written and race conditions (with tar) be avoided
  logrotate -f -s $mySTATUS $myCONF

  # Compressing some folders first and rotate them later
  if [ "$(fuEMPTY $myADBHONEYDL)" != "0" ]; then tar cvfz $myADBHONEYTGZ $myADBHONEYDL; fi
  if [ "$(fuEMPTY $myCOWRIETTYLOGS)" != "0" ]; then tar cvfz $myCOWRIETTYTGZ $myCOWRIETTYLOGS; fi
  if [ "$(fuEMPTY $myCOWRIEDL)" != "0" ]; then tar cvfz $myCOWRIEDLTGZ $myCOWRIEDL; fi
  if [ "$(fuEMPTY $myDIONAEABI)" != "0" ]; then tar cvfz $myDIONAEABITGZ $myDIONAEABI; fi
  if [ "$(fuEMPTY $myDIONAEABIN)" != "0" ]; then tar cvfz $myDIONAEABINTGZ $myDIONAEABIN; fi
  if [ "$(fuEMPTY $myHONEYTRAPATTACKS)" != "0" ]; then tar cvfz $myHONEYTRAPATTACKSTGZ $myHONEYTRAPATTACKS; fi
  if [ "$(fuEMPTY $myHONEYTRAPDL)" != "0" ]; then tar cvfz $myHONEYTRAPDLTGZ $myHONEYTRAPDL; fi
  if [ "$(fuEMPTY $myTANNERF)" != "0" ]; then tar cvfz $myTANNERFTGZ $myTANNERF; fi

  # Ensure correct permissions and ownership for previously created archives
  chmod 760 $myADBHONEYTGZ $myCOWRIETTYTGZ $myCOWRIEDLTGZ $myDIONAEABITGZ $myDIONAEABINTGZ $myHONEYTRAPATTACKSTGZ $myHONEYTRAPDLTGZ $myTANNERFTGZ
  chown beehive:beehive $myADBHONEYTGZ $myCOWRIETTYTGZ $myCOWRIEDLTGZ $myDIONAEABITGZ $myDIONAEABINTGZ $myHONEYTRAPATTACKSTGZ $myHONEYTRAPDLTGZ $myTANNERFTGZ

  # Need to remove subfolders since too many files cause rm to exit with errors
  rm -rf $myADBHONEYDL $myCOWRIETTYLOGS $myCOWRIEDL $myDIONAEABI $myDIONAEABIN $myHONEYTRAPATTACKS $myHONEYTRAPDL $myTANNERF

  # Recreate subfolders with correct permissions and ownership
  mkdir -p $myADBHONEYDL $myCOWRIETTYLOGS $myCOWRIEDL $myDIONAEABI $myDIONAEABIN $myHONEYTRAPATTACKS $myHONEYTRAPDL $myTANNERF
  chmod 760 $myADBHONEYDL $myCOWRIETTYLOGS $myCOWRIEDL $myDIONAEABI $myDIONAEABIN $myHONEYTRAPATTACKS $myHONEYTRAPDL $myTANNERF
  chown beehive:beehive $myADBHONEYDL $myCOWRIETTYLOGS $myCOWRIEDL $myDIONAEABI $myDIONAEABIN $myHONEYTRAPATTACKS $myHONEYTRAPDL $myTANNERF

  # Run logrotate again to account for previously created archives - DO NOT FORCE HERE!
  logrotate -s $mySTATUS $myCONF
}

# Let's create a function to clean up and prepare honeytrap data
fuADBHONEY() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/adbhoney/*; fi
  mkdir -p /data/adbhoney/log/ /data/adbhoney/downloads/
  chmod 760 /data/adbhoney/ -R
  chown beehive:beehive /data/adbhoney/ -R
}

# Let's create a function to clean up and prepare ciscoasa data
fuCISCOASA() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/ciscoasa/*; fi
  mkdir -p /data/ciscoasa/log
  chmod 760 /data/ciscoasa -R
  chown beehive:beehive /data/ciscoasa -R
}

# Let's create a function to clean up and prepare conpot data
fuCONPOT() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/conpot/*; fi
  mkdir -p /data/conpot/log
  chmod 760 /data/conpot -R
  chown beehive:beehive /data/conpot -R
}

# Let's create a function to clean up and prepare cowrie data
fuCOWRIE() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/cowrie/*; fi
  mkdir -p /data/cowrie/log/tty/ /data/cowrie/downloads/ /data/cowrie/keys/ /data/cowrie/misc/
  chmod 760 /data/cowrie -R
  chown beehive:beehive /data/cowrie -R
}

# Let's create a function to clean up and prepare dionaea data
fuDIONAEA() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/dionaea/*; fi
  mkdir -p /data/dionaea/log /data/dionaea/bistreams /data/dionaea/binaries /data/dionaea/rtp /data/dionaea/roots/ftp /data/dionaea/roots/tftp /data/dionaea/roots/www /data/dionaea/roots/upnp
  chmod 760 /data/dionaea -R
  chown beehive:beehive /data/dionaea -R
}

# Let's create a function to clean up and prepare elasticpot data
fuELASTICPOT() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/elasticpot/*; fi
  mkdir -p /data/elasticpot/log
  chmod 760 /data/elasticpot -R
  chown beehive:beehive /data/elasticpot -R
}

# Let's create a function to clean up and prepare elk data
fuELK() {
  # ELK data will be kept for <= 90 days, check /etc/crontab for curator modification
  # ELK daemon log files will be removed
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/elk/log/*; fi
  mkdir -p /data/elk
  chmod 760 /data/elk -R
  chown beehive:beehive /data/elk -R
}

# Let's create a function to clean up and prepare glastopf data
fuGLASTOPF() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/glastopf/*; fi
  mkdir -p /data/glastopf/db /data/glastopf/log
  chmod 760 /data/glastopf -R
  chown beehive:beehive /data/glastopf -R
}

# Let's create a function to clean up and prepare glastopf data
fuGLUTTON() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/glutton/*; fi
  mkdir -p /data/glutton/log
  chmod 760 /data/glutton -R
  chown beehive:beehive /data/glutton -R
}

# Let's create a function to clean up and prepare heralding data
fuHERALDING() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/heralding/*; fi
  mkdir -p /data/heralding/log
  chmod 760 /data/heralding -R
  chown beehive:beehive /data/heralding -R
}

# Let's create a function to clean up and prepare honeytrap data
fuHONEYTRAP() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/honeytrap/*; fi
  mkdir -p /data/honeytrap/log/ /data/honeytrap/attacks/ /data/honeytrap/downloads/
  chmod 760 /data/honeytrap/ -R
  chown beehive:beehive /data/honeytrap/ -R
}

# Let's create a function to clean up and prepare mailoney data
fuMAILONEY() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/mailoney/*; fi
  mkdir -p /data/mailoney/log/
  chmod 760 /data/mailoney/ -R
  chown beehive:beehive /data/mailoney/ -R
}

# Let's create a function to clean up and prepare mailoney data
fuMEDPOT() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/medpot/*; fi
  mkdir -p /data/medpot/log/
  chmod 760 /data/medpot/ -R
  chown beehive:beehive /data/medpot/ -R
}

# Let's create a function to clean up nginx logs
fuNGINX() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/nginx/log/*; fi
  touch /data/nginx/log/error.log
  chmod 644 /data/nginx/conf -R
  chmod 644 /data/nginx/cert -R
}

# Let's create a function to clean up and prepare rdpy data
fuRDPY() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/rdpy/*; fi
  mkdir -p /data/rdpy/log/
  chmod 760 /data/rdpy/ -R
  chown beehive:beehive /data/rdpy/ -R
}

# Let's create a function to prepare spiderfoot db
fuSPIDERFOOT() {
  mkdir -p /data/spiderfoot
  touch /data/spiderfoot/spiderfoot.db
  chmod 760 -R /data/spiderfoot
  chown beehive:beehive -R /data/spiderfoot
}

# Let's create a function to clean up and prepare suricata data
fuSURICATA() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/suricata/*; fi
  mkdir -p /data/suricata/log
  chmod 760 -R /data/suricata
  chown beehive:beehive -R /data/suricata
}

# Let's create a function to clean up and prepare p0f data
fuP0F() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/p0f/*; fi
  mkdir -p /data/p0f/log
  chmod 760 -R /data/p0f
  chown beehive:beehive -R /data/p0f
}

# Let's create a function to clean up and prepare p0f data
fuTANNER() {
  if [ "$myPERSISTENCE" != "on" ]; then rm -rf /data/tanner/*; fi
  mkdir -p /data/tanner/log /data/tanner/files
  chmod 760 -R /data/tanner
  chown beehive:beehive -R /data/tanner
}

# Avoid unwanted cleaning
if [ "$myPERSISTENCE" = "" ]; then
  echo $myRED"!!! WARNING !!! - This will delete ALL honeypot logs. "$myWHITE
  while [ "$myQST" != "y" ] && [ "$myQST" != "n" ]; do
    read -p "Continue? (y/n) " myQST
  done
  if [ "$myQST" = "n" ]; then
    echo $myGREEN"Puuh! That was close! Aborting!"$myWHITE
    exit
  fi
fi

# Check persistence, if enabled compress and rotate logs
if [ "$myPERSISTENCE" = "on" ]; then
  echo "Persistence enabled, now rotating and compressing logs."
  fuLOGROTATE
else
  echo "Cleaning up and preparing data folders."
  fuADBHONEY
  fuCISCOASA
  fuCONPOT
  fuCOWRIE
  fuDIONAEA
  fuELASTICPOT
  fuELK
  fuGLASTOPF
  fuGLUTTON
  fuHERALDING
  fuHONEYTRAP
  fuMAILONEY
  fuMEDPOT
  fuNGINX
  fuRDPY
  fuSPIDERFOOT
  fuSURICATA
  fuP0F
  fuTANNER
fi
