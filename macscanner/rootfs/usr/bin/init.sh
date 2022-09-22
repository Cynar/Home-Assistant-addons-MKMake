#!/usr/bin/with-contenv bashio

echo "Running"


# Load Config
CONFIG_PATH=/data/options.json
SECRETS_PATH=/config/secrets.yaml

RATE=$(jq --raw-output '.refresh_rate // empty' $CONFIG_PATH)
MQTT_ADDRESS=$(jq --raw-output '.mqtt_server_address // empty' $CONFIG_PATH)
MQTT_PORT=$(jq --raw-output '.mqtt_server_port // empty' $CONFIG_PATH)
MQTT_USERNAME=$(jq --raw-output '.mqtt_server_username // empty' $CONFIG_PATH)
MQTT_PASSWORD=$(jq --raw-output '.mqtt_server_password // empty' $CONFIG_PATH)
MQTT_TOPIC=$(jq --raw-output '.mqtt_server_topic // empty' $CONFIG_PATH)
MQTT_PASS_FLAG=$(jq --raw-output '.read_mqtt_from_secrets // empty' $CONFIG_PATH)

NMAP_TARGET=$(jq --raw-output '.nmap_target // empty' $CONFIG_PATH)
NMAP_SPEED=$(jq --raw-output '.nmap_speed // empty' $CONFIG_PATH)

if [ "$MQTT_PASS_FLAG" == "true" ]; then
	MQTT_USERNAME=$(grep  'mqtt_server_username:' $SECRETS_PATH | awk '{ print $2}')
	MQTT_PASSWORD=$(grep  'mqtt_server_password:' $SECRETS_PATH | awk '{ print $2}')
fi

# Build mqtt command

if [ "$MQTT_USERNAME" = "" ] || [ "$MQTT_PASSWORD" = "" ]
then
mqtt_command_pub="mosquitto_pub -h $MQTT_ADDRESS -p $MQTT_PORT"
mqtt_command_sub="mosquitto_sub -h $MQTT_ADDRESS -p $MQTT_PORT"
else
mqtt_command_pub="mosquitto_pub -h $MQTT_ADDRESS -p $MQTT_PORT -u $MQTT_USERNAME -P $MQTT_PASSWORD"
mqtt_command_sub="mosquitto_sub -h $MQTT_ADDRESS -p $MQTT_PORT -u $MQTT_USERNAME -P $MQTT_PASSWORD"
fi

#Main Loop
while :
do
	NEXT_EPOCH=$(date +%s)+$RATE

	# Get raw scan data
	sudo /usr/bin/nmap -sn -T$NMAP_SPEED -n $NMAP_TARGET -oX - > raw.xml
	rawdataxml=`cat raw.xml`

	# Extract MACs
	echo "$rawdataxml" | grep 'addrtype=\"mac\"' | grep -o -E '([[:xdigit:]]{1,2}:){5}[[:xdigit:]]{1,2}' > mac.txt
	macdata=`cat mac.txt`

	# Get count of found MACS
	mac_count=`wc -l mac.txt | awk '{ print $1 }'`
	echo "Publishing, $mac_count addresses found"

	# Publish Data
	$mqtt_command_pub -r -t $MQTT_TOPIC/data/raw -f mac.txt
	$mqtt_command_pub -r -t $MQTT_TOPIC/data/xml -f raw.xml
	$mqtt_command_pub -r -t $MQTT_TOPIC/data/count -m $mac_count

	# Sleep till next cycle (run time accounted for)
	END_EPOCH=$(date +%s)
	SLEEP_SECONDS=$(( $NEXT_EPOCH - $END_EPOCH ))

	if (( SLEEP_SECONDS > 0 )); then
		echo "sleeping for $SLEEP_SECONDS seconds"
		sleep $SLEEP_SECONDS
	fi
done
