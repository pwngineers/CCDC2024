#!/bin/bash

SPLUNK_SERVER="172.20.242.20"
SPLUNK_PORT="9997"
SPLUNK_ADMIN_PASSWORD="quickbrownfox"

# Direct download URL
DOWNLOAD_URL="https://download.splunk.com/products/universalforwarder/releases/10.2.0/linux/splunkforwarder-10.2.0-d749cb17ea65-linux-amd64.tgz"

echo "=========================================="
echo "Splunk Universal Forwarder Installation"
echo "Target Splunk Server: $SPLUNK_SERVER:$SPLUNK_PORT"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root or with sudo"
    exit 1
fi

# Check if forwarder already installed
if [ -d "/opt/splunkforwarder" ]; then
    echo "WARNING: Splunk forwarder already installed at /opt/splunkforwarder"
    read -p "Remove and reinstall? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        /opt/splunkforwarder/bin/splunk stop 2>/dev/null
        rm -rf /opt/splunkforwarder
    else
        echo "Installation cancelled."
        exit 0
    fi
fi

# Download Splunk Universal Forwarder
echo "Downloading Splunk Universal Forwarder..."
cd /tmp
wget -O splunkforwarder.tgz "$DOWNLOAD_URL"

if [ $? -ne 0 ]; then
    echo "ERROR: Download failed. Check URL or internet connection."
    exit 1
fi

# Extract to /opt
echo "Extracting forwarder to /opt..."
tar xvzf splunkforwarder.tgz -C /opt

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to extract forwarder"
    exit 1
fi

# Start Splunk and accept license
echo "Starting Splunk Universal Forwarder..."
/opt/splunkforwarder/bin/splunk start --accept-license --answer-yes --no-prompt --seed-passwd "$SPLUNK_ADMIN_PASSWORD"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to start forwarder"
    exit 1
fi

# Add forward server
echo "Configuring forwarder to send to $SPLUNK_SERVER:$SPLUNK_PORT..."
/opt/splunkforwarder/bin/splunk add forward-server "$SPLUNK_SERVER:$SPLUNK_PORT" -auth admin:"$SPLUNK_ADMIN_PASSWORD"

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to add forward server"
    exit 1
fi

# Add log monitoring
echo "Adding log monitors..."
/opt/splunkforwarder/bin/splunk add monitor /var/log/syslog -index main -auth admin:"$SPLUNK_ADMIN_PASSWORD" 2>/dev/null
/opt/splunkforwarder/bin/splunk add monitor /var/log/auth.log -index main -auth admin:"$SPLUNK_ADMIN_PASSWORD" 2>/dev/null
/opt/splunkforwarder/bin/splunk add monitor /var/log/messages -index main -auth admin:"$SPLUNK_ADMIN_PASSWORD" 2>/dev/null
/opt/splunkforwarder/bin/splunk add monitor /var/log/secure -index main -auth admin:"$SPLUNK_ADMIN_PASSWORD" 2>/dev/null

# Monitor entire /var/log directory
/opt/splunkforwarder/bin/splunk add monitor /var/log/ -index main -auth admin:"$SPLUNK_ADMIN_PASSWORD"

# Enable boot start
echo "Enabling Splunk to start at boot..."
/opt/splunkforwarder/bin/splunk enable boot-start

# Restart forwarder
echo "Restarting forwarder..."
/opt/splunkforwarder/bin/splunk restart

# Verify configuration
echo ""
echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo "Forwarder Version: $(/opt/splunkforwarder/bin/splunk version)"
echo "Sending logs to: $SPLUNK_SERVER:$SPLUNK_PORT"
echo ""
echo "Verification commands:"
echo "  Status:          /opt/splunkforwarder/bin/splunk status"
echo "  Forward servers: /opt/splunkforwarder/bin/splunk list forward-server"
echo "  Monitored paths: /opt/splunkforwarder/bin/splunk list monitor"
echo "=========================================="

# Cleanup
rm -f /tmp/splunkforwarder.tgz

echo ""
echo "Next steps:"
echo "1. Verify data is arriving in Splunk Web UI with: index=* | stats count by host"
echo "2. Check forwarder status: /opt/splunkforwarder/bin/splunk status"