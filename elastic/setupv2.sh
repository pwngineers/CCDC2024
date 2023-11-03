#!/bin/bash

print(){
	echo "=============================================================" 
	echo $1
	echo "=============================================================" 
}

print "Create encyprion key"
read -p "Input encryption key of at least 32-char (can be random): " KEY
echo "used ${KEY} as encryption key"
echo " "
print "Installing dependencies"
#it is a surprise tool that will help us later :)
apt install curl

print "Grabbing PGP Key"
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

print "Downloading packages from the web"
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.10.4-amd64.deb

wget https://artifacts.elastic.co/downloads/kibana/kibana-8.10.4-amd64.deb

shasum -a 512 kibana-8.10.4-amd64.deb

shasum -a 512 -c elasticsearch-8.10.4-amd64.deb.sha512

print "Unpacking..."
dpkg -i elasticsearch-8.10.4-amd64.deb

dpkg -i kibana-8.10.4-amd64.deb

print "Configuring Kibana"

echo "Setting encryption key..."

sed -i 'xpack.encryptedSavedObjects.encryptionKey: "${KEY}"' /etc/kibana/kibana.yml


print "configuring Elastic search"
#TODO

print "Performing Summoning ritual"
systemctl daemon-reload

print  "Starting up service..."
systemctl enable kibana.service
systemctl enable elasticsearch.service
systemctl start kibana.service
systemctl start elasticsearch.service
echo " "
echo "kibana should be up on port 5601"
echo "reset password via CLI or check temp password in unpacking step"
print "Generating token to connect kibana..."
echo " "
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana
echo " "
print "Generating 6-digit verification code..."
/usr/share/kibana/bin/kibana-verification-code

print "Creating enrollment token for nodes out of cluster"
echo " "
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s node
echo " "

print "DONE"
echo "Be sure to manually config Kibana"
echo "setup fleet server and harden host machine for next step"
