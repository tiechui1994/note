# VPN 环境

## PPTP VPN

PPTP(点对点隧道协议) 是一种用于通过 Internet 创建虚拟专用网络的方法. 它是由微软开发的. 通过使用它, 用户可以从支持该协
议的任何 Internet 服务商访问公司网络. PPTP 工作在 OSI 模型的数据链路层(二层).

PPTP 中, 控制流和数据流是分开的. 控制流通过TCP, 数据流通过GRE(通用路由封装协议). 这使得 PPTP 对防火墙不太友好, 因为
通常不支持GRE.


### 安装依赖服务包 ppp, pptpd

```bash
sudo apt-get update && \
sudo apt-get install pptpd ppp -y --no-install-recommends --no-upgrade
```

### 配置(服务配置与账号配置)

服务配置, 配置文件为: `/etc/pptpd.conf`

账号配置, 配置文件为: `/etc/ppp/chap-secrets`, `/etc/ppp/pptpd-options` 等.

- 服务配置:

```
###############################################################################
# $Id: pptpd.conf,v 1.11 2011/05/19 00:02:50 quozl Exp $
#
# Sample Poptop configuration file /etc/pptpd.conf
#
# Changes are effective when pptpd is restarted.
###############################################################################

# TAG: ppp
#	Path to the pppd program, default '/usr/sbin/pppd' on Linux
ppp /usr/sbin/pppd

# TAG: option
#	Specifies the location of the PPP options file.
#	By default PPP looks in '/etc/ppp/options'
option /etc/ppp/pptpd-options

# TAG: debug
#	Turns on (more) debugging to syslog
debug

# TAG: stimeout
#	Specifies timeout (in seconds) on starting ctrl connection
#stimeout 10

# TAG: noipparam
#   Suppress the passing of the client's IP address to PPP, which is done by default otherwise.
#noipparam

# TAG: logwtmp
#	Use wtmp(5) to record client connections and disconnections.
#logwtmp

# TAG: vrf <vrfname>
#	Switches PPTP & GRE sockets to the specified VRF, which must exist
#	Only available if VRF support was compiled into pptpd.
#vrf test

# TAG: bcrelay <if>
#	Turns on broadcast relay to clients from interface <if>
#bcrelay eth1

# TAG: delegate
#	Delegates the allocation of client IP addresses to pppd.
#
#   Without this option, which is the default, pptpd manages the list of
#   IP addresses for clients and passes the next free address to pppd.
#   With this option, pptpd does not pass an address, and so pppd may use radius or chap-secrets to
#   allocate an address.
#delegate

# TAG: connections
#   Limits the number of client connections that may be accepted.
#
#   If pptpd is allocating IP addresses (e.g. delegate is not used) then the number of connections
#   is also limited by the remoteip option.  The default is 100.
#connections 100

# TAG: localip
# TAG: remoteip
#	Specifies the local and remote IP address ranges.
#
#	These options are ignored if delegate option is set.
#
#       Any addresses work as long as the local machine takes care of the
#       routing.  But if you want to use MS-Windows networking, you should
#       use IP addresses out of the LAN address space and use the proxyarp
#       option in the pppd options file, or run bcrelay.
#
#	You can specify single IP addresses seperated by commas or you can
#	specify ranges, or both. For example:
#
#		192.168.0.234,192.168.0.245-249,192.168.0.254
#
#	IMPORTANT RESTRICTIONS:
#
#	1. No spaces are permitted between commas or within addresses.
#
#	2. If you give more IP addresses than the value of connections,
#	   it will start at the beginning of the list and go until it
#	   gets connections IPs.  Others will be ignored.
#
#	3. No shortcuts in ranges! ie. 234-8 does not mean 234 to 238,
#	   you must type 234-238 if you mean this.
#
#	4. If you give a single localIP, that's ok - all local IPs will
#	   be set to the given one. You MUST still give at least one remote
#	   IP for each simultaneous client.
#
# (Recommended)
localip 172.31.1.1
remoteip 172.31.1.100-200
```

这里重点说明以下几个 tag:

1) localip, remoteip.

localip 表示给服务器分配的ip地址(服务器指的是vpn server).

