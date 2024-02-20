#!/bin/bash -e

# Definiere das Backup-Verzeichnis und Dateinamenformat
BACKUPDIR="."
DATE=$(date '+%Y-%m-%d')
BACKUPFILE="homematic-backup-$DATE.sbk"

MY_USER="ubuntu"

# Installation von QEMU und den benötigten Binärdateien für die Emulation
sudo apt-get update
sudo apt-get install -y qemu qemu-user-static binfmt-support

sudo cp /media/$MY_USER/rootfs/bin/crypttool /tmp/crypttool

# Erstelle temporäres Verzeichnis
TMPDIR=$(sudo mktemp -d)
TMPDIR2=$(sudo mktemp -d)

# Kopiere VERSION von /media/$USER/rootfs nach /tmp/firmware_version
sudo cp /media/$MY_USER/rootfs/VERSION $TMPDIR/firmware_version

# Archiviere /usr/local und speichere es als /tmp/usr_local.tar.gz
sudo mkdir -p $TMPDIR2/usr/local
sudo cp -r /media/$MY_USER/userfs/* $TMPDIR2/usr/local

# Überprüfe, ob das Verzeichnis Dateien enthält, bevor du es archivierst
if [ -n "$(sudo find $TMPDIR2/usr/local -type f)" ]; then
    sudo tar czf $TMPDIR/usr_local.tar.gz --exclude-tag=.nobackup -C $TMPDIR2 usr/local
fi

# Erstelle Symbolic Links für Bibliotheken in /lib32
for libfile in /media/$MY_USER/rootfs/lib32/*; do
    libname=$(basename "$libfile")
    if [ ! -e "/lib32/$libname" ]; then
        sudo ln -s "$libfile" "/lib32/$libname"
        sudo ln -s "$libfile" "/media/$MY_USER/$libname"
    elif [ ! -L "/lib32/$libname" ]; then
        # Die Datei existiert, ist jedoch kein Symbolic Link
        sudo mv "/lib32/$libname" "/lib32/${libname}_bak"
        sudo ln -s "$libfile" "/lib32/$libname"
        sudo ln -s "$libfile" "/media/$MY_USER/$libname"
    fi
done

for libfile in /media/$MY_USER/rootfs/lib/*; do
    libname=$(basename "$libfile")
    if [ ! -e "/lib/$libname" ]; then
        sudo ln -s "$libfile" "/lib/$libname"
        sudo ln -s "$libfile" "/media/$MY_USER/$libname"
    elif [ ! -L "/lib/$libname" ]; then
        # Die Datei existiert, ist jedoch kein Symbolic Link
        sudo mv "/lib/$libname" "/lib/${libname}_bak"
        sudo ln -s "$libfile" "/lib/$libname"
        sudo ln -s "$libfile" "/media/$MY_USER/$libname"
    fi
done

# Führe die ARM-Binärdatei mit QEMU aus
sudo LD_LIBRARY_PATH=/lib32:/lib qemu-arm-static /tmp/crypttool -s -t 1 <$TMPDIR/usr_local.tar.gz >$TMPDIR/signature

# Speichere den aktuellen Schlüsselindex
sudo LD_LIBRARY_PATH=/lib32:/lib qemu-arm-static /tmp/crypttool -g -t 1 >$TMPDIR/key_index

# Aufräumen: Lösche temporäres Verzeichnis
sudo rm -rf $TMPDIR
sudo rm -rf $TMPDIR2
sudo rm /tmp/crypttool

# Rückgängig machen der Sicherungen in /lib32
for libfile in /lib32/*_bak; do
    libname=$(basename "$libfile" _bak)
    sudo mv "$libfile" "/lib32/$libname"
done

# Rückgängig machen der Sicherungen in /lib
for libfile in /lib/*_bak; do
    libname=$(basename "$libfile" _bak)
    sudo mv "$libfile" "/lib/$libname"
done

# Entferne Symbolic Links
sudo find /lib32 -type l -exec rm -f {} \;
sudo find /lib -type l -exec rm -f {} \;
sudo find /media/$MY_USER -maxdepth 1 -type l -exec rm -f {} \;

echo "Backup wurde erstellt: $BACKUPDIR/$BACKUPFILE"
