#!/bin/bash

# Variable for the Rustdesk version to install
version=1.3.7
arch=x86_64

# Check if the internet connection is active
if ! ping -c 3 www.example.com; then
	echo -e "The internet connection isn't active, please check your connection and retry"
	exit 1
fi

# Variable to store the directory path
directory="$HOME/Downloads"

# Check if the target directory exists
if [ ! -d "${directory}" ]; then
  # If the directory doesn't exist, create it
  mkdir "${directory}"
  echo "The folder “Directory” has been created."
else
  echo "The folder “Directory” already exists."
fi

# Download latest Rustdesk version into the Downloads directory
echo -e "Downloading the rustdesk package\n"
# curl -L -O "https://github.com/rustdesk/rustdesk/releases/download/${version}/rustdesk-${version}-${arch}.deb" -o "${directory}/rustdesk-${version}-${arch}.deb"

curl -L -O --output-dir ${directory}/ "https://github.com/rustdesk/rustdesk/releases/download/${version}/rustdesk-${version}-${arch}.deb"

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

echo -e "Installation of the Rustdesk package previously downloaded\n"
sudo dpkg -i "${directory}/rustdesk-${version}-x86_64.deb"

sleep 2

echo -e "If a dependancy is missing, force its installation\n"
sudo apt-get -f install -y

# Checking possible remaining errors
sudo dpkg -i "${directory}/rustdesk-${version}-x86_64.deb"
if ! $? ; then
    echo "Error installing Rustdesk package."
    exit 1
fi
