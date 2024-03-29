#!/bin/bash

PATH_SERVER="/etc/openvpn/server"

new_client () {
    client=$1

    common=$(cat ${PATH_SERVER}/client-common.txt)
    ca=$(cat ${PATH_SERVER}/easy-rsa/pki/ca.crt)
    cert=$(cat "${PATH_SERVER}/easy-rsa/pki/issued/$client.crt" | grep -v CERTIFICATE)
    key=$(cat "${PATH_SERVER}/easy-rsa/pki/private/$client.key" | grep -v OpenVPN)
    tc=$(cat ${PATH_SERVER}/tc.key)

    # 生成 client.ovpn
    cat > "~/$client.ovpn" <<-EOF
${common}
<ca>
${ca}
</ca>
<cert>
${cert}
</cert>
<key>
${key}
</key>
<tls-crypt>
${tc}
</tls-crypt>
EOF
}

install_openvpn() {
    echo 'Welcome to this OpenVPN road warrior installer!'

    # 系统 IPv4 地址
    if [[ $(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}') -eq 1 ]]; then
        ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
    else
        number_of_ip=$(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}')
        echo
        echo "Which IPv4 address should be used?"
        ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | nl -s ') '
        read -p "IPv4 address [1]: " ip_number
        until [[ -z "$ip_number" || "$ip_number" =~ ^[0-9]+$ && "$ip_number" -le "$number_of_ip" ]]; do
            echo "$ip_number: invalid selection."
            read -p "IPv4 address [1]: " ip_number
        done
        [[ -z "$ip_number" ]] && ip_number="1"
        ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n "$ip_number"p)
    fi

    # 私有 IPv4, 使用 NAT. 获取公网IP
    if echo "$ip" | grep -qE '^(10\.|172\.1[6789]\.|172\.2[0-9]\.|172\.3[01]\.|192\.168)'; then
        echo
        echo "This server is behind NAT. What is the public IPv4 address or hostname?"
        # Get public IP and sanitize with grep
        get_public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(curl -m 10 -4Ls "http://ip1.dynupdate.no-ip.com/")")
        read -p "Public IPv4 address / hostname [$get_public_ip]: " public_ip
        # If the checkip service is unavailable and user didn't provide input, ask again
        until [[ -n "$get_public_ip" || -n "$public_ip" ]]; do
            echo "Invalid input."
            read -p "Public IPv4 address / hostname: " public_ip
        done
        [[ -z "$public_ip" ]] && public_ip="$get_public_ip"
    fi

    # 系统支持 IPv6 地址(单个)
    if [[ $(ip -6 addr | grep -c 'inet6 [23]') -eq 1 ]]; then
        ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}')
    fi

    # 系统支持 IPv6 地址(多个, 选择一个)
    if [[ $(ip -6 addr | grep -c 'inet6 [23]') -gt 1 ]]; then
        number_of_ip6=$(ip -6 addr | grep -c 'inet6 [23]')
        echo
        echo "Which IPv6 address should be used?"
        ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | nl -s ') '
        read -p "IPv6 address [1]: " ip6_number
        until [[ -z "$ip6_number" || "$ip6_number" =~ ^[0-9]+$ && "$ip6_number" -le "$number_of_ip6" ]]; do
            echo "$ip6_number: invalid selection."
            read -p "IPv6 address [1]: " ip6_number
        done
        [[ -z "$ip6_number" ]] && ip6_number="1"
        ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | sed -n "$ip6_number"p)
    fi

    # 协议(UDP, TCP)
    echo
    echo "Which protocol should OpenVPN use?"
    echo "   1) UDP (recommended)"
    echo "   2) TCP"
    read -p "Protocol [1]: " protocol
    until [[ -z "$protocol" || "$protocol" =~ ^[12]$ ]]; do
        echo "$protocol: invalid selection."
        read -p "Protocol [1]: " protocol
    done
    case "$protocol" in
        1|"")
            protocol=udp
            ;;
        2)
            protocol=tcp
            ;;
    esac

    # 端口(1194, 默认)
    echo
    echo "What port should OpenVPN listen to?"
    read -p "Port [1194]: " port
    until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
        echo "$port: invalid port."
        read -p "Port [1194]: " port
    done
    [[ -z "$port" ]] && port="1194"

    # DNS
    echo
    echo "Select a DNS server for the clients:"
    echo "   1) Current system resolvers"
    echo "   2) Google"
    echo "   3) 1.1.1.1"
    echo "   4) OpenDNS"
    echo "   5) Quad9"
    echo "   6) AdGuard"
    read -p "DNS server [1]: " dns
    until [[ -z "$dns" || "$dns" =~ ^[1-6]$ ]]; do
        echo "$dns: invalid selection."
        read -p "DNS server [1]: " dns
    done

    # client
    echo
    echo "Enter a name for the first client:"
    read -p "Name [client]: " unsanitized_client
    client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client") # 去除非常用字符
    [[ -z "$client" ]] && client="client"
    echo
    echo "OpenVPN installation is ready to begin."
    firewall="iptables"
    read -n1 -r -p "Press any key to continue ..."

    # 安裝 openvpn
    openvpn_url='https://github.com/tiechui1994/jobs/releases/download/openvpn_2.5.4/openvpn_2.5.4_ubuntu_18.04_amd64.deb'
    curl -sL "$openvpn_url" -o "openvpn_2.5.4_amd64.deb" && \
    dpkg -i openvpn_2.5.4_amd64.deb

    # 获取 easy-rsa.
    easy_rsa_url='https://github.com/OpenVPN/easy-rsa/releases/download/v3.0.8/EasyRSA-3.0.8.tgz'
    mkdir -p ${PATH_SERVER}/easy-rsa/
    curl -sL "$easy_rsa_url" | tar xz -C ${PATH_SERVER}/easy-rsa/ --strip-components 1
    chown -R root:root ${PATH_SERVER}/easy-rsa

    # 创建 PKI, 生成 CA, Server, Client 证书
    cd ${PATH_SERVER}/easy-rsa
    ./easyrsa init-pki
    ./easyrsa --batch build-ca nopass  # ca.crt
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-server-full server nopass # server.crt
    EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client" nopass # client.crt
    EASYRSA_CRL_DAYS=3650    ./easyrsa gen-crl

    # 将生成的 server 相关的信息复制
    cp pki/ca.crt \
        pki/private/ca.key \
        pki/issued/server.crt \
        pki/private/server.key \
        pki/crl.pem \
        ${PATH_SERVER}

    # 文件目录权限
    chown "nobody:nogroup" ${PATH_SERVER}/crl.pem
    chmod o+x ${PATH_SERVER}

    # 生成 tls-crypt key
    openvpn --genkey --secret ${PATH_SERVER}/tc.key

    # 生成 DH 参数(2048位)
    openssl dhparam -2 -out ${PATH_SERVER}/dh.pem

    # 生成 server.conf
    cat > ${PATH_SERVER}/server.conf <<-EOF
