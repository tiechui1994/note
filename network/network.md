# 网络配置

## 网络IP配置 

大多数网络设置可以通过 `/etc/network/interfaces` 上的 interfaces 配置文件完成. 在这里, 可以为网卡提供IP address
(或使用dhcp), 设置route, 配置IP masquerading, 设置default routes等等.

> 记住将要在启动时启动的接口添加到 'auto' 行.


### DHCP 自动配置IP

```
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
```

### 手动配置IP

如果是手动配置它, 则类似以下内容将设置 default gateway(network, broadcast 和 gateway是可选的):

```
auto eth0
iface eth0 inet static
    address 192.168.0.7
    netmask 255.255.255.0
    gateway 192.168.0.254
```

### 设置速度与双工(duplex)

某些网络中, 无法进行自动协商. 如果必须手动设置接口的速度和双工, 则可能需要反复尝试. 以下是基本步骤:

- 安装 `ethtool` 和 `net-tools` 软件包. 以便拥有 `ethtool` 和 `mii-tool` 程序

- 尝试确定其当前速度和双工设置. 

1. 以 root 用户身份, 首先尝试 `ethtool eth0`, 然后查看 `Speed:` 和 `Duplex:` 行是否有效. 否则, 设备可能不支持
ethtool

2. 以 root 身份, 尝试 `mii-tool -v eth0`, 查看其输出是否正常.

## NetworkManager

NetworkManager 守护程序试图通过管理主网络连接和其他网络接口 (如以太网,Wi-Fi和移动宽带设备) 来使网络的配置和操作尽可能
轻松自如. 

当网络连接可用时, NetworkManager会连接该网络设备, 除非该行为被禁用.

为了响应网络事件, NetworkManager 将按字母顺序在 `/etc/NetworkManager/dispatcher.d` 目录或子目录中执行脚本. 每
个脚本应该是 `root` 权限可执行文件. 此外, 它允许 `group` 或 `other` 的用户写入.

每个脚本都接收两个参数, 第一个是操作发生的设备的接口名称, 第二个是操作. 对于设备操作, 该接口是适合IP配置的内核接口的名称.
因此, 如果适用, 它可以是 `VPN_IP_IFACE`, `DEVICE_IP_IFACE`, `DEVICE_IFACE`. 对于 `hostname` 设备名称始终为
"none", 对于 `connectivity-change` 该名称为空.

### Action

- **pre-up**

该 `interface` 已连接到网络, 但尚未完全激活. 必须将处理此事件的脚本放在 `dispatcher.d/pre-up.d` 目录中, 或将其符
号链接到 `dispatcher.d/pre-up.d` 目录中, NetworkManager 将等待脚本执行完成, 然后再向应用程序指示该接口已完全激活.

- **up**

`interface` 已激活.

- **pre-down**

该 `interface` 将被停用, 但尚未从网络断开连接. 必须将处理此事件的脚本放在 `dispatcher.d/pre-down.d` 目录中, 或将
其符号链接到 `dispatcher.d/pre-down.d` 目录中, NetworkManager 将等待脚本执行完成, 然后再将接口与其网络断开连接. 

- **down**

该 `interface` 已被禁用.

- **vpn-pre-up**

VPN已连接到网络, 但尚未完全激活. 必须将处理此事件的脚本放在 `dispatcher.d/pre-up.d` 目录中, 或将其符号链接到
`dispatcher.d/pre-up.d` 目录中, NetworkManager 将等待脚本执行完成, 然后向应用程序指示VPN已完全激活.

- **vpn-up**

VPN连接已激活.

- **vpn-pre-down**

VPN 将被停用, 但尚未从网络断开连接. 必须将处理此事件的脚本放在 `dispatcher.d/pre-down.d` 目录中, 或将其符号链接到 
`dispatcher.d/pre-down.d` 目录中, 并且 NetworkManager 将等待脚本执行完成, 然后再将VPN与其网络断开连接.

- **vpn-down**

VPN连接已停用.

- **hostname**

系统主机名已更新. 使用 `gethostname` 进行检索. 接口名称(第一个参数)为空, 并且未为此操作设置任何环境变量.

- **dhcp4-change**

DHCPv4租约发生改变(renewed, rebound等)

