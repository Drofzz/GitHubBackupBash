#!/bin/sh

GITHUBUSER="foo"
GITHUBREPO="bar.git"

BACKUPUSR="root"
BACKUPGRP="root"

WORKDIR="@tmpWork/GitBackup/"
GITREPO="git@github.com:$GITHUBUSER/$GITHUBREPO"
GITNAME="$GITHUBREPO"
BACKUPDIR="/var/GitBackup"
DATE=`date +%Y-%m-%d.%H-%M`

Backup () {
	if [ ! -d "$BACKUPDIR" ]; then
	echo "Backupdir not found... Creating it"
	mkdir -p "$BACKUPDIR"
	fi
	echo "Gziping Bundle..."
	gzip -9qf "$GITNAME.bundle"
	echo "Moving GZipped bundle to Backupdir..."
	mv "$GITNAME.bundle.gz" "$BACKUPDIR$GITNAME.$DATE.bundle.gz"
	}
	
if [ ! -d $WORKDIR ]; then
echo "Couldn't Find Workdir... Creating it"
mkdir -p $WORKDIR
fi
echo "Going To Workdir..."
cd $WORKDIR

if [ ! -d $GITNAME ]; then
echo "Git Repo Not Found... Cloning it"
git clone --bare "$GITREPO" "$GITNAME"
fi

echo "Going to Repo..."
cd "$GITNAME"

echo "Getting all branches up to date..."
git fetch origin '*:*'

echo "Creating new Repo Bundle..."
git bundle create "../$GITNAME.bundle" --all

echo "Going Back To Workdir..."
cd ..

echo "Creating md5hash for new bundle..."
openssl md5 "$GITNAME.bundle" > "$GITNAME.bundle.md5"

if [ ! -f "$GITNAME.bundle.md5.old" ]; then
	echo "This Seems to be the first Backup..."
	Backup
else
echo "Going to Match the old Repo for changes..."
diff -q "$GITNAME.bundle.md5.old" "$GITNAME.bundle.md5" 1>/dev/null

if [ $? == "0" ]; then
	echo "Nothing has changed since last backup..."
	else
	echo "Something has changed since last backup..."
		Backup
fi

fi
echo "Updating Owner"
chown -R $BACKUPUSR:$BACKUPGRP "$BACKUPDIR"

echo "Cleaning Up..."
rm -f "$GITNAME.bundle"
mv "$GITNAME.bundle.md5" "$GITNAME.bundle.md5.old"
echo "Done..."
