#!/bin/bash

# HASHIAPPNAME Value passed in from packer

HASHIAPP_ZIPFILE=$HASHIAPPNAME"_"$HASHIAPP_VERSION"_linux_amd64.zip"
HASHIAPP_DOWNLOAD_PATH="/tmp"
HASHIAPP_DOWNLOAD_URL="https://releases.hashicorp.com/$HASHIAPPNAME/$HASHIAPP_VERSION/$HASHIAPP_ZIPFILE"

HASHIAPP_USER="$HASHIAPPNAME"
HASHIAPP_GROUP="$HASHIAPPNAME"

HASHIAPP_BASE_PATH="/opt/$HASHIAPPNAME"
HASHIAPP_BIN_PATH=$HASHIAPP_BASE_PATH"/bin"
HASHIAPP_CONFIG_PATH=$HASHIAPP_BASE_PATH"/config"
HASHIAPP_DATA_PATH=$HASHIAPP_BASE_PATH"/data"

SYSTEMD_PATH="/etc/systemd/system/"

echo "Configuring directories for $HASHIAPPNAME"

echo $(sudo mkdir --parents $HASHIAPP_BIN_PATH)
echo $(sudo mkdir --parents $HASHIAPP_CONFIG_PATH)
echo $(sudo mkdir --parents $HASHIAPP_DATA_PATH)

wget -P $HASHIAPP_DOWNLOAD_PATH $HASHIAPP_DOWNLOAD_URL

unzip -d $HASHIAPP_DOWNLOAD_PATH "$HASHIAPP_DOWNLOAD_PATH/$HASHIAPP_ZIPFILE"

sudo mv "$HASHIAPP_DOWNLOAD_PATH/$HASHIAPPNAME" $HASHIAPP_BIN_PATH

sudo ln -s "$HASHIAPP_BIN_PATH/$HASHIAPPNAME" /usr/local/bin/$HASHIAPPNAME

sudo useradd --system --home $HASHIAPP_CONFIG_PATH --shell /bin/false $HASHIAPP_USER

# Move Hashiapp Systemd startup file to /etc/systemd/system
echo "*****"
echo $(ls /tmp/etc/systemd/system)
echo "Moving systemd file..."
echo "*****"
sudo mv "/tmp"$SYSTEMD_PATH$HASHIAPPNAME".service" $SYSTEMD_PATH
sudo chmod a+x $SYSTEMD_PATH$HASHIAPPNAME".service"
sudo chown root:root $SYSTEMD_PATH$HASHIAPPNAME".service"

# Move Hashiapp <hashiapp> *.hcl *.json config files to Hashiapp config base path /opt/<hashiapp_name>/config
echo "*****"
echo "Hashiapp config files..."
echo "*****"
sudo mv "/tmp$HASHIAPP_CONFIG_PATH/"* $HASHIAPP_CONFIG_PATH

# Move any run script to Hashiapp base path /opt/<hashiapp_name>/bin
echo "*****"
echo "Hashiapp startup/run script..."
echo "*****"
sudo mv "/tmp$HASHIAPP_BIN_PATH/"* $HASHIAPP_BIN_PATH

sudo chown --recursive $HASHIAPP_USER:$HASHIAPP_GROUP $HASHIAPP_BASE_PATH