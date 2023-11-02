#!/bin/bash
print_step() {
        echo "======================================================================="
        echo $1
        echo "======================================================================="
}

print_step "Step 0: Retrieving elastic and kibana..."

echo "grabbing public signing key..."
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg

echo "retrieve elasticsearch..."
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.10.4-amd64.deb

wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.10.4-amd64.deb.sha512

shasum -a 512 -c elasticsearch-8.10.4-amd64.deb.sha512

sudo dpkg -i elasticsearch-8.10.4-amd64.deb

systemctl start elasticsearch.service

echo "retrieve kibana..."

wget https://artifacts.elastic.co/downloads/kibana/kibana-8.10.4-amd64.deb
shasum -a 512 kibana-8.10.4-amd64.deb

print_step "Step 1: installing..."

dpkg -i *.deb

echo "installing java"
apt update
apt install -y openjdk-8-jdk pwgen

print_step "Step 2 Configuring Elasticsearch"
echo "Setting cluster-name to kibana"
sed -i "s/#cluster.name: my-application/cluster.name: kibana/" /etc/elasticsearch/elasticsearch.yml
echo "Setting network.host to 127.0.0.1"
sed -i "s/#network.host: 192.168.0.1/network.host: 127.0.0.1/" /etc/elasticsearch/elasticsearch.yml
echo "Setting listerning port to 9200"
sed -i "s/#http.port: 9200/http.port: 9200/" /etc/elasticsearch/elasticsearch.yml

print_step "Step 5: Performing summoning ritual..."
systemctl daemon-reload

print_step "Step 5.1: Enabling elasticsearch"
systemctl enable elasticsearch.service

print_step "Step 5.2: Enabling kibana"
systemctl enable kibana.service

print_step "Step 6: Starting services"
systemctl start elasticsearch.service
systemctl enable kibana.service


echo "Kibana is up on port 5601"
echo "Make sure to connect kibana via token and reset password"
echo "TODO: Change config file to increase security"
