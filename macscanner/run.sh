#!/usr/bin/env bashio

DIRECTORY=/config/macscanner/
FILE=init.sh

echo "Checking for existing filestructre"

if [ ! -d "$DIRECTORY" ]; then
  echo "$DIRECTORY does not exist. Creating"
  mkdir $DIRECTORY
fi

if [ ! -f "$DIRECTORY$FILE" ]; then
  echo "$DIRECTOR$FILE does not exist. Creating"

  cat > $DIRECTORY$FILE
  echo "#!/usr/bin/with-contenv bashio" > $DIRECTORY$FILE
  echo "" > $DIRECTORY$FILE
  echo "echo \"Running\"" > $DIRECTORY$FILE
  echo "CONFIG_PATH=/data/options.json" > $DIRECTORY$FILE
else
  echo "Existing file structure found, executing..."
fi

source /config/macscanner/init.sh
