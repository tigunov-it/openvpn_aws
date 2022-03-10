#!/bin/bash
sudo apt-get update
sudo apt-get -y upgrade

# Установка mc
sudo apt -y install mc

# Установка OpenVPN и EasyRSA
sudo apt -y install openvpn

wget -P /home/ubuntu https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz

cd /home/ubuntu
tar xvf EasyRSA-3.0.8.tgz
cd /home/ubuntu/EasyRSA-3.0.8/
cp vars.example vars

sudo chown -R ubuntu:ubuntu /home/ubuntu/EasyRSA-3.0.8

sudo echo '
set_var EASYRSA_REQ_COUNTRY    "US"
set_var EASYRSA_REQ_PROVINCE   "California"
set_var EASYRSA_REQ_CITY       "San Francisco"
set_var EASYRSA_REQ_ORG        "Copyleft Certificate Co"
set_var EASYRSA_REQ_EMAIL      "me@example.net"
set_var EASYRSA_REQ_OU         "My Organizational Unit" ' >> /home/ubuntu/EasyRSA-3.0.8/vars

sudo cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf.gz /etc/openvpn/
sudo gzip -d /etc/openvpn/server.conf.gz

sudo sed -i 's/cipher AES-256-CBC/cipher AES-256-CBC \nauth SHA256/' /etc/openvpn/server.conf
sudo sed -i 's/dh dh2048.pem/dh dh.pem/' /etc/openvpn/server.conf
sudo sed -i 's/;user nobody/user nobody/' /etc/openvpn/server.conf
sudo sed -i 's/;group nogroup/group nogroup/' /etc/openvpn/server.conf
sudo sed -i 's/server 10.8.0.0 255.255.255.0/server 10.8.7.0 255.255.255.0/' /etc/openvpn/server.conf
sudo sed -i 's/;client-to-client/client-to-client/' /etc/openvpn/server.conf

sudo echo 'net.ipv4.ip_forward=1' >> /etc/sysctl.conf

sudo echo '# START OPENVPN RULES
# NAT table rules
*nat
:POSTROUTING ACCEPT [0:0]
# Allow traffic from OpenVPN client to wlp11s0 (change to the interface you discovered!)
-A POSTROUTING -s 10.8.7.0/8 -o ens5 -j MASQUERADE
COMMIT
# END OPENVPN RULES' >> /etc/ufw/before.rules

sudo sed -i 's/DEFAULT_FORWARD_POLICY="DROP"/DEFAULT_FORWARD_POLICY="ACCEPT"/' /etc/default/ufw

mkdir -p /home/ubuntu/client-configs/keys
mkdir -p /home/ubuntu//client-configs/files

chmod -R 700 /home/ubuntu/client-configs

cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf /home/ubuntu/client-configs/base.conf
sudo chown -R ubuntu:ubuntu /home/ubuntu/client-configs

#sudo sed -i 's/remote your_server_ip 1194/remote your_server_ip 1194/' /etc/openvpn/server.conf
sudo sed -i 's/;user nobody/user nobody/' /home/ubuntu/client-configs/base.conf
sudo sed -i 's/;group nogroup/group nogroup/' /home/ubuntu/client-configs/base.conf
sudo sed -i 's/ca ca.crt/;ca ca.crt/' /home/ubuntu/client-configs/base.conf
sudo sed -i 's/cert client.crt/;cert client.crt/' /home/ubuntu/client-configs/base.conf
sudo sed -i 's/key client.key/;key client.key/' /home/ubuntu/client-configs/base.conf
sudo sed -i 's/tls-auth ta.key 1/;tls-auth ta.key 1/' /home/ubuntu/client-configs/base.conf
sudo sed -i 's/cipher AES-256-CBC/cipher AES-256-CBC \nauth SHA256/' /home/ubuntu/client-configs/base.conf
sudo echo 'key-direction 1' >> /home/ubuntu/client-configs/base.conf

touch /home/ubuntu/client-configs/make_config.sh


echo '#!/bin/bash
# First argument: Client identifier

KEY_DIR=/home/ubuntu/client-configs/keys
OUTPUT_DIR=/home/ubuntu/client-configs/files
BASE_CONFIG=/home/ubuntu/client-configs/base.conf'  >> /home/ubuntu/client-configs/make_config.sh


echo "
cat \${BASE_CONFIG} \\
    <(echo -e '<ca>') \\
    \${KEY_DIR}/ca.crt \\
    <(echo -e '</ca>\\n<cert>') \\
    \${KEY_DIR}/\${1}.crt \\
    <(echo -e '</cert>\\n<key>') \\
    \${KEY_DIR}/\${1}.key \\
    <(echo -e '</key>\\n<tls-auth>') \\
    \${KEY_DIR}/ta.key \\
    <(echo -e '</tls-auth>') \\
    > \${OUTPUT_DIR}/\${1}.ovpn" >> /home/ubuntu/client-configs/make_config.sh


sudo chmod 700 /home/ubuntu/client-configs/make_config.sh
sudo chown -R ubuntu:ubuntu /home/ubuntu/client-configs


sudo ufw allow 1194
sudo ufw allow OpenSSH

sudo ufw disable
sudo ufw enable

sudo reboot