- **connectivity-change**

network connectivity 状态发生改变(`no connectivity`, `went online`等)


## NetworkManger 启动流程分析

[文档](https://developer-old.gnome.org/NetworkManager/stable/NetworkManager.conf.html)

1. 读取配置文件 `/etc/NetworkManager/NetworkManager.conf`, 同时会读取以下目录的配置文件:

- `/usr/lib/NetworkManager/conf.d/NAME.conf`
- `/etc/NetworkManager/conf.d/NAME.conf`
- `/var/lib/NetworkManager/NetworkManager-intern.conf`

> 1. `/usr/lib/NetworkManager/conf.d/NAME.conf` 最先被解析, 甚至在 NetworkManager.conf 之前.
> 2. 可以通过添加 `/etc/NetworkManager/conf.d/NAME.conf` 文件来覆盖  `/usr/lib/NetworkManager/conf.d/NAME.conf`
当中的配置.
> 3. NetworkManager 可以通过 D-Bus 或其他内部操作覆盖某些用户配置选项. 这种状况下, 它会将这些更改写入到文件
`/var/lib/NetworkManager/NetworkManager-intern.conf`. 该文件不打算由用户修改, 但它最后读取并且可以覆盖某些用户
的配置.

> `/etc/netplan` (Ubuntu18.04之后新的网络配置方式) 目录下的 yaml 文件最终会转换成 conf 文件, 存放在 
`/run/NetworkManager/conf.d/netplan.conf`. 如果一个 key 出现多次, 则使用最后一次出现的 key.

配置文件的格式:

```
# no-mac-addr-change.conf
[device-mac-addr-change-wifi]
match-device=driver:rtl8723bs,driver:rtl8189es,driver:r8188eu,driver:8188eu,driver:eagle_sdio,driver:wl
wifi.scan-rand-mac-address=no
wifi.cloned-mac-address=preserve
ethernet.cloned-mac-address=preserve
```

将上面目录下所有的 `.conf` 的内容都合并成一个, 作为最终 NetworkManager 的配置. 在此过程中NetworkManger 会校验每一
个 `[section].key` 是否合法, 如果非法, 则会忽略, 并在日志当中记录.

当文件读取完成之后, 会形成一个 NetworkManger 配置文件.

配置文件包含的 section 有:

- `[main]`

1) plugins, 系统插件列表, 使用 `,` 进行分隔. 这些插件用于读写系统范围的 connection. 当指定多个插件时, 将从所有列出
的插件中读取 connection. 写入 connection 时, 会按照插件列出的顺序保存 connection. 

常用的插件(plugins):

```
- keyfile, 通用插件. 执行 NetworkManager 所有 connection types 和 capabilities. 它在 system-connections
中以 `ini` 风格的格式写文件.  存储的 connection 文件包含纯文本形式的 passwords, secrets 和 private keys, 因此
它只能被root读取.

- ifupdown, 该插件用于 Debian 和 Ubuntu 发行版本, 并从 `/etc/network/interfaces` 读取以太网和WIFI连接. 这个插
件是只读的; 使用此插件时, 从 NetworkManager 添加的任何 connection (any types) 都将使用 keyfile 保存.

- ifcfg-rh, 该插件用于 Fedora 和 Red Hat 发行版本. 用于从标准 `/etc/sysconfig/network-scripts/ifcfg-*` 文件
读取和写入配置. 目前支持读取 `Ethernet, Wi-Fi, InfiniBand, VLAN, Bond, Bridge, Team` 类型的 connection. 启
用 ifcfg-rh 插件会隐式启用 ibft 插件(如果可用). 可用通过添加 `no-ibft` 来禁用.
```

2) dns, 设置 DNS (resolv.conf) 的工作模式.

```
default: 未指定秘钥时的默认值. NetworkManager 将更新 resolve.conf.

dnsmasq: NetworkManager 将 dnsmasq 作为本地缓存 nameserver 运行. 如果用户连接到VPN, 则使用 "split DNS" 配置,
然后更新 resolv.conf 以指向本地 nameserver.

systemd-resolved: NetworkManager 会将 DNS 配置推送到 systemd-resolved

unbound: NetworkManager 将与 unbound 和 dnssec-triggerd 通信, 提供具有 DNSSEC 支持的 "split DNS" 配置. 
resolv.conf 将由 dnssec-trigger 守护进程管理.

none: NetworkManager 不会修改 resolv.conf. 这意味着 rc-manager 不受管理.
```