local ${ip}
port ${port}
proto ${protocol}
dev tun
topology subnet
server 10.8.0.0 255.255.255.0
EOF

    # IPv6
    if [[ -z "$ip6" ]]; then
        echo 'push "redirect-gateway def1 bypass-dhcp"' >> ${PATH_SERVER}/server.conf
    else
        echo 'server-ipv6 fddd:1194:1194:1194::/64' >> ${PATH_SERVER}/server.conf
        echo 'push "redirect-gateway def1 ipv6 bypass-dhcp"' >> ${PATH_SERVER}/server.conf
    fi
    echo 'ifconfig-pool-persist ipp.txt' >> ${PATH_SERVER}/server.conf

    # DNS
    case "$dns" in
        1|"")
            # Locate the proper resolv.conf
            # Needed for systems running systemd-resolved
            if grep -q '^nameserver 127.0.0.53' "/etc/resolv.conf"; then
                resolv_conf="/run/systemd/resolve/resolv.conf"
            else
                resolv_conf="/etc/resolv.conf"
            fi
            # Obtain the resolvers from resolv.conf and use them for OpenVPN
            grep -v '^#\|^;' "$resolv_conf" | grep '^nameserver' | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | while read line; do
                echo "push \"dhcp-option DNS $line\"" >> ${PATH_SERVER}/server.conf
            done
            ;;
        2)
            echo 'push "dhcp-option DNS 8.8.8.8"' >> ${PATH_SERVER}/server.conf
            echo 'push "dhcp-option DNS 8.8.4.4"' >> ${PATH_SERVER}/server.conf
            ;;
        3)
            echo 'push "dhcp-option DNS 1.1.1.1"' >> ${PATH_SERVER}/server.conf
            echo 'push "dhcp-option DNS 1.0.0.1"' >> ${PATH_SERVER}/server.conf
            ;;
        4)
            echo 'push "dhcp-option DNS 208.67.222.222"' >> ${PATH_SERVER}/server.conf
            echo 'push "dhcp-option DNS 208.67.220.220"' >> ${PATH_SERVER}/server.conf
            ;;
        5)
            echo 'push "dhcp-option DNS 9.9.9.9"' >> ${PATH_SERVER}/server.conf
            echo 'push "dhcp-option DNS 149.112.112.112"' >> ${PATH_SERVER}/server.conf
            ;;
        6)
            echo 'push "dhcp-option DNS 94.140.14.14"' >> ${PATH_SERVER}/server.conf
            echo 'push "dhcp-option DNS 94.140.15.15"' >> ${PATH_SERVER}/server.conf
            ;;
    esac

