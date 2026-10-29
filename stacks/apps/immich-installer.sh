#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  printf "❌ Please run this script as root user (sudo -i)\n\n\n"
  exit 1
fi

SETUP_PATH="/DATA/AppData/immich"
ENV_FILE="$SETUP_PATH/immich.env"

echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
echo "  Immich Installer (with immich-compose.yml and .env)"
echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
echo ""

printf "Environment file status: $ENV_FILE\n"
# Check if the environment file exists
if [ ! -f "$ENV_FILE" ]; then
  printf "\n❌ Environment file not found!\n"
  printf "   Please ensure key-value pairs exist on $ENV_FILE\n"
  exit 1
fi
# Validate that required variables are loaded
if [ -z "$IMMICH_VERSION" ] || [ -z "$UPLOAD_LOCATION" ] || [ -z "$DB_DATA_LOCATION" ] || 
   [ -z "$APPDATA_LOCATION" ] || [ -z "$MACHINE_LEARNING_VERSION" ] || [ -z "$REDIS_VERSION" ] || 
   [ -z "$POSTGRES_VERSION" ] || [ -z "$DB_STORAGE_TYPE" ] || [ -z "$DB_PASSWORD" ] || 
   [ -z "$DB_USERNAME" ] || [ -z "$DB_DATABASE_NAME" ] || [ -z "$EXTLIB_LOCATION"]; then
  printf "❌ Error: At least one key/value missing or empty in $ENV_FILE\n"
  exit 1
fi

# Source the file and automatically strip any trailing carriage returns from variables
while IFS='=' read -r key value; do
  # Skip comments and empty lines
  [[ "$key" =~ ^#.*$ ]] || [ -z "$key" ] && continue
  # Trim carriage returns if present
  value=$(echo "$value" | tr -d '\r')
  export "$key"="$value"
done < $ENV_FILE
printf "Verified!\n"

# Fetch remote template via curl and substitute variables into immich-template.yml
printf "🎵 Composing environment file from remote Immich YAML template...\n"
curl -sfL "https://raw.githubusercontent.com/dragonmarsx/ZimaX2/refs/heads/main/stacks/apps/immich-template.yml" | envsubst > $SETUP_PATH/immich-compose.yml

printf "⚙️ Installing. Check progress on ZimaOS web dashboard...\n"
casaos-cli app-management install -f  "$SETUP_PATH/immich-compose.yml"
printf  "Renaming this script with extension '.executed.txt' to avoid accidental re-run.\n\n\n"
# mv /DATA/scripts/immich-installer.sh /DATA/scripts/immich-installer.sh.executed.txt
printf  "Done!\n\n\n"
