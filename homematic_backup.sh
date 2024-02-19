#!/bin/sh -e

# Definiere das Backup-Verzeichnis und Dateinamenformat
BACKUPDIR="."
DATE=$(date '+%Y-%m-%d')
BACKUPFILE="homematic-backup-$DATE.sbk"

MY_USER="root"

cp /mnt/$MY_USER/rootfs/bin/crypttool /tmp/crypttool

# Erstelle temporäres Verzeichnis
TMPDIR=$(mktemp -d)
TMPDIR2=$(mktemp -d)

# Kopiere VERSION von /mnt/$USER/rootfs nach /tmp/firmware_version
cp /mnt/$MY_USER/rootfs/VERSION $TMPDIR/firmware_version

# Archiviere /usr/local nur wenn es Dateien enthält
mkdir -p $TMPDIR2/usr/local
echo $TMPDIR2/usr/local
cp -r /mnt/$MY_USER/userfs/* $TMPDIR2/usr/local

# Überprüfe, ob das Verzeichnis Dateien enthält, bevor du es archivierst
if [ -n "$(find $TMPDIR2/usr/local -type f)" ]; then
    tar czf $TMPDIR/usr_local.tar.gz --exclude-tag=.nobackup -C $TMPDIR2 usr/local
fi

/tmp/crypttool -s -t 1 <$TMPDIR/usr_local.tar.gz >$TMPDIR/signature

# Speichere den aktuellen Schlüsselindex
/tmp/crypttool -g -t 1 >$TMPDIR/key_index

# Erstelle das endgültige Archiv
tar cf $BACKUPDIR/$BACKUPFILE -C $TMPDIR usr_local.tar.gz signature firmware_version key_index

# Aufräumen: Lösche temporäres Verzeichnis
rm -rf $TMPDIR
rm -rf $TMPDIR2
rm /tmp/crypttool

echo "Backup wurde erstellt: $BACKUPDIR/$BACKUPFILE"
