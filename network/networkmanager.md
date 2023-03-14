## NetworkManager

NetworkManager 守护程序试图通过管理主网络连接和其他网络接口 (如以太网,Wi-Fi和移动宽带设备) 来使网络的配置和操作尽
可能自动化. 

当网络连接可用时, NetworkManager 会连接该网络设备, 除非该行为被禁用.

为了响应网络事件, NetworkManager 将按字母顺序在 `/etc/NetworkManager/dispatcher.d` 目录或子目录中执行脚本. 每
个脚本应该是 `root` 权限可执行文件. 此外, 它允许 `group` 或 `other` 的用户写入.

每个脚本都接收两个参数, 第一个是操作发生的设备的接口名称, 第二个是 Action. 

对于 `设备` 操作, 该接口是适合IP配置的内核接口的名称. 设备名称可以是 `VPN_IP_IFACE`, `DEVICE_IP_IFACE`, `DEVICE_IFACE`. 

对于 `主机名` 和 `连接更改` 操作, 设备名称始终为 "none".

### Action

- pre-up

该 `interface` 已连接到网络, 但尚未完全激活. 必须将处理此事件的脚本放在 `dispatcher.d/pre-up.d` 目录中, 或将其符
号链接到 `dispatcher.d/pre-up.d` 目录中, NetworkManager 将等待脚本执行完成, 然后再向应用程序指示该接口已完全激活.

- up

`interface` 已激活.

- pre-down

该 `interface` 将被停用, 但尚未从网络断开连接. 必须将处理此事件的脚本放在 `dispatcher.d/pre-down.d` 目录中, 或将
其符号链接到 `dispatcher.d/pre-down.d` 目录中, NetworkManager 将等待脚本执行完成, 然后再将接口与其网络断开连接. 

- down

该 `interface` 已被禁用.

---

- vpn-pre-up

VPN已连接到网络, 但尚未完全激活. 必须将处理此事件的脚本放在 `dispatcher.d/pre-up.d` 目录中, 或将其符号链接到
`dispatcher.d/pre-up.d` 目录中, NetworkManager 将等待脚本执行完成, 然后向应用程序指示VPN已完全激活.

- vpn-up

VPN连接已激活.

- vpn-pre-down

VPN 将被停用, 但尚未从网络断开连接. 必须将处理此事件的脚本放在 `dispatcher.d/pre-down.d` 目录中, 或将其符号链接到 
`dispatcher.d/pre-down.d` 目录中, 并且 NetworkManager 将等待脚本执行完成, 然后再将VPN与其网络断开连接.

- vpn-down

VPN连接已停用.

---

- hostname

系统主机名已更新. 使用 `gethostname` 进行检索. 接口名称(第一个参数)为空, 并且未为此操作设置任何环境变量.

- dhcp4-change

DHCPv4租约发生改变(renewed, rebound等)

- connectivity-change

network connectivity 状态发生改变(`no connectivity`, `went online`等)


## NetworkManger 启动与配置

[文档](https://developer-old.gnome.org/NetworkManager/stable/NetworkManager.conf.html)

- 读取配置文件 `/etc/NetworkManager/NetworkManager.conf`, 同时会读取以下目录的配置文件:

1) `/usr/lib/NetworkManager/conf.d/NAME.conf`
2) `/etc/NetworkManager/conf.d/NAME.conf`

> 1) `/usr/lib/NetworkManager/conf.d/NAME.conf` 最先被解析, 甚至在 NetworkManager.conf 之前.
> 2) 可以通过添加 `/etc/NetworkManager/conf.d/NAME.conf` 文件来覆盖 `/usr/lib/NetworkManager/conf.d/NAME.conf`
当中的配置.

> `/etc/netplan` (Ubuntu18.04之后新的网络配置方式) 目录下的 yaml 文件最终会转换成 conf 文件, 存放在 
`/run/NetworkManager/conf.d/netplan.conf`. 如果一个 key 出现多次, 则使用最后一次出现的 key.

最终形成 NetworkManager.conf 配置文件.

- 设置 hostname (`/etc/hostname` 文件的内容)

- 启动 dns-mgr.

1) 根据 `main.dns` 的配置初始化 `dns-mgr`, `init: dns=DNS, rc-manager=RC`.

这里的 dns, rc-manager, plugin 值对应是前面的 `[main]` 当中的配置选项.

> `dns=default` 是 debian10 当中的配置, 这是一个默认值.
> `dns=dnsmasq` 是 ubuntu 16.04 中的配置.
> `dns=systemd-resolved` 是 ubuntu 18.04 之后的配置.

