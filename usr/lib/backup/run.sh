#!/bin/bash

# Minden hiba vegzetes hiba, amire kilepunk
set -e

SRCDIR=`dirname $0`

# Elso dolgunk betolteni a configot
. /etc/default/backup

# Ellenorizzuk, hogy letezik-e a pidfile
if [ -f $BACKUPPID ]; then
	# Ha igen megnezzuk fut-e a script
	if [ `kill -0 $(cat $BACKUPPID) 2>/dev/null` ]; then
		# Ha fut a script kilepunk hibaval
		echo "A mentes fut:" 1>&2
		echo "`ps -p $(cat $BACKUPPID) u`" 1>&2
		exit 1
	else
		rm "$BACKUPPID" 2>&1>/dev/null
	fi
fi

# Megcsinaljuk a pidfile -t
echo $$>"$BACKUPPID"

# A futasi konyvtarakat ellenorizzuk
# es ha nincsennek meg akkor megcsinaljuk azokat
[ -d "${BACKUPVAR}" ] || mkdir -p "${BACKUPVAR}"

# Betoltjuk a mentes elott futtatando
# fuggvenyeket minden fuggvenynek egyedi
# nevvel kell rendelkeznie
BACKUPSCRIPTS="backupnum $BACKUPSCRIPTS"
for fv in $(echo $BACKUPSCRIPTS)
	do
	. "$SRCDIR/include/$fv" && "_$fv" pre
	done

# Oszerakjuk a kivetelek listajat az rsynchez
for ex in $(echo $RSYNC_EXCLUDE)
	do
		REXCLUDE="--exclude ${ex} $REXCLUDE"
	done

# Indul a mentes
/usr/bin/rsync -aSHWR --stats $REXCLUDE --delete-after $BACKUPDIRS "${BACKUPSRV}::${BACKUPTARGET}/0/"

# Miutan elkeszult a mentes takaritunk magunk utan
for fv in $(echo $BACKUPSCRIPTS)
	do
	. "$SRCDIR/include/$fv" && "_$fv" post
	done

# A futas vegen eltavolitjuk 
# pidfileunkat
rm "$BACKUPPID"

exit 0
