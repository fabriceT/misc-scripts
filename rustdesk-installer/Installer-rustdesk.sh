#/bin/bash

version=1.3.6

# Vérifier si la connexion internet est active
ping6 -c 3 www.example.com
if [ $? -eq 0 ]; then

cd ~/Téléchargements

echo -e "téléchargement du paquet rustdesk\n"
wget -c https://github.com/rustdesk/rustdesk/releases/download/$version/rustdesk-$version-x86_64.deb

sleep 2

echo -e "Le paquet gstreamer1.0-pipewire est-il installé ? Si il n'est pas installé on l'installe\n"
sleep 2
echo -e "De plus nous ajoutons la source et installons la version fournie par le paquet communautaire pipewire-debian\n"

pkg=gstreamer1.0-pipewire

status="$(dpkg-query -W --showformat='${db:Status-Status}' "$pkg" 2>&1)"
if [ ! $? = 0 ] || [ ! "$status" = installed ]; then
	sudo add-apt-repository ppa:pipewire-debian/pipewire-upstream -y 2>&1
	sudo apt update -y
	sudo apt install $pkg -y
fi

sleep 3
echo -e "installation du paquet rustdesk précédemment téléchargé\n"
sudo dpkg -i ~/Téléchargements/rustdesk-$version-x86_64.deb 

sleep 2

echo -e "Si il manque une dépendance, en forcer l'installation\n"
sudo apt-get -f install -y

else
	echo -e "Pas de connexion internet, verifier votre connexion et ré-essayez"
fi