> 如果 dns 是 dnsmasq, 形成的 dns 的配置文件来自两部分: /etc/NetworkManager/NetworkManager.conf 当中的 `dns`
相关section 和 /etc/NetworkManager/dnsmasq.d/*.conf 当中的 dnsmasq 配置文件. 

- load settings plugin

- 执行 settings plugin 选项

1) ifupdown 插件, 设置 management mode

2) ifupdown 插件, 解析 /etc/network/interfaces

3) keyfile 插件, 加载 path 下的 connection, 并逐个进行初始化

- dhcp-init, 设置 DHCP 选项 

- load device plugin (wifi, bluetooth, wwan, adsl)

- create device (Generic, Ethernet, 802.11 WiFi)

- device change state(状态变化比较复杂)

- 在上述的执行过程中会有 `state change` 执行 dispatcher 脚本

1) 执行 `/etc/NetworkManager/dispatcher.d` 下的脚本.

2) 执行 `/etc/NetworkManager/dispatcher.d/NAME` 下的脚本.


### 配置文件

配置文件是由许多个 section 组成, 每个 section 又包含自己的属性配置, 配置文件当中常用的 section 有:

#### main

1) plugins, 系统插件列表, 使用 `,` 进行分隔. 这些插件用于读写系统的 connection profile. 当指定多个插件时, 将从
所有列出的 plugin 中读取 connection. 写入 connection 时, 会按照插件列出的顺序保存 connection.

如果第一个插件无法写入该类型的 connection, 则尝试下一个 plugin. 如果没有一个 plugin 可以保存 connection, 则会向
用户返回一个错误.

常用的插件(plugins):

```
- keyfile, 通用插件, 支持 NetworkManager 所有 connection types 和 capabilities. 表示以 ini 格式向目录
/etc/NetworkManager/system-connections 中写入 connection 文件. 

存储的 connection 文件包含纯文本形式的 passwords, secrets 和 private keys, 因此它只能被root读取.

keyfile 插件总是处于激活状态, 并且自动存储其他 active plugin 不支持的 connection.


- ifupdown, 该插件用于 Debian 和 Ubuntu 发行版本, 并从 `/etc/network/interfaces` 读取 Ethernet 和 WIFI connections. 
这个插件是只读的; 使用此插件时 从 NetworkManager 添加的 connection (any types) 都将使用 keyfile 进行存储.


- ifcfg-rh, 该插件用于 Fedora 和 Red Hat 发行版本. 用于从标准 `/etc/sysconfig/network-scripts/ifcfg-*` 文件
读取和写入配置. 目前支持读取 `Ethernet, Wi-Fi, InfiniBand, VLAN, Bond, Bridge, Team` 类型的 connection. 

启用 ifcfg-rh 插件会隐式启用 ibft 插件(如果可用). 这可用通过添加 `no-ibft` 来禁用.


- ibft, no-ibft, 已经弃用, 不再支持.
```

2) dns, 设置 DNS (resolv.conf) 的处理模式.

如果该属性未设置, 默认值是 default. 当 /etc/resolv.conf 是 /run/systemd/resolve/stub-resolv.con, 
/run/systemd/resolve/resolv.conf, /lib/systemd/resolv.conf, /usr/lib/systemd/resolv.conf 的链接文件, 则
默认值是 systemd-resolved

```
default: 未设置时的默认值. NetworkManager 将直接更新文件 /etc/resolv.conf.

systemd-resolved: NetworkManager 会将 DNS 配置推送到 systemd-resolved, 由 systemd-resolved 去更新 /etc/resolv.conf(一般是建立软连接)

dnsmasq: NetworkManager 将 dnsmasq 作为本地缓存 nameserver 运行. 如果用户连接到VPN, 则使用 "Condition Forward",
然后更新 resolv.conf 以指向 local nameserver. 通过讲自定义选项添加到 /ect/NetworkManager/dnsmasq.d 目录中的
文件, 可以讲自定义选项传递给 dnsmasq 实例.

注: 当有多个上游服务器可用时, dnsmasq 最初会使用并行的方式请求 DNS 解析, 然后使用最快的响应. 可用通过将 'all-servers'
或 'strict-order' 选项传递给 dnsmasq 来修改此行为.

unbound: NetworkManager 将与 unbound 和 dnssec-triggerd 进行通信, 提供具有 DNSSEC 支持的 "Condition Forward".
/etc/resolv.conf 将由 dnssec-trigger 守护进程管理.

none: NetworkManager 不会修改 resolv.conf. 这意味着 rc-manager 不受管理.
```

注: 当 plugin 是 `dnsmasq`, `systemd-resolved`, 和 `unbound` 会缓存本地域名服务器. 因此. 当 NetworkManager
写入 `/run/NetworkManager/resolv.conf` 和 `/etc/resolv.conf` (根据 rc-manager的设置) 时, 域名服务器只有localhost.
NetworkManager 还会写入一个文件 `/run/NetworkManager/no-stub-resolv.conf`, 里面包含推送到 DNS 插件的原始域名服
务器.

3) rc-manager, 设置 DNS (resolv.conf) 的管理模式. 默认值取决于 NetworkManager 的编译选项, 无论如何设置, NetworkManager
始终将 resolv.conf 写入其运行时状态文件 `/run/NetworkManager/resolv.conf` 当中. 

如果使用设置 `dns=none` 或文件 `/etc/resolv.conf` 不可变(`chattr +i`), NetworkManager 将忽略此设置并且始终选择 unmanaged.

```
symlink: 符号链接, 如果 resolv.conf 是一个普通文件或不存在, 在更新时 NetworkManager 会替换该文件. 如果 resolv.conf 
是一个符号链接, NetworkManager 会忽略它, 如果该符号链接指向 /run/NetworkManager/resolv.conf 源文件, resolv.conf 
内容将会被更新. 

用户可以使用符号链接以摆脱 NetworkManager 管理 resolv.conf. 


file: NetworkManager 会写入 /ect/resolv.conf 当中. 任何情况下, resolv.conf 的内容都会被更新.

注: 在低版本的 NetworkManager 当中, 会用纯文件替换悬空的符号链接.
    在高版本的 NetworkManager 当中, 如果它找到符号链接 resolv.conf 的源文件, 源文件将会被更新.

resolvconf: NetworkManager 将运行 resolvconf 来更新 DNS 配置. 在 1.2.x 版本当中的默认配置.

netconfig: NetworkManager 将运行 netconfig 来更新 DNS 配置.

unmanaged: 不会创建 /ect/resolv.conf 文件.
```

4) dhcp, 此项设置 DHCP 客户端 NetworkManager 将使用的内容. 可选的值: dhclient, dhcpcd, internal. 

dhclient 和 dhcpcd 选项需要安装指定的客户端. internal 使用内置的 DHCP 客户端.

如果此选项缺失, 默认是 internal. 如果所选插件不可用, 则按以下顺序查找客户端: dhclient, dhcpcd, internal.

5) systemd-resolved, 将连接 DNS 配置发送到 `systemd-resolved`. 默认值是 "true". 

注: 此设置是对 dns 的补充. 可以在设置 dns 为其它 plugin 时, 启用 systemd-resolved, 或者 dns 设置为 systemd-resolved 
时, 将系统解析器配置为使用 systemd-resolved. 


#### keyfile

1) path, 读取和存储 keyfile 的位置. 默认位置是 `/etc/NetworkManager/system-connections`

2) unmanaged-devices, 设置不接受 NetworkManager 管理的设备列表.

案例:
```
[keyfile]
    unmanaged-devices=mac:00:22:68:1c:59:b1;interface-name:eth2
```

匹配规则:
```
interface-name:IFNAME, interface-name:~IFNAME, 网络接口名称匹配

mac:HWADDR, MAC 地址匹配

type:TYPE, 类型匹配. 常见的类型 bridge, ethernet, loopback, tun

driver:DRIVER, 驱动匹配, 常见驱动 bridge, tun, veth(ethernet), vmxnet3(ethernet)
```

#### ifupdown

在使用 ifupdown 插件时有效.

1) managed, 如果设置为 true, 则 /etc/network/interfaces 中列出的网卡由 NetworkManager 管理. 如果设置为 false,
则 NetworkManager 将忽略 /etc/network/interfaces 中列出的网卡. 

记住: NetworkManager 控制 default route, 由于该网卡被忽略, NetworkManager 可能会将 default route 分配给其
它某个网卡. 

默认值 false

#### logging

1) level, 设置日志级别, 可选日志级别 OFF, ERR, WARN, INFO, DEBUG, TRACE

2) backend, 设置日志存储的位置, 支持的值 "syslog" 和 "journal. 默认值是 journal

#### connection

设置 connection 的默认值.


#### device

设置 device 的默认值

1) managed, 该设备是否受到 NetworkManager 的管理

2) match-device, 匹配的 device. 规则与 `keyfile.unmanaged-devices` 是一致的.

3) stop-match, 如果该 section 匹配(基于 match-device), 也不会考虑后续的 section. 例如, 现在有2个 section, 
它的前后顺序是 `[device-wifi-wlan0]` 和 `[device-wifi-other]`, 当 `[device-wifi-wlan0]` 中设置了 `stop-match=1`,
则在 `[device-wifi-wlan0]` 匹配的 device 不会设置相关指定的属性, 后续的 `[device-wifi-other]` 也不会继续搜索.

案例:

```
[device]
   match-device=interface-name:eth3
   managed=1
```


#### global-dns

全局DNS设置, 会覆盖 connection 当中的 DNS 设置

1) searches, 在主机名查找期间使用的搜索域列表.

2) options, 传递给主机名解析的选项参数列表.

#### global-dns-domain

以 `global-dns-domain-` 前缀开头 section 可用为特定域定义全局DNS配置. `global-dns-domain-` 之后的内容指定了域
名. 默认域名由通配符 "*" 表示. 默认域名是强制性的.

1) servers, 域名解析的 DNS 主机地址列表


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