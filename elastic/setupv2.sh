#!/bin/bash

print(){
	echo "=============================================================" 
	echo $1
	echo "=============================================================" 
}
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
read -p "Input encryption key of at least 32-char: " KEY
echo "used ${KEY} as encryption key"

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

echo "kibana should be up on port 5601\n \nBe sure to reset password and config security"
print "Generating token to connect kibana..."
/usr/share/elasticsearch/bin/elasticsearch-create-enrollment-token -s kibana

print "Generating 6-digit verification code..."
/usr/share/kibana/bin/kibana-verification-code


print "DONE"
echo "Be sure to manually config Kibana"
