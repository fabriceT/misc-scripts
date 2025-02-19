#!/bin/bash

# Author Joyce MARKOLL <meets@gmx.fr>
# Contributor Fabrice THIROUX <fabrice.thiroux@free.fr>

# Debug
set -x

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
    echo "The folder '${directory} has been created."
fi

# Download latest Rustdesk version into the Downloads directory
echo -e "Downloading the rustdesk package\n"
curl -L -O --output-dir "${directory}"/ "https://github.com/rustdesk/rustdesk/releases/download/${version}/${rustpkg}"

sleep 2

cat <<EOF
Is the gstreamer1.0-pipewire package installed ? If not we install it.
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

echo "Installing the Rustdesk package"
sudo dpkg -i "${directory}/${rustpkg}"
echo -e "If a dependancy is missing, force its installation\n"
sudo apt-get -f install -y

# Checking possible remaining errors
if dpkg -s rustdesk | grep "Status: install" > /dev/null 2>&1; then
    echo "Rustdesk was installed successfully."
else
    echo "Error installing Rustdesk package."
    exit 1
fi

# Optional lines as the temporary files are stored in /tmp
# Cleaning temporary directories with their contents
sleep 1
sudo chmod 0644 RustDesk/*
sudo rm -rf /tmp/RustDesk/*
rm -rf /tmp/tmp.*/*
rmdir /tmp/tmp.*

