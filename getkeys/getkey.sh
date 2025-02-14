#!/bin/bash

export TEXTDOMAIN=getkey.sh
export TEXTDOMAINDIR="/usr/share/locale"

echo $"Please provide the key signature you want to add?"
read -r KEY

sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com "$KEY"
