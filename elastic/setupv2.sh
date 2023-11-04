#!/bin/bash

print(){
	echo "=============================================================" 
	echo $1
	echo "=============================================================" 
}

print "Create encyprion key"
read -p "Input encryption key of at least 32-char (can be random): " KEY
echo "Encryption key recieved"
echo "DONE!"

print "Installing dependencies"
#it is a surprise tool that will help us later :)
apt install curl
echo "DONE!"

print "Grabbing PGP Key..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg
echo "DONE!"

print "Downloading packages from the web..."
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.10.4-amd64.deb
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.10.4-amd64.deb
shasum -a 512 kibana-8.10.4-amd64.deb
shasum -a 512 -c elasticsearch-8.10.4-amd64.deb.sha512
echo "DONE!"

print "Unpacking..."
dpkg -i elasticsearch-8.10.4-amd64.deb
dpkg -i kibana-8.10.4-amd64.deb
echo "DONE!"
print "Configuring Kibana"

echo "Setting encryption key..."
printf 'xpack.encryptedSavedObjects.encryptionKey: "${KEY}"' >> /etc/kibana/kibana.yml
echo "DONE!"

print "configuring Elastic search"
#TODO if needed
echo "DONE!"

print "Performing Summoning ritual"
systemctl daemon-reload
echo "DONE!"

print  "Starting up service..."
systemctl enable kibana.service
systemctl enable elasticsearch.service
systemctl start kibana.service
systemctl start elasticsearch.service
echo " "
echo "kibana should be up on port 5601"
echo "reset password via CLI or check temp password in unpacking step"
echo "DONE!"

print "Generating token to connect kibana..."
echo " "
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
echo " "
echo "DONE!"

print "Generating 6-digit verification code..."
/usr/share/kibana/bin/kibana-verification-code
echo "DONE!"

print "Creating enrollment token for nodes out of cluster"
echo " "
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
echo " "
echo "DONE!"

print "End Script"
echo "Be sure to manually config Kibana"
echo "setup fleet server and harden host machine for next step"
