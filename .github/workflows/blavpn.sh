#!/bin/bash

# 确保脚本以root权限运行
if [ "$(id -u)" != "0" ]; then
   echo "该脚本必须以root权限运行" 1>&2
   exit 1
fi

# 更新系统
echo "正在更新系统..."
yum update -y

# 安装EPEL仓库
echo "正在安装EPEL仓库..."
yum install -y epel-release

# 安装OpenVPN
echo "正在安装OpenVPN..."
yum install -y openvpn

# 安装Easy-RSA
echo "正在安装Easy-RSA..."
yum install -y easy-rsa

# 创建OpenVPN配置目录
echo "正在创建OpenVPN配置目录..."
mkdir -p /etc/openvpn/easy-rsa

# 复制Easy-RSA配置到OpenVPN目录
echo "正在复制Easy-RSA配置..."
cp -R /usr/share/easy-rsa/* /etc/openvpn/easy-rsa

# 配置Easy-RSA
echo "正在配置Easy-RSA..."
cd /etc/openvpn/easy-rsa
./easyrsa init-pki
./easyrsa build-ca nopass
./easyrsa gen-req server nopass
./easyrsa sign-req server server
./easyrsa gen-dh
openvpn --genkey --secret ta.key

# 创建OpenVPN服务器配置文件
echo "正在创建OpenVPN服务器配置文件..."
cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 8.8.4.4"
keepalive 10 120
comp-lzo
persist-key
persist-tun
status openvpn-status.log
verb 3
explicit-exit-notify 1
EOF

# 启动OpenVPN服务
echo "正在启动OpenVPN服务..."
systemctl start openvpn@server.service
systemctl enable openvpn@server.service

# 配置防火墙（如果使用firewalld）
echo "正在配置防火墙..."
firewall-cmd --zone=public --add-port=1194/udp --permanent
firewall-cmd --reload

# 获取服务器的外部IP地址
SERVER_IP=$(curl -s https://api.ipify.org)

# 生成客户端配置文件
echo "正在生成客户端配置文件..."
cat > /etc/openvpn/client.conf <<EOF
client
dev tun
proto udp
remote $SERVER_IP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
ca ca.crt
comp-lzo
verb 3
EOF

# 显示连接信息
echo "OpenVPN服务器已配置完成。"
echo "以下是客户端连接信息："
echo "服务器地址：$SERVER_IP"
echo "端口：1194"
echo "协议：UDP"
echo "客户端配置文件：/etc/openvpn/client.conf"

# 将客户端配置文件复制到当前目录，以便下载
cp /etc/openvpn/client.conf /root/client.conf
echo "客户端配置文件已复制到/root/client.conf，你可以下载并使用它来连接到VPN。"

# 提供中文教程说明如何连接
echo "以下是如何使用客户端配置文件连接到VPN的中文教程："
echo "1. 下载/root/client.conf文件到你的设备。"
echo "2. 安装OpenVPN客户端软件（如果你的设备还没有安装）。"
echo "3. 打开OpenVPN客户端软件，导入下载的client.conf配置文件。"
echo "4. 连接到VPN服务器。"
echo "5. 确保你的网络流量通过VPN隧道传输，以保护你的隐私和安全。"