注意: 当 plugin 是 `dnsmasq`, `systemd-resolved`, 和 `unbound` 会缓存本地域名服务器. 因此. 当 NetworkManager
写入 `/run/NetworkManager/resolv.conf` 和 `/etc/resolv.conf` (根据 rc-manager的设置) 时, 域名服务器只有localhost.
NetworkManager 还会写入一个文件 `/run/NetworkManager/no-stub-resolv.conf`, 其中包含推送到 DNS 插件的原始域名服
务器.

3) rc-manager, 设置 DNS (resolv.conf) 的管理模式. 默认值取决于 NetworkManager 的编译选项, 无论如何设置, NetworkManager
始终将 resolv.conf 写入其运行时状态文件 `/run/NetworkManager/resolv.conf` 当中. 如果使用设置 `dns=none` 或使文件
`/etc/resolv.conf` 不可变(`chattr +i`), NetworkManager 将忽略此设置并且始终选择 unmanaged.

```
symlink: 符号链接, 如果 resolv.conf 是一个普通文件或不存在, 在更新时 NetworkManager 会替换该文件. 如果 resolv.conf 
是一个符号链接, NetworkManager 会忽略它, 除非该符号链接指向 "/run/NetworkManager/resolv.conf", 否则, 符号链接将
会被更新. 用户可以使用符号链接替换以摆脱 NetworkManager 管理 resolv.conf. 

file: NetworkManager 会写入 /ect/resolv.conf 当中. 在任何情况下, 现有的符号链接都不会被文件替换.

注: 在低版本的 NetworkManager 当中, 会用纯文件替换悬空的符号链接.
    在高版本的 NetworkManager 当中, 如果它找到符号链接 resolv.conf 的目标文件, 目标文件将会被更新.

resolvconf: NetworkManager 将运行 resolvconf 来更新 DNS 配置. 在 1.2.x 版本当中的默认配置.

netconfig: NetworkManager 将运行 netconfig 来更新 DNS 配置.

unmanaged: 不会创建 /ect/resolv.conf 文件.
```

4) dhcp, 此项设置 DHCP 客户端 NetworkManager 将使用的内容. 可选的值: dhclient, dhcpcd, internal. dhclient
和 dhcpcd 选项需要安装指定的客户端. internal 使用内置的 DHCP 客户端.

如果此选项缺失, 会按照 dhclient, dhcpcd, internal 的顺序查找可用的DHCP客户端.

5) systemd-resolved 将连接 DNS 配置发送到 `systemd-resolved`. 默认值是 "true". 注意, 此设置是对 dns 的补充. 可
以在设置 dns 为其它插件时, 启用 systemd-resolved, 或者 dns 设置为 systemd-resolved 时, 将系统解析器配置为使用 
systemd-resolved. 


- `[keyfile]`

1) path, 读取和存储密钥文件的位置. 默认位置是 `/etc/NetworkManager/system-connections`
2) unmanaged-devices, NetworkManager 忽略的网卡设备列表.

eg:
```
[keyfile]
    unmanaged-devices=mac:00:22:68:1c:59:b1;interface-name:eth2
```

- `[ifupdown]`

在使用 ifupdown 插件时有效.

1) managed, 如果设置为 true, 则 /etc/network/interfaces 中列出的网卡由 NetworkManager 管理. 如果设置为 false,
则 NetworkManager 将忽略 /etc/network/interfaces 中列出的网卡. 记住: NetworkManager 控制 default route, 由
于该网卡被忽略, NetworkManager 可能会将 default route 分配给其它某个网卡. 默认值 false

- `[logging]`

1) level, 设置日志级别

- `[connection]`

- `[connectivity]`

- `[global-dns]` 

全局DNS设置, 会覆盖 connection 当中的 DNS 设置

1) searches, 在主机名查找期间使用的搜索域列表.
2) options, 传递给主机名解析的选项参数列表.

- `[global-dns-domain-xxx]`

