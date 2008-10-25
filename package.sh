#!/bin/bash

# Packages a Cocoa application for redistribution, and copies the
# resulting .dmg file to the desktop. Adapted from
# http://www.stone.com/The_Cocoa_Files/Just_Ship_it.html

# TODO: support application names with spaces in them
# TODO: set a background image on the DMG
# TODO: arrange the icons in the DMG

pushd $(dirname ${BASH_SOURCE[0]})
SCRIPTDIR=$(pwd)
popd
SPARKLEHOME=$SCRIPTDIR/Sparkle
PRIVATEKEY=$1
APPNAME=$2

if [ "$PRIVATEKEY" = "" ]; then
  echo "Usage: $0 path-to-private-key app-name"
  exit 1
fi

if [ "$APPNAME" = "" ]; then
  echo "Usage: $0 path-to-private-key app-name"
  exit 1
fi

PLIST=~/bin/Release/$APPNAME.app/Contents/Info.plist

APPVERSION=$(cat $PLIST | grep -A 1 CFBundleVersion | tail -n 1 | sed 's/.*>\(.*\)<.*/\1/')

if [ "$APPVERSION" = "" ]; then
  echo "Couldn't determine CFBundleVersion"
  exit 1
fi

TMPDIR=$(mktemp -d -t $APPNAME)
pushd $TMPDIR

# Copy the application to the staging directory.
cp -R -L ~/bin/Release/$APPNAME.app .
chmod -R u+w,go-w,a+rX .
chown -R root.admin .

# Remove development scree from frameworks
find . -name 'Documentation' -exec rm -rf {} \; -prune
find . -name 'Headers' -exec rm -rf {} \; -prune
find . -name 'PrivateHeaders' -exec rm -rf {} \; -prune

# Strip symbols from binaries
for binary in $(find . -type f -print | xargs file | grep Mach-O | awk -F: '{print $1}')
do
  strip -S $binary
  chmod a+x $binary
done

# Create a DMG
# TODO: the volume name can't contain a space or MOUNTPOINT won't be
# determined correctly
IMAGE=$APPNAME-tmp
hdiutil create -megabytes 10 $IMAGE -layout NONE -fs HFS -volname ${APPNAME} -nospotlight
IMAGE=$(pwd)/$IMAGE.dmg

# Mount the disk
DRIVESPEC=$(hdid $IMAGE)
DRIVE=$(echo $DRIVESPEC | awk '{print $1}')
MOUNTPOINT=$(echo $DRIVESPEC | awk '{print $2}')

# Copy the application to the disk
cp -R -L $APPNAME.app $MOUNTPOINT

# Make a link to Applications on the disk
osascript -e "tell application \"Finder\" to make alias file to alias (POSIX file \"/Applications\" as text) at (POSIX file \"$MOUNTPOINT\" as text)"

# Eject the disk and compress it
hdiutil eject ${DRIVE}
TARGETIMAGE=~/Desktop/$APPNAME-$APPVERSION
hdiutil convert -format UDCO $IMAGE -o $TARGETIMAGE

# Append a hash to the filename, for cache busting
HASH=$(openssl dgst -sha1 $TARGETIMAGE.dmg | sed 's/.*= \([a-f0-9]\{8\}\).*/\1/')
mv $TARGETIMAGE.dmg $TARGETIMAGE-$HASH.dmg
TARGETIMAGE=$TARGETIMAGE-$HASH.dmg

# Print the final filename and version
echo $TARGETIMAGE
echo "Version $APPVERSION"

# Sign the update
# TODO: this assumes the Sparkle distribution is a peer of the application
# project folder, and the private key is in the parent folder
ruby "$SPARKLEHOME/Extras/Signing Tools/sign_update.rb" $TARGETIMAGE ${PRIVATEKEY}

popd > /dev/null
rm -rf $TMPDIR
