#!/bin/bash

version=1.3.6

# Vérifier si la connexion internet est active
if ! ping -c 3 www.example.com; then
	echo -e "Pas de connexion internet, verifier votre connexion et ré-essayez"
	exit 1
fi

cd "${HOME}/Téléchargements" || exit 1

echo -e "téléchargement du paquet rustdesk\n"
wget -c "https://github.com/rustdesk/rustdesk/releases/download/${version}/rustdesk-${version}-x86_64.deb"

sleep 2

cat <<EOF
Le paquet gstreamer1.0-pipewire est-il installé ? Si il n'est pas installé on l'installe.
De plus, nous ajoutons la source et installons la version fournie par le paquet communautaire pipewire-debian.
EOF
sleep 2

pkg=gstreamer1.0-pipewire

if ! status="$(dpkg-query -W --showformat='${db:Status-Status}' "${pkg}" 2>&1)" || [[ ! "${status}" = installed ]]; then
	echo sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y 2>&1
	sudo apt update -y
	sudo apt install "${pkg}" -y
	sleep 3
fi

echo -e "installation du paquet rustdesk précédemment téléchargé\n"
sudo dpkg -i "${HOME}/Téléchargements/rustdesk-${version}-x86_64.deb"

sleep 2

echo -e "Si il manque une dépendance, en forcer l'installation\n"
sudo apt-get -f install -y
