#!/bin/bash
export TEXTDOMAIN=getkey.sh
export TEXTDOMAINDIR="/usr/share/locale"

set -euo pipefail

echo $"Please provide the key signature you want to add?"
read -r KEY

KEYRING_DIR="/etc/apt/keyrings"
sudo mkdir -p "$KEYRING_DIR"

KEYRING_FILE="$KEYRING_DIR/${KEY}.gpg"

echo $"Downloading and installing the key..."
gpg --no-default-keyring --keyring "$KEYRING_FILE" --keyserver keyserver.ubuntu.com --recv-keys "$KEY"

echo $"Key installed at $KEYRING_FILE"
echo $"Remember to add 'signed-by=$KEYRING_FILE' to the relevant .sources or .list entry."