cat >> ${PATH_SERVER}/server.conf <<-EOF
keepalive 10 120
auth SHA512
cipher AES-256-CBC
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-crypt tc.key
crl-verify crl.pem
tls-server
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256
user nobody
group nogroup
persist-key
persist-tun
verb 3
EOF

    # 开启 ip 转发(修改 sysctl 文件)
    echo 'net.ipv4.ip_forward=1' > /etc/sysctl.d/99-openvpn-forward.conf
    echo 1 > /proc/sys/net/ipv4/ip_forward
    if [[ -n "$ip6" ]]; then
        echo "net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.d/99-openvpn-forward.conf
        echo 1 > /proc/sys/net/ipv6/conf/all/forwarding
    fi

    # iptables规则
    iptables=$(command -v iptables)
    ip6tables=$(command -v ip6tables)

    cat > /etc/systemd/system/openvpn-iptables.service <<-'EOF'
[Unit]
Before=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
EOF

    cat >> /etc/systemd/system/openvpn-iptables.service <<-EOF
ExecStart=${iptables} -t nat -A POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to ${ip}
ExecStart=${iptables} -I INPUT -p ${protocol} --dport ${port} -j ACCEPT
ExecStart=${iptables} -I FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStart=${iptables} -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=${iptables} -t nat -D POSTROUTING -s 10.8.0.0/24 ! -d 10.8.0.0/24 -j SNAT --to ${ip}
ExecStop=${iptables} -D INPUT -p ${protocol} --dport ${port} -j ACCEPT
ExecStop=${iptables} -D FORWARD -s 10.8.0.0/24 -j ACCEPT
ExecStop=${iptables} -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
EOF

    if [[ -n "$ip6" ]]; then
        cat >> /etc/systemd/system/openvpn-iptables.service <<-EOF
ExecStart=${ip6tables} -t nat -A POSTROUTING -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to ${ip6}
ExecStart=${ip6tables} -I FORWARD -s fddd:1194:1194:1194::/64 -j ACCEPT
ExecStart=${ip6tables} -I FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
ExecStop=${ip6tables} -t nat -D POSTROUTING -s fddd:1194:1194:1194::/64 ! -d fddd:1194:1194:1194::/64 -j SNAT --to ${ip6}
ExecStop=${ip6tables} -D FORWARD -s fddd:1194:1194:1194::/64 -j ACCEPT
ExecStop=${ip6tables} -D FORWARD -m state --state RELATED,ESTABLISHED -j ACCEPT
EOF
    fi

    cat >> /etc/systemd/system/openvpn-iptables.service <<-'EOF'
[Install]
WantedBy=multi-user.target
EOF
    systemctl enable --now openvpn-iptables.service

    # If the server is behind NAT, use the correct IP address
    [[ -n "$public_ip" ]] && ip="$public_ip"
    # 生成客户端 common 文件, 在生成 client.ovpn 的时候使用
    cat > ${PATH_SERVER}/client-common.txt <<-EOF
client
dev tun
proto ${protocol}
remote ${ip} ${port}
pull
nobind
persist-key
persist-tun
connect-retry 5 5
resolv-retry infinite
ignore-unknown-option block-outside-dns
block-outside-dns

remote-cert-tls server
cipher AES-256-CBC
auth SHA512
tls-client
tls-version-min 1.2
tls-cipher TLS-ECDHE-ECDSA-WITH-AES-128-GCM-SHA256

verb 3
EOF

    # 启动 openvpn-server 服务
    systemctl enable --now openvpn-server@server.service
    new_client "$client"
    echo
    echo "Finished!"
    echo
    echo "The client configuration is available in:" ~/"$client.ovpn"
    echo "New clients can be added by running this script again."
}

