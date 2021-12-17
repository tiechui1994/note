# 常用的环境搭建

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
# 客户端
sudo route add -net 192.168.1.0/24 gw 172.31.1.1 metric 1
```

NAT:
```
# 服务端
sudo iptables -t nat -A POSTROUTING -s 172.31.1.0/24 -j SNAT --to-source 192.168.1.100
```

> 这里不需要设置DNAT, 原因在于当设置了SNAT之后, iptables会自动维护NAT表, 并将响应报文的目的地址自动转换回来.

> 注: 如果要想服务器也能访问客户端的局域网, 也需要进行上述操作, 只不过是相反的操作而已.


## L2TP VPN

- L2TP

L2TP(第2层隧道协议)是一种允许远程用户访问公共网络的隧道协议. L2TP允许点对点协议(PPP)会话在多个网络和链路上传输. L2TP
来源于微软的 PPTP 和思科的 L2F(Layer 2 Forwarding)技术. 因此, L2TP 具有 L2TP 的特性, 它结合了 PPTP 的控制和数据
通道, 并且运行在更快的UDP上.

当处于安全性考虑时, L2TP是更好的选择, 因为L2TP需要证书, 但是 PPTP 使用的是用户名+密码.

- IPsec

IPsec 是一套相关协议, 用于在IP数据包层进行加密安全通信. 

IPsec 在IP层使用两种协议来保护通信:

1) 认证头(AH), 用于验证IP数据包来源和验证其内容完整性的安全协议.

2) 封装安全负载(ESP), 用于加密整个IP数据包(并认证其内容)的安全协议.

IPsec 通道协商. 有两种不同模式用于确定如何在VPN中交换数据流:

1) 传输模式 - 在已建立 IPsec 隧道的两台主机之间直接发送数据包, 保护数据流. 也就是说, 当通信端点和加密端点相同时, IP数
据包的数据部分已加密, 但不加密IP报头. 为受保护的主机提供加密和解密服务的VPN网关无法对受保护的VPN通信使用传输模式. 当数据
包被拦截时, 源或目的地的IP地址可以进行修改. 基于这种结构, 传送模式只能在通信端点和加密端点相同时才能使用. End-to-End

2) 隧道模式 - 通过将原始IP数据包封装在VPN隧道中的另一个数据包中, 保护数据流. 此模式使用预先共享密钥(PSK)与IKE一起认证
对等方. 这是独立专用网络内的主机通过公共网络进行通信最常用的方式. 此模式可供VPN客户端和VPN网关使用, 并保护在非IPsec系统
之间来回通信. Site-to-Site

- IKE

IKE(Internet密钥交换)协议是通信双方建立安全连接的协议. 它是基于UDP 500端口号的应用层协议. IKE提供了多种身份验证方式,
最常见的是预共享密钥(PSK)验证, 基于证书的身份验证.


### 安装依赖服务 ppp, xl2tpd, libreswan

xl2tpd 实现了 L2TP 协议. libreswan 实现了 IPsec.

IPsec 用于 VPN 协议本身配置的 IKE(因特网密钥交换)协议. 术语 IPsec 和 IKE 可以互换使用. IPsec VPN 也称为 IKE VPN,
IKEv2 VPN, XAUTH VPN, Cisco VPN 或 IKE/IPsec VPN. 使用 L2TP 的 IPsec VPN的变体称为 L2TP/IPsec VPN. 它需要
可选通道 xl2tpd 应用程序. 


```bash
sudo apt-get update && \
sudo apt-get install xl2tpd ppp libreswan -y --no-install-recommends --no-upgrade
```

### 服务配置

- xl2tpd 配置文件: /etc/xl2tpd/xl2tpd.conf

```
[global]								
  port = 1701                           ; bind port to  1701
  auth file = /etc/ppp/chap-secrets     ; auth secret file
  access control = yes				    ; refuse connections without IP match
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
pppoptfile = /etc/ppp/xl2tpd-options    ; ppp 的 option 选项文件
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

- ipsec 配置文件: /etc/ipesc.conf

ipesc.conf 文件由三种不同的节类型组成: `config setup` 定义一般参数, `conn <name>` 定义一个连接. `ca <name>` 定
义证书. 其中 `config setup` 只能有一个. 但是 `conn <name>` 和 `ca <name>` 可以有多个.

属于一个section的所有参数必须至少缩进一个空格或制表符. 

> 为了简化配置, 使用 left 和 right 表示一个连接的参与者. 一般情况下, 本地端使用 left, 远程端使用 right  

通用 section 参数:

```
# 表示当前的 section 可以继承 <section name> 当中提供的属性. <section name> 必须出现在当前 section 的前面.
also = <section name>
```

conn 常用参数:

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
  # 要限制连接到特定范围的主机, 可以指定范围(10.1.0.0-10.2.0.100) 或子网 (10.1.0.0/16), 多个地址, 范围和子网可以
  # 使用逗号分隔. 虽然这些可以自由组合, 但要发起连接, 至少需要一个 non-range/subnet.
  # fqdn 或 ip address, 则隐式设置 leftallowany=yes
  # 
  left = <ip address> | <fqdn> | %any | <range> | <subnet>
  
  
  leftid = 10.1.1.1 # 左侧参与者身份标识. 默认是left. 可以是IP地址或以@开头的完全限定性域名. 如果值是 %fromcert,
                    # ID值是从加载的证书中获取DN. 如果值是 %none, 表示不设置ID.
  
  
  # 两个安全网关应该如何相互认证, 可接受的值:
  # 共享机密密钥 secret,
  # RSA 数字签名的 rsasig(默认值), 
  # secret|rsasig 同时使用, 
  # 永远不会尝试或接受协商(仅用于分流连接) never.
  authby = secret | rsasig | never
  
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
  
  # 某些情况下, 例如当 ESP 数据包被过滤或当一个损坏的 IPsec 对等体不能正确识别 NAT 时, 强制 RFC-3948 封装可能很有用.
  # forceencaps=yes 强制 NAT 检测代码撒谎并告诉远程对等方需要 RFC-3948 封装(UDP 端口 4500 数据包中的 ESP).
  # 要使此选项生效, 需要设置设置选项 nat_traversal=yes. 可接受的值为 yes 或 no(默认值).
  forceencaps = yes | no
