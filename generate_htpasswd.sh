#!/usr/bin/env bash
set -e

# Load .env
if [[ ! -f .env ]]; then
    echo ".env file not found!"
    exit 1
fi

set -a
source .env
set +a

AUTH_DIR="${REGISTRY_DATA_VOLUME}/data/registry/auth"
DATA_DIR="${REGISTRY_DATA_VOLUME}/data/data"
OUTPUT_FILE="${AUTH_DIR}/htpasswd"

mkdir -p "$AUTH_DIR" "$DATA_DIR"

# Install htpasswd if missing
if ! command -v htpasswd &> /dev/null; then
    echo "htpasswd not found. Installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y apache2-utils
    elif command -v apk &> /dev/null; then
        sudo apk add apache2-utils
    elif command -v dnf &> /dev/null; then
        sudo dnf install -y httpd-tools
    elif command -v yum &> /dev/null; then
        sudo yum install -y httpd-tools
    elif command -v pacman &> /dev/null; then
        sudo pacman -Sy --noconfirm apache
    elif command -v brew &> /dev/null; then
        brew install httpd
    else
        echo "Unsupported platform. Please install htpasswd manually."
        exit 1
    fi
fi

# Write or append user
if [[ -f "$OUTPUT_FILE" ]] && grep -q "^${REGISTRY_USERNAME}:" "$OUTPUT_FILE"; then
    echo "User $REGISTRY_USERNAME already exists."
else
    echo "Creating/updating user $REGISTRY_USERNAME in htpasswd."
    htpasswd -Bb "$OUTPUT_FILE" "$REGISTRY_USERNAME" "$REGISTRY_PASSWORD"
fi

echo "✅ htpasswd setup complete at $OUTPUT_FILE"