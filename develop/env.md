# 常用的环境搭建

## PPTP VPN(虚拟私有网络)搭建

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

## L2TP

L2TP(第2层隧道协议)是一种允许远程用户访问公共网络的隧道协议. L2TP允许点对点协议(PPP)会话在多个网络和链路上传输. L2TP
来源于微软的 PPTP 和思科的 L2F(Layer 2 Forwarding)技术. 因此, L2TP 具有 L2TP 的特性, 它结合了 PPTP 的控制和数据
通道, 并且运行在更快的UDP上.

当处于安全性考虑时, L2TP是更好的选择, 因为L2TP需要证书, 但是 PPTP 使用的是用户名+密码.


### 安装依赖服务 ppp, xl2tpd, libreswan

xl2tpd 实现了 L2TP 协议. libreswan 实现了 IPsec.

IPsec 用于 VPN 协议本身配置的 IKE(因特网秘钥交换)协议. 术语 IPsec 和 IKE 可以互换使用. IPsec VPN 也称为 IKE VPN,
IKEv2 VPN, XAUTH VPN, Cisco VPN 或 IKE/IPsec VPN. 使用 L2TP 的 IPsec VPN的变体称为 L2TP/IPsec VPN. 它需要
可选通道 xl2tpd 应用程序. 


```bash
sudo apt-get update && \
sudo apt-get install xl2tpd ppp libreswan -y --no-install-recommends --no-upgrade
```

### 服务配置

xl2tpd 配置文件: /etc/xl2tpd/xl2tpd.conf

```
[global]								
  port = 1701						 	; bind port to  1701
  auth file = /etc/l2tpd/l2tp-secrets 	; auth secret file
  access control = yes					; refuse connections without IP match
  rand source = dev                     ; 随机值的来源:
                                        ; dev - reads of /dev/urandom
                                        ; sys - uses rand()

[lns default]							; default LNS config
ip range = 192.168.42.10-192.168.42.50  ; 定义VPN客户端的地址段. remoteip
local ip = 192.168.42.1                 ; 定义VPN服务器的地址段. localip
require chap = yes                      ; Require CHAP auth
refuse pap = yes                        ; Refuse PAP auth
refuse chap = no                        ; Refuse CHAP auth
refuse authentication = no              ; 
require authentication = yes            ; 要求对等方进行身份验证
name = l2tpd                            ; 服务名称唯一标识
pppoptfile = /etc/ppp/xl2tpd-options   ; ppp 的 option 选项文件
length bit = yes                        ;
```

xl2tpd 的 option 配置文件: /etc/ppp/xl2tpd-options

```
ms-dns 8.8.8.8
ms-dns 8.8.4.4

noccp
auth
crtscts
lock

ipcp-accept-local
ipcp-accept-remote
lcp-echo-failure 4
lcp-echo-interval 30
```

> 注: ipcp-accept-local, ipcp-accept-remote 使用此选项, 即使 local/remote IP 地址已在选项中指定, pppd 也会
接受对等方对 local/remote IP 地址的连接.

ipsec 配置文件: /etc/ipesc.conf

```
version 2.0

config setup
  nat_traversal=yes
  virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!192.168.42.0/23
  protostack=netkey
  nhelpers=0
  interfaces=%defaultroute
  uniqueids=no

conn shared
  left=172.17.0.2
  leftid=115.238.53.210
  right=%any
  forceencaps=yes
  authby=secret
  pfs=no
  rekey=no
  keyingtries=3
  dpddelay=15
  dpdtimeout=30
  dpdaction=clear
  ike=3des-sha1,3des-sha2,aes-sha1,aes-sha1;modp1024,aes-sha2,aes-sha2;modp1024,aes256-sha2_512
  phase2alg=3des-sha1,3des-sha2,aes-sha1,aes-sha2,aes256-sha2_512
  sha2-truncbug=yes

conn l2tp-psk
  auto=add
  leftsubnet=172.17.0.2/32
  leftnexthop=%defaultroute
  leftprotoport=17/1701
  rightprotoport=17/%any
  type=transport
  auth=esp
  also=shared

conn xauth-psk
  auto=add
  leftsubnet=0.0.0.0/0
  rightaddresspool=192.168.43.10-192.168.43.250
  modecfgdns1=8.8.8.8
  modecfgdns2=8.8.4.4
  leftxauthserver=yes
  rightxauthclient=yes
  leftmodecfgserver=yes
  rightmodecfgclient=yes
  modecfgpull=yes
  xauthby=file
  ike-frag=yes
  ikev2=never
  cisco-unity=yes
  also=shared
```

ipesc秘钥配置: /etc/ipsec.secrets

该文件也就是"预共享秘钥", "X509数字证书".

针对预共享秘钥(PSK), X509数字证书(RSA,ECDSA,P12), 每个秘钥前面有一个可选的ID选择器列表. 这两部分使用冒号(:)分隔. 
如果未指定ID选择器, 则该行必须以冒号开头.

ID选择器包含: IP地址, 完全限定域名, 域名, user@FQDN, %any

```
# 使用 ip 地址 
10.1.0.1 10.2.0.1: PSK "secret shared"

# 使用 ip 地址, %any
115.238.53.210  %any: PSK "secret shared"

# 使用 %any, 域名
%any  gateway.domain.com: PSK "secret shared"

# 域名, ip 地址
www.xs.nl @www.vax.ru
    10.1.0.1 10.2.0.1 10.3.0.1: PSK "secret shared"

# RSA 私有秘钥
@my.com : RSA "rsa private key"

# X.509 证书

@username: XAUTH "password"

include ipsec.*.secrets
```

ipsec密码配置: /ect/ipsec.d/password


账号配置文件: /etc/ppp/chap-secrets

```
admin l2tpd password *
```

格式: `client server secret ip`, client是VPN client的用户名, server是在 xl2tpd 当中 `name` 配置的标识符号.
secret 是 VPN client的用户名对于的密码. ip 是 VPN client 对应的密码.

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