manage_openvpn() {
    clear
    echo "OpenVPN is already installed."
    echo
    echo "Select an option:"
    echo "   1) Add a new client"
    echo "   2) Revoke an existing client"
    echo "   3) Remove OpenVPN"
    echo "   4) Exit"
    read -p "Option: " option
    until [[ "$option" =~ ^[1-4]$ ]]; do
        echo "$option: invalid selection."
        read -p "Option: " option
    done
    case "$option" in
        1)
            echo
            echo "Provide a name for the client:"
            read -p "Name: " unsanitized_client
            client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
            while [[ -z "$client" || -e ${PATH_SERVER}/easy-rsa/pki/issued/"$client".crt ]]; do
                echo "$client: invalid name."
                read -p "Name: " unsanitized_client
                client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
            done

            # 生成新的客户端配置
            cd ${PATH_SERVER}/easy-rsa/
            EASYRSA_CERT_EXPIRE=3650 ./easyrsa build-client-full "$client" nopass
            new_client "$client"
            echo
            echo "$client added. Configuration available in:" ~/"$client.ovpn"
            exit
            ;;
        2)
            # 证书吊销
            # This option could be documented a bit better and maybe even be simplified
            # ...but what can I say, I want some sleep too
            number_of_clients=$(tail -n +2 ${PATH_SERVER}/easy-rsa/pki/index.txt | grep -c "^V")
            if [[ "$number_of_clients" = 0 ]]; then
                echo
                echo "There are no existing clients!"
                exit
            fi
            echo
            echo "Select the client to revoke:"
            tail -n +2 ${PATH_SERVER}/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | nl -s ') '
            read -p "Client: " client_number
            until [[ "$client_number" =~ ^[0-9]+$ && "$client_number" -le "$number_of_clients" ]]; do
                echo "$client_number: invalid selection."
                read -p "Client: " client_number
            done
            client=$(tail -n +2 ${PATH_SERVER}/easy-rsa/pki/index.txt | grep "^V" | cut -d '=' -f 2 | sed -n "$client_number"p)
            echo
            read -p "Confirm $client revocation? [y/N]: " revoke
            until [[ "$revoke" =~ ^[yYnN]*$ ]]; do
                echo "$revoke: invalid selection."
                read -p "Confirm $client revocation? [y/N]: " revoke
            done

            if [[ "$revoke" =~ ^[yY]$ ]]; then
                # 开始吊销证书
                cd ${PATH_SERVER}/easy-rsa/
                ./easyrsa --batch revoke "$client"
                EASYRSA_CRL_DAYS=3650 ./easyrsa gen-crl
                rm -f ${PATH_SERVER}/crl.pem
                cp ${PATH_SERVER}/easy-rsa/pki/crl.pem ${PATH_SERVER}/crl.pem
                # CRL is read with each client connection, when OpenVPN is dropped to nobody
                chown "nobody:nogroup" ${PATH_SERVER}/crl.pem
                echo
                echo "$client revoked!"
            else
                echo
                echo "$client revocation aborted!"
            fi
            exit
            ;;
        3)
            echo
            read -p "Confirm OpenVPN removal? [y/N]: " remove
            until [[ "$remove" =~ ^[yYnN]*$ ]]; do
                echo "$remove: invalid selection."
                read -p "Confirm OpenVPN removal? [y/N]: " remove
            done
            if [[ "$remove" =~ ^[yY]$ ]]; then
                # 删除配置文件
                systemctl disable --now openvpn-iptables.service
                rm -f /etc/systemd/system/openvpn-iptables.service
                systemctl disable --now openvpn-server@server.service
                rm -f /etc/systemd/system/openvpn-server@server.service.d/disable-limitnproc.conf
                rm -f /etc/sysctl.d/99-openvpn-forward.conf

                # 卸载软件
                rm -rf ${PATH_SERVER}
                apt-get remove --purge -y openvpn
                echo
                echo "OpenVPN removed!"
            else
                echo
                echo "OpenVPN removal aborted!"
            fi
            exit
            ;;
        4)
            exit
            ;;
    esac
}

if [[ -z "$(dpkg -l|grep -E 'ii\s+openvpn')" ]]; then
    PATH_SERVER="/opt/local/openvpn/etc/server"
    install_openvpn
else
    PATH_SERVER="$(grep -E '/server$' /var/lib/dpkg/info/openvpn.list)"
    manage_openvpn
fi