#!/bin/sh

unset KEYNUMBER
export TEXTDOMAIN=getkey.sh
export TEXTDOMAINDIR="/usr/share/locale"

echo $"Please provide the key signature you want to add?"
read KEY
if [ -n "$KEY" ]; then
	KEYNUMBER="-${KEY}"
fi

sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $KEY