以 `global-dns-domain-` 前缀开头 section 可用为特定域定义全局DNS配置. `global-dns-domain-` 之后的内容指定了域
名. 默认域名由通配符 "*" 表示. 默认域名是强制性的.

1) servers, 域名解析的 DNS 主机地址列表

- `[.config]`

- `[device]`

2. 读取 state 文件.

- `/var/lib/NetworkManager/NetworkManager.state`

文件内容是: 
```
[main]
NetworkingEnabled=true
WirelessEnabled=true
WWANEnabled=true
```

该文件是在解析 `NetworkManager` 之后动态生成的.

3. 创建网卡

- 创建 netns (network namaespace), 参数 `(net:8, mnt:9)`, 相当于命令 `ip netns add NAME`

- 为网络设置进行 `link`, `address`, `route`.

4. 设置 hostname (`/etc/hostname` 文件的内容)

5. 启动 dns-mgr.

- 根据 `main.dns` 的配置初始化 `dns-mgr`, `init: dns=DNS, rc-manager=RC, plugin=PLUGIN`.

这里的 dns, rc-manager, plugin 值对应是前面的 `[main]` 当中的配置选项.

> `dns=default` 是 debian10 当中的配置, 这是一个默认值.
> `dns=dnsmasq` 是 ubuntu 16.04 中的配置.
> `dns=systemd-resolved` 是 ubuntu 18.04 之后的配置.