```

案例配置:

```
version 2.0

config setup
  virtual_private=%v4:10.0.0.0/8,%v4:192.168.0.0/16,%v4:172.16.0.0/12,%v4:!192.168.42.0/23
  interfaces=%defaultroute
  uniqueids=no
  nat_traversal=yes
  protostack=auto

conn shared
  left=172.17.0.2
  leftid=115.238.53.210
  right=%any
  forceencaps=yes
  authby=secret
  ikev2=never
  ike=3des-sha1,3des-sha2,aes-sha1,aes-sha1;modp1024,aes-sha2,aes-sha2;modp1024,aes256-sha2_512
  phase2alg=3des-sha1,3des-sha2,aes-sha1,aes-sha2,aes256-sha2_512
  pfs=no
  rekey=no
  keyingtries=5
  dpddelay=15
  dpdtimeout=30
  dpdaction=clear
  sha2-truncbug=yes

conn l2tp-psk
  type=transport
  auto=add
  leftprotoport=17/1701
  rightprotoport=17/%any
  auth=esp
  also=shared

conn xauth-psk
  type=tunnel
  auto=add
  leftsubnet=0.0.0.0/0
  rightaddresspool=192.168.43.10-192.168.43.250
  modecfgdns="8.8.8.8 8.8.4.4"
  leftxauthserver=yes
  rightxauthclient=yes
  leftmodecfgserver=yes
  rightmodecfgclient=yes
  modecfgpull=yes
  ikev2=never
  cisco-unity=yes
  also=shared

conn ike2-rsa
  auto=add
  left=%defaultroute
  leftid=115.238.53.210
  leftcert=115.238.53.210
  leftsendcert=always
  leftsubnet=0.0.0.0/0
  leftrsasigkey=%cert
  right=%any
  rightid=%fromcert
  rightaddresspool=192.168.43.10-192.168.43.250
  rightca=%same
  rightrsasigkey=%cert
  narrowing=yes
  dpddelay=30
  dpdtimeout=120
  dpdaction=clear
  ikev2=insist
  rekey=no
  pfs=no
  ike=aes256-sha2,aes128-sha2,aes256-sha1,aes128-sha1
  phase2alg=aes_gcm-null,aes128-sha1,aes256-sha1,aes128-sha2,aes256-sha2
  ikelifetime=24h
  salifetime=24h
  encapsulation=yes
  modecfgdns="8.8.8.8 8.8.4.4"
  mobike=no
```

- ipesc密钥配置: /etc/ipsec.secrets

该文件里包含多个key. 其中的key类型可以是:

```
RSA, 定义一个RSA私钥
ECDSA, 定义一个ECDSA私钥
PSK, 定义一个预共享密钥
XAUTH, 定义一个XAUTH凭证
```

每个密钥前面有一个可选的ID选择器列表. 这两部分使用冒号(:)分隔. 如果未指定ID选择器, 则该行必须以冒号开头.

选择器包含: IP地址, 完全限定域名, 域名, user@FQDN, %any.

```
# 使用 ip 地址 
10.1.0.1 10.2.0.1: PSK "secret shared"

# 使用 ip 地址, %any
112.113.114.115  %any: PSK "secret shared"

# 使用 %any, 域名
%any  gateway.domain.com: PSK "secret shared"

# 域名, ip 地址
www.xs.nl @www.vax.ru
    10.1.0.1 10.2.0.1 10.3.0.1: PSK "secret shared"

# RSA 私有密钥
@my.com : RSA "rsa private key"

# XAUTH 凭证
@username: XAUTH "password"

include ipsec.*.secrets
```

案例:
```
112.113.114.115  %any: PSK "1234567890"
```

- VPN账号文件: /ect/ipsec.d/passwd

```
admin:$1$P3Q2MST/$MjcjDrMUokEltHzYqSxTt0:xauth-psk
```

在 passwd 每一行是一个 VPN 账号, 其包含三部分, 分别是 username, password, conn_name. 使用冒号(:)进行分隔.

password 是加盐哈希值. 加盐哈希命令 `openssl passwd -1|-5|-6 PASSWORD`, 其中使用 `-1` 表示使用 MD5 哈希, `-5` 
是使用 SHA-256 哈希, `-6` 是使用 SHA-512 哈希.

conn_name 是在 /etc/ipsec.conf 当中　`conn <name>`　当中的 <name>.


- VPN账号文件: /etc/ppp/chap-secrets

```
admin l2tpd 12345678 *
```

在 chap-secrets 的每一行是一个 VPN 账号, 其格式为: `client server secret ip`, client是VPN client的用户名, 
server 是在 xl2tpd 当中 `name` 配置的标识符号. secret 是 VPN client的用户名对于的密码. ip 是 VPN client 对应
分配的IP地址.

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