#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  printf "❌ Please run this script as root user (sudo -i)\n\n\n"
  exit 1
fi

echo ""
echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
echo "  Immich Installer (with immich-compose.yml and .env)"
echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
echo ""

read -p "📂 Enter installation path (default /DATA/AppData/immich): " SETUP_PATH
SETUP_PATH=${SETUP_PATH:-/DATA/AppData/immich}
read -p "📂 Enter environment filename (default immich.env): " ENV_NAME
ENV_NAME=${ENV_NAME:-immich.env}
ENV_PATH="$SETUP_PATH/$ENV_NAME"

if [ ! -f "$ENV_PATH" ]; then
    printf "❌ Error: $ENV_PATH as typed, cannot be found there. Try again.\n\n\n"
    exit 1
fi

# Check if the environment file exists
if [ ! -f "$ENV_PATH" ]; then
  printf "\n❌ Environment file not found!\n"
  printf "   Please ensure key-value pairs exist on $ENV_PATH\n"
  exit 1
fi
printf "➡️ Environment file status: Found!\n"

# Validate that required variables are loaded
source "$ENV_PATH"
if 
   [ -z "$UPLOAD_LOCATION" ] ||  [ -z "$DB_DATA_LOCATION" ] || 
   [ -z "$APPDATA_LOCATION" ] || [ -z "$EXTLIB_LOCATION" ]  || 
   [ -z "$IMMICH_VERSION" ] || [ -z "$MACHINE_LEARNING_VERSION" ] || 
   [ -z "$REDIS_VERSION" ] ||  [ -z "$POSTGRES_VERSION" ] || 
   [ -z "$DB_STORAGE_TYPE" ] || [ -z "$DB_PASSWORD" ] || 
   [ -z "$DB_USERNAME" ] || [ -z "$DB_DATABASE_NAME" ]; then
  printf "❌ Error: At least one key/value missing or empty in $ENV_PATH\n"
  exit 1
fi
printf "✅ Environment file: Scanned!\n"
# Source the file and automatically strip any trailing carriage returns from variables
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "               Captured key values"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
while IFS='=' read -r key value; do
  # Skip comments and empty lines
  [[ "$key" =~ ^#.*$ ]] || [ -z "$key" ] && continue
  # Trim carriage returns if present
  value=$(echo "$value" | tr -d '\r')
  export "$key"="$value"
  printf " $key"="$value\n"
done < $ENV_PATH
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
printf "✅ Key-values captured!\n"

# Fetch remote template via curl and substitute variables into immich-template.yml
printf "🎼 Composing environment file from remote Immich YAML template...\n"
curl -sfL "https://raw.githubusercontent.com/dragonmarsx/ZimaX2/refs/heads/main/stacks/apps/immich-template.yml" | envsubst > $SETUP_PATH/immich-compose.yml

read -p "❓ Agree to install Immich-server with the key-values above? (Enter-type yes): " AGREE_INSTALL
AGREE_INSTALL=${AGREE_INSTALL:-no}
if [[ "${AGREE_INSTALL,,}" == "yes" ]]; then
    printf "⚙️ Give ZimaOS a couple of minutes to complete the installation.\n"
    printf "   Check progress on ZimaOS web dashboard...\n\n\n"
    casaos-cli app-management install -f "$SETUP_PATH/immich-compose.yml"
	sleep 180
    printf "\n✏️ Renaming this script with extension '.executed.txt' to avoid accidental re-run.\n\n\n"
    mv /DATA/scripts/immich-installer.sh /DATA/scripts/immich-installer.executed.txt
    exit 1
fi
printf "❌ Canceling installation of Immich-server.\n"
printf "   To re-attempt, execute the same installation script.\n\n\n"
