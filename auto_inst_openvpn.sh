#Setup OpenVPN auto

#echo "Adding the EPEL repository"
#yum install wget -y
#wget http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm
#rpm -Uvh epel-*
#rm epel-release-6-8.noarch.rpm -f

# Update the OS
#echo "Updating the system"
#yum update -y

#echo "Installing openvpn"
#yum install openvpn easy-rsa openssl -y

mkdir -p /etc/openvpn/easy-rsa/keys
cp -R /usr/share/easy-rsa/3.0.3/* /etc/openvpn/easy-rsa/
cp /root/vpn/vars /etc/openvpn/easy-rsa/vars
chmod 0755 *
source /root/vpn/vars
cd /etc/openvpn/easy-rsa/

#./clean-all
./easyrsa init-pki
./easyrsa build-ca
./easyrsa gen-dh
./easyrsa gen-req vpn-server nopass
./easyrsa sign-req server vpn-server
openvpn --genkey --secret /etc/openvpn/easy-rsa/keys/ta.key
cp -R ./pki/* ./keys/
sync

# Set the server configuration
cp /usr/share/doc/openvpn-2.4.6/sample/sample-config-files/server.conf /etc/openvpn/
cd /etc/openvpn/
sed -i 's|;duplicate-cn|duplicate-cn|' server.conf
sed -i 's|;log         openvpn.log|log         openvpn.log|' server.conf
sed -i 's|;user nobody|user nobody|' server.conf
sed -i 's|;group nobody|group nobody|' server.conf
sed -i 's|dh dh2048.pem|dh /etc/openvpn/easy-rsa/keys/dh.pem|' server.conf
sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|push "redirect-gateway def1 bypass-dhcp"|' server.conf
sed -i 's|ca ca.crt|ca /etc/openvpn/easy-rsa/keys/ca.crt|' server.conf
sed -i 's|tls-auth ta.key|tls-auth /etc/openvpn/easy-rsa/keys/ta.key|' server.conf
sed -i 's|cert server.crt|cert /etc/openvpn/easy-rsa/keys/issued/vpn-server.crt|' server.conf
sed -i 's|key server.key|key /etc/openvpn/easy-rsa/keys/private/vpn-server.key|' server.conf
sed -i 's|;push "dhcp-option DNS 208.67.222.222"|push "dhcp-option DNS 8.8.8.8"|' server.conf
sed -i 's|;push "dhcp-option DNS 208.67.220.220"|push "dhcp-option DNS 8.8.4.4"|' server.conf
sed -i 's|net.ipv4.ip_forward = 0|net.ipv4.ip_forward = 1|' /etc/sysctl.conf
sysctl -p
echo 1 > /proc/sys/net/ipv4/ip_forward
iptables -v -F
iptables -F -t mangle
iptables -F -t nat
iptables -v -A INPUT -i lo -j ACCEPT
iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o eth0 -j MASQUERADE
service iptables save
service iptables restart
chkconfig --add openvpn
chkconfig openvpn on
service openvpn start

#=====================Client1
cd /etc/openvpn/easy-rsa/
mkdir -p /etc/openvpn/easy-rsa/client1_keys
./easyrsa gen-req client1 nopass
./easyrsa sign-req client client1

mv /etc/openvpn/easy-rsa/pki/issued/client1.crt /etc/openvpn/easy-rsa/client1_keys/
mv /etc/openvpn/easy-rsa/pki/private/client1.key /etc/openvpn/easy-rsa/client1_keys/
cp /etc/openvpn/easy-rsa/keys/ta.key /etc/openvpn/easy-rsa/client1_keys/
cp /etc/openvpn/easy-rsa/keys/dh.pem /etc/openvpn/easy-rsa/client1_keys/
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/easy-rsa/client1_keys/
sync
#=====================Client2
cd /etc/openvpn/easy-rsa/
mkdir -p /etc/openvpn/easy-rsa/client2_keys
./easyrsa gen-req client2 nopass
./easyrsa sign-req client client2

mv /etc/openvpn/easy-rsa/pki/issued/client2.crt /etc/openvpn/easy-rsa/client2_keys/
mv /etc/openvpn/easy-rsa/pki/private/client2.key /etc/openvpn/easy-rsa/client2_keys/
cp /etc/openvpn/easy-rsa/keys/ta.key /etc/openvpn/easy-rsa/client2_keys/
cp /etc/openvpn/easy-rsa/keys/dh.pem /etc/openvpn/easy-rsa/client2_keys/
cp /etc/openvpn/easy-rsa/keys/ca.crt /etc/openvpn/easy-rsa/client2_keys/
sync

