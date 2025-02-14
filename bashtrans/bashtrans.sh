#!/bin/bash
#
# Build for PCLinuxOS 2010
# By Leiche (kellerleicheorig at aol.com)
# Licence GPL
# Generate pot, and *-language.po files, to translate bash scripts
# Aug Sun 08 2010
#

if [ $# -eq 0 ]; then
    echo "No File"
    exit 1 #exit script
fi

SCRIPT="$1"

SAVE=$(zenity --file-selection --title "Bash-Script-Translator-Generator" --save)
if [ -n "$SAVE" ];then
    LOCALE=$(grep LC_CTYPE /usr/share/i18n/locales/i18n | tail -1 | cut -c 10-14)
    bash --dump-po-strings "$SCRIPT" | xgettext -L PO -o "$SAVE.pot" -
    xterm -e "msginit -l $LOCALE -i $SAVE.pot -o $SAVE-$LOCALE.po"
fi
