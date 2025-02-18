#!/bin/bash

set -euo pipefail

# Variable for the Rustdesk version to install
version=1.3.7
arch=x86_64
rustdesk_package=rustdesk-${version}-${arch}.deb

# Check if the internet connection is active
if ! ping -c 3 www.example.com; then
    echo  "No internet connection, please check connectivity"
	exit 1
fi

# Variable to store the directory path
directory=$(mktemp -d)

# Check if the target directory exists
if [[ ! -d "${directory}" ]]; then
    # If the directory doesn't exist, create it
    mkdir -p "${directory}"
    echo "The folder '${directory} has been created."
fi

# Download latest Rustdesk version into the Downloads directory
echo "Downloading the rustdesk package"
curl -L -O --output-dir "${directory}"/ "https://github.com/rustdesk/rustdesk/releases/download/${version}/${rustdesk_package}"

sleep 2

cat <<EOF
Is the gstreamer1.0-pipewire package installed ? If not, we install it.
Additionnally we are adding the pipewire-debian community package source in to install that version.
EOF
sleep 2

pkg=gstreamer1.0-pipewire

if ! status="$(dpkg-query -W --showformat='${db:Status-Status}' "${pkg}" 2>&1)" || [[ ! "${status}" = installed ]]; then
	echo sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y 2>&1
	sudo apt update -y
	sudo apt install "${pkg}" -y
	sleep 3
fi

echo "Installation of the Rustdesk package"
sudo dpkg -i "${directory}/${rustdesk_package}"

sleep 2

echo "If a dependancy is missing, force its installation"
sudo apt-get -f install -y

# Checking possible remaining errors
sudo dpkg -i "${directory}/${rustdesk_package}"
if ! $? ; then
    echo "Error installing Rustdesk package."
    exit 1
fi
