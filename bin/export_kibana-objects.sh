#!/bin/bash
# Export all Kibana objects through Kibana Saved Objects API
# Make sure ES is available
myES="http://127.0.0.1:64298/"
myKIBANA="http://127.0.0.1:64296/"
myESSTATUS=$(curl -s -XGET ''$myES'_cluster/health' | jq '.' | grep -c green)
if ! [ "$myESSTATUS" = "1" ]
  then
    echo "### Elasticsearch is not available, try starting via 'systemctl start elk'."
    exit
  else
    echo "### Elasticsearch is available, now continuing."
    echo
fi

# Set vars
myDATE=$(date +%Y%m%d%H%M)
myINDEXCOUNT=$(curl -s -XGET ''$myKIBANA'api/saved_objects/_find?type=index-pattern' | jq '.saved_objects[].attributes' | tr '\\' '\n' | grep "scripted" | wc -w)
myINDEXID=$(curl -s -XGET ''$myKIBANA'api/saved_objects/_find?type=index-pattern' | jq '.saved_objects[].id' | tr -d '"')
myDASHBOARDS=$(curl -s -XGET ''$myKIBANA'api/saved_objects/_find?type=dashboard&per_page=300' | jq '.saved_objects[].id' | tr -d '"')
myVISUALIZATIONS=$(curl -s -XGET ''$myKIBANA'api/saved_objects/_find?type=visualization&per_page=300' | jq '.saved_objects[].id' | tr -d '"')
mySEARCHES=$(curl -s -XGET ''$myKIBANA'api/saved_objects/_find?type=search&per_page=300' | jq '.saved_objects[].id' | tr -d '"')
myCOL1="[0;34m"
myCOL0="[0;0m"

# Let's ensure normal operation on exit or if interrupted ...
function fuCLEANUP {
  rm -rf patterns/ dashboards/ visualizations/ searches/
}
trap fuCLEANUP EXIT

# Export index patterns
mkdir -p patterns
echo $myCOL1"### Now exporting"$myCOL0 $myINDEXCOUNT $myCOL1"index pattern fields." $myCOL0
curl -s -XGET ''$myKIBANA'api/saved_objects/index-pattern/'$myINDEXID'' | jq '. | {attributes}' > patterns/$myINDEXID.json &
echo

# Export dashboards
mkdir -p dashboards
echo $myCOL1"### Now exporting"$myCOL0 $(echo $myDASHBOARDS | wc -w) $myCOL1"dashboards." $myCOL0
for i in $myDASHBOARDS;
  do
    echo $myCOL1"###### "$i $myCOL0
    curl -s -XGET ''$myKIBANA'api/saved_objects/dashboard/'$i'' | jq '. | {attributes}' > dashboards/$i.json &
  done;
echo

# Export visualizations
mkdir -p visualizations
echo $myCOL1"### Now exporting"$myCOL0 $(echo $myVISUALIZATIONS | wc -w) $myCOL1"visualizations." $myCOL0
for i in $myVISUALIZATIONS;
  do
    echo $myCOL1"###### "$i $myCOL0
    curl -s -XGET ''$myKIBANA'api/saved_objects/visualization/'$i'' | jq '. | {attributes}' > visualizations/$i.json &
  done;
echo

# Export searches
mkdir -p searches
echo $myCOL1"### Now exporting"$myCOL0 $(echo $mySEARCHES | wc -w) $myCOL1"searches." $myCOL0
for i in $mySEARCHES;
  do
    echo $myCOL1"###### "$i $myCOL0
    curl -s -XGET ''$myKIBANA'api/saved_objects/search/'$i'' | jq '. | {attributes}' > searches/$i.json &
  done;
echo

# Wait for background exports to finish
wait

# Building tar archive
echo $myCOL1"### Now building archive"$myCOL0 "kibana-objects_"$myDATE".tgz"
tar cvfz kibana-objects_$myDATE.tgz patterns dashboards visualizations searches > /dev/null

# Stats
echo
echo $myCOL1"### Statistics"
echo $myCOL1"###### Exported"$myCOL0 $myINDEXCOUNT $myCOL1"index patterns." $myCOL0
echo $myCOL1"###### Exported"$myCOL0 $(echo $myDASHBOARDS | wc -w) $myCOL1"dashboards." $myCOL0
echo $myCOL1"###### Exported"$myCOL0 $(echo $myVISUALIZATIONS | wc -w) $myCOL1"visualizations." $myCOL0
echo $myCOL1"###### Exported"$myCOL0 $(echo $mySEARCHES | wc -w) $myCOL1"searches." $myCOL0
echo
