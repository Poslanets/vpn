#Setup OpenVPN auto

##yum install openvpn easy-rsa -y
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
cp ./pki/* ./keys/
sync
#Run 1 line at time.
#./build-ca # In common name should be name [b]server[/b]
#./build-key-server server 
#./build-key ardupilot #Create Client
#./build-dh

# Set the server configuration
cp /usr/share/doc/openvpn-2.4.6/sample/sample-config-files/server.conf /etc/openvpn/
cd /etc/openvpn/
sed -i 's|;duplicate-cn|duplicate-cn|' server.conf
sed -i 's|;log         openvpn.log|log         openvpn.log|' server.conf
sed -i 's|;user nobody|user nobody|' server.conf
sed -i 's|;group nobody|group nobody|' server.conf
sed -i 's|dh dh1024.pem|dh /etc/openvpn/easy-rsa/keys/dh.pem|' server.conf
sed -i 's|;push "redirect-gateway def1 bypass-dhcp"|push "redirect-gateway def1 bypass-dhcp"|' server.conf
sed -i 's|ca ca.crt|ca /etc/openvpn/easy-rsa/keys/ca.crt|' server.conf
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
