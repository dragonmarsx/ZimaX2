#!/bin/bash

# Ensure script is run as root
if [ "$EUID" -ne 0 ]; then
  printf "❌ Please run this script as root user (sudo -i)\n\n\n"
  exit 1
fi

echo ""
echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
echo "         DUAL NODE RESIDENTIAL SERVER SERIES"
echo "  ArrStack Installer w/*arr-compose.yml + arrstack.env"
echo "➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖➖"
echo ""

# Questions for end-user
read -p "📂 Enter installation path ([Enter]=/DATA/AppData/arrstack): " ARR_PATH
ARR_PATH=${ARR_PATH:-/DATA/AppData/arrstack}
read -p "📂 Enter environment filename ([Enter]=arrstack.env): " ENV_NAME
ENV_NAME=${ENV_NAME:-arrstack.env}
ENV_PATH="$ARR_PATH/$ENV_NAME"

# Check if the environment file exists
if [ ! -f "$ENV_PATH" ]; then
  printf "\n❌ Environment file not found!\n"
  printf "   Please ensure key-value pairs exist on $ENV_PATH\n\n\n"
  exit 1
fi
printf "➡️ Environment file status: Found!\n"

# Validate that required variables are loaded
source "$ENV_PATH"
if [ -z "$TZ" ] || [ -z "$PUID" ] || [ -z "$PGID" ]  ||
   [ -z "$APPDATA_PATH" ] || [ -z "$MEDIA_PATH" ] ||
   [ -z "$LOCAL_IP" ] || [ -z "$DNS_IP1" ]  || [ -z "$DNS_IP2" ]; then
  printf "❌ Error: At least one key/value missing or empty in $ENV_PATH\n\n\n"
  exit 1
fi
printf "✅ Environment file: Scanned!\n"

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "               Captured key values"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
# Source the file and automatically strip any trailing carriage returns from variables
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

read -p "❓ Agree to install all arr stack apps with key-values above? (yes or no): " AGREE_INSTALL
AGREE_INSTALL=${AGREE_INSTALL:-no}
if [[ "${AGREE_INSTALL,,}" == "yes" ]]; then
  arrSet=("qbittorrent" "sabnzbd" "prowlarr" "sonarr" "radarr" "bazarr" "lidarr" "flaresolverr" "seerr")

  printf "⚙️ Creating/verifying arrstack network.\n"
  if ! docker network inspect arrstack_net >/dev/null 2>&1; then
    if ! docker network create arrstack_net; then
	  printf "❌ Failed to create arrstack network.\n" >&2
	  exit 1
    fi
  fi
  # Continue only if the network provably exists.
  if ! docker network inspect arrstack_net >/dev/null 2>&1; then
    printf "❌ Arrstack network not found after creation.\n" >&2
    exit 1
  fi
  docker network ls -f name=arrstack_net

  for f in "${arrSet[@]}"; do
    # Fetch remote template via curl and substitute variables into *-template.yml
    printf "🎼 %-14.20s: Fetching and composing\n" $f
    curl -sfL "https://raw.githubusercontent.com/dragonmarsx/ZimaX2/refs/heads/main/stacks/arrs/$f-template.yml" | envsubst > "$ARR_PATH/$f-compose.yml"

  done

  for f in "${arrSet[@]}"; do
    # Equivalent to docker compose up -d
    casaos-cli app-management install -f "$ARR_PATH/$f-compose.yml"    
    sleep 2	
  done    

  printf "🕔 Give ZimaOS sufficient time to complete all installations.\n"
  printf "⚙️ Check all progress on ZimaOS web dashboard...\n\n"
  read -t 5

  printf "✏️ Renaming script with extension '.executed.txt' to avoid accidental re-run.\n"
  # Capture absolute path and filename of this script.
  ABS_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
  SCRIPT_PATH="$(dirname "$ABS_PATH")"
  mv "$ABS_PATH" "$SCRIPT_PATH/arrstack-installer.executed.txt"
  printf "Done.\n\n\n"
  exit 1
fi
printf "❌ Canceling installation of arr stacks apps.\n"
printf "   To re-attempt, execute the same installation script.\n\n\n"