remoteip 表示分配给客户端的ip地址(客户端指的是vpn client), 要和服务器的ip处于同一网段.

> 注: 这里选择的 localip, remoteip 不要和客户端本身的ip地址段冲突.

> 注: 如果设置了 delegate 选项, localip, remoteip 将被忽略.

可以使用逗号分隔单个ip地址, 也可以使用范围, 或同时指定两者. 例如: 192.168.1.10,192.168.1.20-30,192.168.1.100

注意, 逗号之间或地址之间不能有空格; 如果提供的ip地址比连接的值多, 它将从列表的开头开始, 直到获取连接ip, 其他的将被忽略;
如果设置了单个 localip, 它没有问题, 但是必须为每个客户端至少提供一个 remoteip, 言外之意就是, localip可以是单个ip,
但是 remoteip 必须是多个.

2) delegate

将客户端ip地址的分配委托给 pppd.

如果停用该选项(默认), pptpd 会管理客户端的 ip 地址列表, 并将下一个空闲地址传递给 pppd.

如果开启该选项, pptpd 不传递地址, 因此 pppd 可以使用 radius 或 chap-secrets 来分配地址.

3) option

指定 PPP 选项文件的位置. 默认选项文件是 `/etc/ppp/options`. 这里配置的是 `/etc/ppp/pptpd-options`, 在该文件当中
可以配置更多的选项.

4) ppp

pppd 程序的路径, 对于手动编译的选项则需要指定.

- option 选项配置

下面是 `/etc/ppp/pptpd-options` 文件的配置.

```
# Authentication
name pptpd

# Network and Routing
ms-dns 114.114.114.114
ms-dns 8.8.8.8
proxyarp
nodefaultroute

# Logging
debug
dump

# Miscellaneous
lock
nobsdcomp
novj
novjccomp
nologfd
```

重要的 tag:

1) name

用于身份验证的本地系统名称. 必须匹配 `/ect/ppp/chap-secrets` 中条目的第二个字段.

2) refuse-pap, refuse-chap, refuse-mschap, require-mschap-v2, require-mppe-128, require-chap

auth 加密方式

require-mschap-v2, 要求对端使用 MS-CHAPv2(Microsoft Challenge Handshake Authentication Protocol) 进行身
份认证.

require-mppe-128, 使用 MPPE 128 位加密(注: MPPE需要在认证时使用 MS-CHAPv2). 手机客户端, 一般使用的是该认证方式.

3) ms-dns, ms-wins

配置 dns 域名服务器

4) lock

为伪tty创建一个UUCP风格的锁文件, 保证独占访问.

- 账号配置

连接VPN的账号配置. 文件位于 `/etc/ppp/chap-secrets`, 每一行为一个条目. 格式如下:

```
client server secret ip 
```

其中 server 就是在 `/etc/ppp/pptpd-options` 当中的 `name` 配置的名称. client是客户端用户名, secret是客户端的
密码, ip 是客户端是ip地址(如果是任意地址, 可以写"*")

### 设置内核参数和防火墙

- 内核参数

在文件 `/etc/sysctl.conf` 当中开启:

```
net.ipv4.ip_forward = 1
```

然后执行 `sudo sysctl -p`


- 防火墙(NAT转发, 网络设置)

```
cat > /etc/iptables.firewall.rules <<- 'TABLE'
iptables -t nat -A POSTROUTING -s 172.31.1.1/24 -o eth0 -j MASQUERADE
iptables -t filter -A FORWARD -s 172.31.1.1/24 -p tcp -m tcp --tcp-flags SYN,RST SYN -j TCPMSS --set-mss 1200
TABLE
```

然后执行 `sudo iptables-restore < /etc/iptables.firewall.rules`

### 服务重启并测试

重启服务:

`sudo systemctl status pptpd.service`

检查服务运行状态:

`sudo netstat -ntlp | grep 1723`

如果出现了条目, 则正常运行.

测试:

![image](/images/develop_env_pptpd_test.jpeg)

Linux 下测试:

1. 安装客户端软件
```
sudo apt-get install pptp-linux
```

