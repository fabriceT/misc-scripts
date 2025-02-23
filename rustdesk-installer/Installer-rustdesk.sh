#!/bin/bash

# Author Joyce MARKOLL <meets@gmx.fr>
# Contributor Fabrice THIROUX <fabrice.thiroux@free.fr>

# Debug
set -euo pipefail

# Variable for the Rustdesk version to install
version="1.3.7"
arch="x86_64"

# Variable for the package name
rustpkg="rustdesk-${version}-${arch}.deb"

# Variable to store the directory path
directory=$(mktemp -d)

# Check if the internet connection is active
if ! ping -c 3 www.example.com; then
    echo -e "The internet connection isn't active, please check your connection and retry"
    exit 1
fi

# Check if the target directory exists
if [[ ! -d "${directory}" ]]; then
# If the directory doesn't exist, create it
    mkdir -p "${directory}"
    echo "The folder '${directory}' has been created."
fi

# Download latest Rustdesk version into the Downloads directory
echo -e "Downloading the rustdesk package\n"
curl -L -O --output-dir "${directory}"/ "https://github.com/rustdesk/rustdesk/releases/download/${version}/${rustpkg}"

sleep 2

# In Ubuntu 20.04 and following versions we need the right pipewire-debian for rustdesk to work.
# Please check and adapt for your distribution if needed.
cat <<EOF
Is the gstreamer1.0-pipewire package installed ? If not we install it.
Additionnally we are adding the pipewire-debian community package source in to install that version.
EOF
sleep 2

pkg="gstreamer1.0-pipewire"

if ! status="$(dpkg-query -W --showformat='${db:Status-Status}' "${pkg}" 2>&1)" || [[ ! "${status}" = installed ]]; then
    echo "Adding pipewire PPA and installing gstreamer1.0-pipewire..." # Descriptive message
    sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y 2>&1
    sudo apt update -y
    sudo apt install "${pkg}" -y
    sleep 3
fi

# Install the dependencies and the previously downloaded package
read -p "Do you want to install Rustdesk ? (Y/n) " install_rustdesk
if [[ "$install_rustdesk" == "Y" ]]; then

# Install the dependencies and the Debian package using apt-get
    if ! sudo apt-get install "${directory}/${rustpkg}" -y; then  # Check if installation succeeds
        echo "Error during initial installation. Trying to fix dependencies..."
        sudo apt-get -f install -y # Try to correct missing dependencies
        if ! sudo apt-get install "${directory}/${rustpkg}" -y; then # Retry installing the package after correction
            echo "Failed to install Rustdesk even after dependency fix."
            exit 1 # Quit if installation fails again
        fi
    fi

# Checking the installation
    if dpkg -s rustdesk | grep "Status: install" > /dev/null 2>&1; then
        echo "Rustdesk was installed successfully."
    else
        echo "Error installing Rustdesk package. Check the dependencies."
        exit 1
    fi
else
    echo "Installation cancelled."
    exit 1
fi