> 如果 dns 是 dnsmasq, 形成的 dns 的配置文件来自两部分: /etc/NetworkManager/NetworkManager.conf 当中的 `dns`
相关section 和 /etc/NetworkManager/dnsmasq.d/*.conf 当中的 dnsmasq 配置文件. 
> dnsmasq 相关的配置, 参考后面的 dnsmasq 配置.

6. 执行 dispatcher 脚本

- 执行 `/etc/NetworkManager/dispatcher.d` 下的脚本.

- 执行 `/etc/NetworkManager/dispatcher.d/NAME` 下的脚本.

7. interface 解析

- 解析 `/etc/network/interfaces` 文件.

8. 根据一开始生成的 NetworkManager 配置文件, 开始逐个执行.


### 修改系统 DNS 的方法

1) 修改 NetworkManager.conf

```
[global-dns-domain-*]
    servers=8.8.4.4,114.114.114.114
```

2) 修改 interfaces

```
dns-nameservers 8.8.4.4 4.4.4.4
```

## 本地 DNS 解析器配置

### dnsmasq

- `resolv-file` 配置 dnsmasq 上游的 DNS 服务器. 如果不开启就使用 Linux 主机默认的 `/etc/resolve.conf` 里的
nameserver.

```
resolv-file=/etc/resolv.dnsmasq.conf
```

配置 `/etc/resolv.dnsmasq.conf` 内容:

```
nameserver 8.8.8.8
nameserver 8.8.4.4
```

- `add-hosts`, 增加自定义 hosts 文件位置.

```
add-hosts=/etc/dnsmasq.hosts
```

在 `/etc/dnsmasq.hosts` 文件中添加 DNS 记录.

```
192.168.1.100 web01.mike.com web01
192.168.1.100 web02.mike.com web02
```

- `server` 指定默认查询的上游服务器. `address` 设置本地DNS记录.

```
# 指定dnsmasq默认查询的上游服务器.
server=8.8.8.8
server=8.8.4.4

# 把所有 .cn 的域名全部通过 114.114.114.114 这台国内DNS服务器来解析
server=/cn/114.114.114.114

# 给*.apple.com和taobao.com使用专用的DNS
server=/taobao.com/223.5.5.5
server=/.apple.com/223.5.5.5

# 把www.hi-linux.com解析到特定的IP
address=/www.hi-linux.com/192.168.101.107

在这里hi-linux.com相当于*.mike.com泛解析
address=/hi-linux.com/192.168.101.107
```

- `domain`, 给dhcp服务赋予域名.

```
# 给dhcp服务赋予域名
domain=thekelleys.org

# 给dhcp的一个子域名赋予一个不同的域名
domain=wirless.thekelleys.org,192.168.2.0/24
```

> dnsmasq 选择最快的上游DNS服务器.

```
all-servers
server=8.8.8.8
server=8.8.4.4
```

`all-servers` 表示对以下设置的所有的 server 发起查询, 选择回应最快的一条作为查询记录.

> 提升 dnsmasq 解析速度. 

一般状况下, dnsmasq 需要经常载入并读取 `/etc/hosts` 文件, 这样会造成性能下降. 可以指定一个共享内存的文件, 比如下面案例
当中的 `/dev/shm/dnsrecord.txt`, 这样可以提升性能. 但是由于内存非持久性, 需要定期同步某个文件到内存文件当中.

```
no-hosts
addon-hosts=/dev/shm/dnsrecord.txt
```

`no-hosts` 表示不使用 `/etc/hosts` 文件.

解决同步问题:

```
# 开机启动
echo "cat /etc/hosts > /dev/shm/dnsrecord.txt" >> /etc/rc.local

# 定时同步
*/10 * * * * cat /etc/hosts > /dev/shm/dnsrecord.txt
```

### systemd-resolved

配置文件: `/etc/systemd/resolved.conf` 或 `/etc/systemd/resolved.conf.d/*.conf`.

systemd-resolved有4种不同方式来处理DNS解析, 其中2种是主要使用模式:

- local DNS stub 模式

使用 systemd DNS stub 文件 `/run/systemd/resolve/stu-resolv.conf`, 这个文件只包含 local stub `127.0.0.53`
作为唯一 DNS 服务器, 以及一系列 search domains. 这是建议使用的操作模式. 原先传统的 `/ect/resolv.conf` 已经通过
systemd-resolved 管理改为软连接到 DNS stub 文件.

而且, `/run/systemd/resolve/resolv.conf` 配置则是 systemd-resolved 使用的上级 DNS 服务器, 也就是转发 DNS 请求
给上级 DNS.

- protect resolv.conf 模式

在使用 protect 模式时, `/etc/resolv.conf` 依然存在, 而且可以由其它软件包管理. 此时 systemd-resolved 仅仅是这个文件
的客户端.

#### 自动管理 DNS

systemd-resolved 默认可以和 NetworkManager 协作管理 `/etc/resolv.conf`, 不需要单独配置. 不过, 如果使用 DHCP 和
VPN 客户端, 则会使用 resolvconf 程序设置 DNS 和 search domains.

#### 手动配置 DNS

在 local DNS stu 模式下, 要定制 DNS 服务器, 需要设置 `/etc/systemd/resolved.conf` 配置:

```
[Resolve]
DNS=8.8.8.8 114.114.114.114
FallbackDNS=127.0.0.1
Domains=~.
#LLMNR=no
#MulticastDNS=no
#DNSSEC=no
#DNSOverTLS=no
#Cache=yes
#DNSStubListener=yes
#ReadEtcHosts=yes
```

> 如果 systemd-resolved 没有从 NetworkManager 收到 DNS 服务器地址, 并且手工配置了 `FallbackDNS`, 那么它将使用配
置的 `FallbackDNS` 地址解析域名.


systemd-resolved 四种方式处理 `/etc/resolv.conf`:

1. systemd-resolved 实时更新 `/run/systemd/resolve/stub-resolv.conf` 文件以确保兼容传统的 Linux 程序. 将软连
接 `/etc/resolv.conf` 指向该文件. 该文件将 127.0.0.53 作为唯一的 DNS 服务器, 并包含 systemd-resolved 使用的搜索
域列表. 搜索域列表将会保持实时更新. 推荐使用该方式.

2. 一个静态的 `/usr/lib/systemd/resolv.conf` 文件, 此文件包含一个唯一的 127.0.0.53 DNS 服务器. 将软连接文件 
`/etc/resolv.conf` 指向该静态文件. 注意: 该静态文件不包含任何搜索域.

3. systemd-resolved 实时更新 `/run/systemd/resolve/resolv.conf` 文件以确保兼容传统的 Linux 程序. 将软连接 
`/etc/resolv.conf` 指向该文件. 注意: 该文件只包含所有已知的全局 DNS 服务器, 而不包含针对特定网络接口设置的 DNS 服务器.

4. 其它软件包或系统管理员维护 `/etc/resolv.conf` 内容. 