2. 增加 ppp 连接配置文件 `/etc/ppp/peers/ppptest`
```
name <user>
password <password>
remotename pptpd
noauth
lock
proxyarp
debug
defaultroute
persist
pty "pptp <serverip> --nolaunchpppd --debug"
```

> proxyarp, noproxyarp
> proxyarp 是在本系统的 ARP `[地址解析协议]` 表中添加一个条目, 其中包含对等方的IP地址和本系统的以太网地址. 这将使对
> 等点在其他系统看来位于本地以太网上.
>
> defaultroute, nodefaultroute
> defaultroute, 当IPCP协商成功之后, 将默认路由添加到系统路由表中, 以对等端作为 gateway. 当 PPP 连接中断时, 此条目
被删除.
>
> replacedefaultroute
> replacedefaultroute, 此选项是 defaultroute 选项的标志. 如果设置了 defaultroute 并且也设置了该标志, pppd 会
用新的默认路由替换现有的默认路由.

[pppd选项](http://man.he.net/man8/pppd)


3. 启动/关闭连接
```
sudo pon ppptest
sudo poff ppptest
```

4. NAT和ROUTE配置

假设: 服务器的局域网是 192.168.1.0/24 网段. ip地址 192.168.1.100.

为了使得使得**客户端可以访问服务器局域网内的其他设备**, 需要做以下配置:

ROUTE:
```
# 客户端, 访问服务器内的其他设备
sudo route add -net 192.168.1.0/24 gw 172.31.1.1 metric 1

# 客户端, 访问其他VPN设备(可选, 一般可以不设置)
sudo route add -net 172.31.1.0/24  gw 172.31.1.1 metric 1
```

NAT:
```
# 服务端
sudo iptables -t nat -A POSTROUTING -s 172.31.1.0/24 -j SNAT --to-source 192.168.1.100
```

> 这里不需要设置DNAT, 原因在于当设置了SNAT之后, iptables会自动维护NAT表, 并将响应报文的目的地址自动转换回来.

> 注: 如果要想服务器也能访问客户端的局域网, 也需要进行上述操作, 只不过是相反的操作而已.


## IKEv2 VPN

### 安装依赖服务 strongswan

```bash
wget https://github.com/tiechui1994/jobs/releases/download/strongswan_5.9.0/strongswan_5.9.0_ubuntu_18.04_amd64.deb
sudo dpkg -i strongswan_5.9.0_ubuntu_18.04_amd64.deb
```

### 服务配置

- 生成秘钥

```
# ca.crt =>  cacerts
# ca.key => private
# server.crt => certs
# server.key => private
# client.crt => certs
# client.key => private

# CA 证书 Subject
# C country 
# O organization
# CN common name
```

生成证书脚本: https://github.com/tiechui1994/note/blob/master/develop/ikev2.sh

- ipsec 配置文件: /opt/local/strongswan/etc/ipesc.conf

ipesc.conf 文件由三种不同的节类型组成: `config setup` 定义一般参数, `conn <name>` 定义一个连接. `ca <name>` 定
义证书. 其中 `config setup` 只能有一个. 但是 `conn <name>` 和 `ca <name>` 可以有多个.

属于一个section的所有参数必须至少缩进一个空格或制表符. 

> 为了简化配置, 使用 left 和 right 表示一个连接的参与者. 一般情况下, 本地端使用 left, 远程端使用 right  

通用 section 参数:

```
# 表示当前的 section 可以继承 <section name> 当中提供的属性. <section name> 必须出现在当前 section 的前面.
also = <section name>
```

[ipsec.conf文件配置选项](https://linux.die.net/man/5/ipsec.conf)

[strongswan conn配置选项](https://wiki.strongswan.org/projects/strongswan/wiki/connsection)

conn 特别关键的选项参数:

```
conn shared
  # 连接类型. 可选的值包括:
  # tunnel(默认值), 隧道, 表示 host-to-host, host-to-subnet, subnet-to-subnet 隧道模式
  # transport, 传输, 表示 host-to-host 的传输模式
  # passthrough, 直达, 表示不适应IPsec处理
  # drop, 丢弃, 表示丢弃该数据包
  # reject, 拒绝, 表示丢弃数据包并返回ICMP包
  type = tunnel | transport | passthrough | drop | reject
  
  # IPsec 启动时应该执行哪些操作. 可选的值包括:
  # add, 表示 ipsec auto --add
  # route, 表示 ipsec auto --route
  # start, 表示 ipsec auto --up
  # manual, 表示 ipsec manual --up
  # ignore(默认值), 忽略, 表示没有自动启动操作
  # 对于打算长久建立连接, 两端都应使用 auto=start 以确保任何重启都会重新协商.
  auto = add | route | start | manual | ignore
  
  # 左侧参与者的公共网络接口的IP地址或几个特殊值.
  # %any(默认值), 表示在协商期间填充地址. 如果本地发起连接, 则查询路由表确定正确的本地IP地址, 如果本地响应连接, 则接受
  # 分配给本地连接网卡的任何IP地址.
  #
  # %defautroute, 连接路由
  # 
  # 要限制连接到特定范围的主机, 可以指定范围(10.1.0.0-10.2.0.100) 或子网 (10.1.0.0/16), 多个地址, 范围和子网可以
  # 使用逗号分隔. 虽然这些可以自由组合, 但要发起连接, 至少需要一个 non-range/subnet.
  # fqdn 或 ip address, 则隐式设置 leftallowany=yes
  left = <ip address> | <fqdn> | %any | <range> | <subnet>
  
  # 左侧参与者身份标识. 默认是 left 或 leftcert 证书的 subjectAltName. 
  # 如果配置了 leftcert, 则身份必须由证书确认. 也就是说, 它必须匹配证书当中 subject DN 或 扩展 subjectAltName.
  # 值也可以是IP地址, 完全限定性域名, 电子邮件地址(以@开头)或可识别名称. 
  #
  # 对于 IKEv2 和 rightid, 身份前面的前缀 % 会阻止守护进程在其 IKE_AUTH 请求中发送 IDr, 并允许它根据响应者证书中包
  # 含的 subject 和 subjectAltNames 验证配置的身份（否则它只会与 IDr 进行比较响应者返回）.
  # 如果响应者为 leftid 配置了不同的值, 则发起者发送的 IDr 可能会阻止响应者找到配置.
  leftid = <id>
  
  # 在隧道中使用的内部源IP, 也称为虚拟IP. 
  # 只在本地相关, 另一端不必同意. 此选项用于使网关本身使用其内部 IP (它是 leftsubnet 的一部分) 与  rightsubnet 通
  # 信. 否则, 它将使用其最近的 IP 地址, 即其公共 IP 地址.
  # 该选项主要在定义subnet-subnet连接时使用, 以便网关可以相互通信以及与另一端的子网通信. 而无需构建额外的host-subnet,
  # subnet-host和host-host隧道. 支持 IPv4 和 IPv6 地址.
  leftsourceip = %config4 | %config6 | <ip address>
  
  # 左侧参与者后面的私有子网, 表示为network/netmask形式. 目前, 支持 IPv4 和 IPv6 范围.
  # 如果省略, 假设为 left/32, 表示连接的左端仅到达左参与者.
  leftsubnet = network/netmask
  
  # 左参与者后面指定多个私有子网, 表示为 { networkA/netmaskA networkB/netmaskB [...] } 
  # 如果同时定义了 leftsubnets= 和 rightsubnets=, 则子网隧道的所有组合都将被实例化.
  # 不能同时使用 leftsubnet 和 leftsubnets.
  leftsubnets = { network/netmask network/netmask }
  
  # 本地(left)或远程(right)要求的身份认证方法. 可接受的值:
  # pubkey, 用于公钥认证(RSA/ECDSA)
  # psk, 用于预共享密钥认证
  # eap, 用于 IKEv2 的可扩展协议.
  # xauth, 用于 IKEv1 的可扩展协议.
  #
  # 对于 eap, 可以附加一个可选的 EAP 方法. 当前定义的方法有 eap-tls, eap-tnc, eap-tnc, eap-md5, eap-ttls,
  # eap-dynamic, eap-radius, eap-identity, eap-peap.
  #
  # EAP(用户名/密码). [eap-md5]
  # CERT [pubkey]
  # CERT + EAP(用户名/密码). [pubkey + eap-md5]
  # EAP-TLS. [eap-tls]
  # EAP-ENC(用户名/密码). [eap-enc]
  #
  # 对于 EAP(用户名/密码), 需要在 ipsec.secrets 当中的 EAP 类型定义.
  # 注: 上述的认证方法, 需要在编译 strongSwan 的时候要启用的 plugin, 否则, 在实际当中旧无法使用.
  #
  leftauth = <auth method>
  
  # 左侧参与者的 X509 证书路径. 该文件可以采用 PEM 或 DER 格式进行编码. 也支持 OpenPGP 证书. 绝对路径或相对于 etc/
  # ipsec.d/certs 的路径被接受. 默认情况下, leftcert 将 leftid 设置为证书subject的名称. 但是, 可以通过指定由证书
  # 认证的 leftid 值来覆盖.
  leftcert = path
  
  # 接受的值是 never 或 no, always 或 yes 以及 ifasked(默认值), 后者意味着对方必须发送证书请求才能获得证书.
  leftsendcert = never | no | ifasked | always | yes
  
  # 证书颁发机构的专有名称, 它位于左侧参与者的证书根证书(cacerts)颁发机构的信任路径中. %same 意味着重用右侧配置的值.
  leftca = <issuer dn> | %same
  
  # 使用默认的 ipsec _updown 脚本插入一对 INPUT 和 OUTPUT iptables 规则, 从而在主机的内部接口是协商客户端子网的
  # 一部分的情况下允许访问主机本身. 可接受的值为 yes 和 no(默认值).
  lefthostaccess = yes | no
  
  # ike 第一阶段中的加密/认证算法. 格式: "cipher-hash;modpgroup,cipher-hash;modpgroup,...". 任何缺失的选项都
  # 将填充允许的默认选项. 使用逗号进行分隔.
  ike = 3des-sha1,3des-sha2,aes-sha1,aes-sha1;modp1024
  
  # 指定第二阶段中支持的算法. 算法之间用逗号分隔. 默认值与 ike 指定的值相同.
  phase2alg = 3des-sha1,3des-sha2
  
  # 在连接的密钥通道上是否需要密钥的PFS(Perfect Forward Secrecy,完全向前保密), (使用 PFS, 密钥交换协议的泄密不会
  # 危及之前协商的密钥);
  # 可接受的值: yes(默认值)和no.
  pfs = yes | no
  
  # 连接即将到期时是否应重新协商. 可接受的值为yes(默认值)和no. 
  rekey = yes | no
  
  # 即使未检测到 NAT 情况, 也强制对 ESP 数据包进行 UDP 封装. 这有助于克服防火墙的限制. 
  forceencaps = yes | no
  
  # 是否使用 IKE 分段. 可选值: 
  # yes(默认), 如果对端也支持IKE分段, 则将分段发送过大的IKE消息.
  # accept, 会告知对端支持分段, 但是守护进程不会使用分段发送自己的消息.
  # no, 禁止使用IKE分段发送消息.
  # 
  # 注:无论此选项值如何, 始终接受对对方发送的分段IKE消息.
  fragmentation = yes  | accept | force | no
  
  # 应该使用哪种密钥交换协议来启动连接. ike 表示连接在启动时使用 IKEv2, 但在响应时接受任何协议版本.
  keyexchange = ike | ikev1 | ikev2
  
  # 定义客户端用于回复EAP身份请求的身份. 如果在EAP服务器上定义, 则定义的身份在EAP身份验证期间使用对端的身份.
  # 特殊值 %identity 使用EAP身份方法向客户端询问EAP身份. 如果未定义, 使用 IKEv2 身份作为 EAP 身份.
  eap_identity = <id>
```

案例配置:
```
version 2.0

config setup
  uniqueids=no
  charondebug="cfg 2, net 2, enc 2, ike 2, tls 2"

conn iOS_cert
    auto=add
    keyexchange=ikev1
    fragmentation=yes
    left=%defaultroute
    leftauth=pubkey
    leftsubnet=0.0.0.0/0
    leftcert=server.crt
    right=%any
    rightauth=pubkey
    rightauth2=xauth
    rightsourceip=10.31.2.0/24
    rightcert=client.cert.pem

conn android_xauth_psk
    auto=add
    keyexchange=ikev1
    type=tunnel
    left=%defaultroute
    leftauth=psk
    leftsubnet=0.0.0.0/0
    right=%any
    rightauth=psk
    rightauth2=xauth
    rightsourceip=10.31.2.0/24

conn ikev2
    auto=add
    type=tunnel
    keyexchange=ikev2
    eap_identity=%identity
    fragmentation=yes
    forceencaps=yes
    rekey=no
    left=%any
    leftid=vpn-server.com
    leftcert=server.crt
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=eap-tls
    rightsourceip=%dhcp
    rightsendcert=never

conn ios_ikev2
    auto=add
    eap_identity=%any
    fragmentation=yes
    keyexchange=ikev2
    ike=aes256-sha256-modp2048,3des-sha1-modp2048,aes256-sha1-modp2048!
    esp=aes256-sha256,3des-sha1,aes256-sha1!
    rekey=no
    left=%defaultroute
    leftid=vpn-server.com
    leftcert=server.crt
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightauth=eap-mschapv2
    rightsourceip=10.31.2.0/24
    rightsendcert=never

conn windows
    auto=add
    keyexchange=ikev2
    eap_identity=%any
    ike=aes256-sha1-modp1024!
    rekey=no
    left=%defaultroute
    leftid=vps.server.com
    leftcert=server.crt
    leftauth=pubkey
    leftsubnet=0.0.0.0/0
    right=%any
    rightauth=eap-mschapv2
    rightsourceip=10.31.2.0/24
    rightsendcert=never
```

- ipesc密钥配置: /opt/local/strongswan/etc/ipsec.secrets

该文件里包含多个key. 其中的key类型可以是:

```
RSA, 定义一个RSA私钥
ECDSA, 定义一个ECDSA私钥
PSK, 定义一个预共享密钥
XAUTH, 定义一个XAUTH凭证
EAP, 定义 EAP 的账号密码
```

每个密钥前面有一个可选的ID选择器列表. 这两部分使用冒号(:)分隔. 如果未指定ID选择器, 则该行必须以冒号开头.

选择器包含: IP, DOMAIN, @DOMAIN, %any.

```
# 使用 ip 地址 
10.1.0.1 10.2.0.1: PSK "secret shared"

# 使用 ip 地址, %any
112.113.114.115  %any: PSK "secret shared"

# 使用 %any, 域名
%any gateway.domain.com: PSK "secret shared"

# 域名, ip 地址
www.xs.nl @www.vax.ru 10.1.0.1 10.2.0.1 10.3.0.1: PSK "secret shared"

# RSA 密钥
@my.com : RSA "rsa private key"

# PSK 
: PSK "pskkey"

# XAUTH 账号
@username: XAUTH "password"

# EAP 账号
"username" %any : EAP "password"

include ipsec.*.secrets
```

案例:
```
: RSA server.pem
: PSK "myPSKkey"
: XAUTH "myXAUTHPass"
myUserName %any : EAP "myUserPass"
```

- strongswan配置: /opt/local/strongswan/etc/strongswan.conf

```
# 本地使用的 UDP 端口. 如果设置为 0, 将分配一个随机端口.
charon.port = 500         

# 在 NAT-T 的情况下本地使用的 UDP 端口. 如果设置为 0, 将分配一个随机端口.
# 必须与 charon.port 不同, 否则将分配一个随机端口.
charon.port_nat_t = 4500  
```

案例:
```
charon {
    load_modular = yes
    duplicheck {
            enable = no
    }
    compress = yes
    plugins {
            include strongswan.d/charon/*.conf
    }
    dns1 = 8.8.8.8
    dns2 = 8.8.4.4
    nbns1 = 8.8.8.8
    nbns2 = 8.8.4.4
}
include strongswan.d/*.conf
```

### 设置内核参数和防火墙

- 内核参数

在文件 `/etc/sysctl.conf` 当中开启:

```
net.ipv4.ip_forward = 1
```

然后执行 `sudo sysctl -p`

### 测试

Android客户端:

[strongSwan](https://download.strongswan.org/Android/)

连接的基本过程:

1. IKE_SA_INIT, 进行协商密码算法, 交换 nonces 和 DH 算法. 生成 SKEYSEED, 后续的消息使用密钥进行加密和验证. 

2. IKE_AUTH. 交换身份和证书, 并建立第一个 CHILD_SA. 这些消息是加密和完整的. 对于 server 端, 先需要需要选择一个 conn
配置, 然后根据配置进行身份认证和证书认证.(这一步最关键, 也是最容易出问题的步骤, 出问题了可以通过设置 `charondebug` 开
启debug消息.)

## OpenVPN

安装配置脚本: https://github.com/tiechui1994/note/blob/master/develop/openvpn.sh

- 服务端配置文件: server/server.conf

重要的参数:

```
# 本地IP地址
local IP

# 监听的端口号. 默认是 1194
port PORT

# 使用的协议. 默认的udp
proto udp|tcp

# CA证书, Server证书/密钥, DH参数, CRL证书校验(这些文件都在 server 目录下)
#  
# dh, PEM 格式的 DH 参数文件(仅在设置 tls-server 时有效). 如果设置为 none 表示禁止 DH 密钥交换(仅使用ECDH), 这时
# 需要对等方支持 ECDH TLS 密码套件的SSL库. 可以使用 openssl dhparam -out dh.pem 2048 生成 2048 位的 DH 参数.
# 
# crl-verify, 根据 PEM 格式的文件检查对等方的证书. 当特定密钥被泄露但整个PKI仍然完整时, 可以使用CRL(证书撤销列表)
#
ca cacert
cert servercert
key keykey
dh file
crl-verify crl.pem


# tls-server, 在 TLS 握手期间启用 TLS 并承担 server 角色.
# tls-client, 在 TLS 握手期间启用 TLS 并承担 client 角色.
#
tls-server
tls-client 

# 使用来着 keyfile 的密钥加密和验证所有控制通道的数据包.
tls-crypt keyfile


# TUN/TAP 虚拟网络设备
# dev-type, 虚拟设备类型. tun 工作在三层, tap 工作在二层.
# dev, 虚拟设备名称. 如果 dev 的值是以 tun 或 tap 开头, 则相应的虚拟设备类型就是 tun 或 tap.
# 
dev-type tun|tap
dev tunX | tapX | null

# 简化服务器模式的配置. 该指令设置一个 OpenVPN 服务器, 该服务器将从给定的network/netmask为客户端分配ip. 服务器本身
# 使用网络的 ".1" 作为本地 TUN/TAP 网卡的服务器IP地址. 
#
server network netmask ['nopool']

# 在虚拟设备类型是 tun 时虚拟网络拓扑结构. 如果虚拟设备类型是 tap, 则它只能使用 subnet 拓扑.
# 
# net30, 点对点拓扑, 为每个客户端分配一个 /30 子网. 客户端是 windows 系统点对点语义.
#
# p2p,点对点拓扑, 其中客户端 tun 网卡的远程端点始终指向服务器的本地端点. 此模式为每个客户端分配一个IP地址. 仅在连接客户
# 端不是 windows 系统时使用.
#
# subnet, 通过使用本地 IP 地址和子网掩码配置 tun 网卡, 使用子网而不是点对点拓扑, 类似于 tap 当中的桥接模式的拓扑.
#  
topology net30|p2p|subnet


# 路由
route network/IP [netmask] [gateway] [metric]
```


案例:
```
local 192.168.1.100
port 1194
proto udp

dev tun
topology subnet
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 114.114.114.114"
keepalive 10 120

ca ca.crt
cert server.crt
key server.key
crl-verify crl.pem

dh dh.pem
tls-crypt tc.key
auth SHA512
cipher AES-256-CBC

user nobody
group nogroup
persist-key
persist-tun
explicit-exit-notify
verb 3
```

- 客户端配置文件: client/client.conf


### 客户端(Android)

[OpenVPN Client Free](https://apkpure.com/openvpn-client-free/it.colucciweb.free.openvpn)

[OpenVPN for Android](https://apkpure.com/openvpn-for-android/de.blinkt.openvpn)

