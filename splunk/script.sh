#!/bin/bash

# Configuration - CHANGE THESE VALUES
SPLUNK_SERVER="172.20.242.20"
SPLUNK_PASSWORD="quickbrownfox"

echo "=========================================="
echo "Splunk Universal Forwarder Installation"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root or with sudo"
    exit 1
fi

# Download
echo "Downloading Splunk Universal Forwarder..."
cd /tmp
wget "https://download.splunk.com/products/universalforwarder/releases/10.2.0/linux/splunkforwarder-10.2.0-d749cb17ea65-linux-amd64.tgz"

if [ $? -ne 0 ]; then
    echo "ERROR: Download failed"
    exit 1
fi

# Extract
echo "Extracting..."
tar xzf splunkforwarder-10.2.0-d749cb17ea65-linux-amd64.tgz -C /opt

# Start
echo "Starting forwarder..."
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "$SPLUNK_PASSWORD"

# Configure forward server
echo "Configuring forward server..."
/opt/splunkforwarder/bin/splunk add forward-server "$SPLUNK_SERVER:9997" -auth admin:"$SPLUNK_PASSWORD"

# Add log monitoring
echo "Adding log monitors..."
/opt/splunkforwarder/bin/splunk add monitor /var/log/ -auth admin:"$SPLUNK_PASSWORD"

# Enable boot start
echo "Enabling auto-start on boot..."
/opt/splunkforwarder/bin/splunk enable boot-start

# Restart
echo "Restarting forwarder..."
/opt/splunkforwarder/bin/splunk restart

# Cleanup
rm -f /tmp/splunkforwarder-10.2.0-d749cb17ea65-linux-amd64.tgz

echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo "Forwarder is now sending logs to: $SPLUNK_SERVER:9997"
echo ""
echo "Verify with: /opt/splunkforwarder/bin/splunk status"
echo "=========================================="
