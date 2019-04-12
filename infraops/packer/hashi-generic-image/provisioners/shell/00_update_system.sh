#!/bin/bash

CONSUL_TEMPLATE_ZIP_FILE="consul-template_"$CONSUL_TEMPLATE_VERSION"_linux_amd64.zip"
CONSUL_TEMPLATE_URL="https://releases.hashicorp.com/consul-template/"$CONSUL_TEMPLATE_VERSION"/"$CONSUL_TEMPLATE_ZIP_FILE

# Move Dnsmasq file /etc/dnsmasq.d/10-consul
echo "*****"
echo $(ls /etc/dnsmasq.d)
echo "Moving Dnsmasq conf file..."
echo "*****"
sudo mv "/tmp/etc/dnsmasq.d/10-consul" /etc/dnsmasq.d/10-consul


sudo apt-get update

sudo apt-get install -y wget unzip jq dnsmasq

# Install Consul Template
echo "*****"
echo "Installing Consul Template..."
echo "*****"
wget -P /tmp $CONSUL_TEMPLATE_URL
unzip /tmp/CONSUL_TEMPLATE_ZIP_FILE
mv /tmp/consul-template /usr/local/bin/

echo "Done update..."
