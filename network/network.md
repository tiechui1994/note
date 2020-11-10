## interfaces 配置

### 设置以太网接口

大多数网络设置可以通过 `/etc/network/interfaces` 上的 interfaces 配置文件完成. 在这里, 可以为网卡提供IP address
(或使用dhcp), 设置route, 配置IP masquerading, 设置default routes等等.

> 记住将要在启动时启动的接口添加到 'auto' 行.


### 使用 DHCP 自动配置接口

```
auto eth0
allow-hotplug eth0
iface eth0 inet dhcp
```

### 手动配置接口

如果是手动配置它, 则类似以下内容将设置 default gateway(network, broadcast 和 gateway是可选的）:

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

NetworkManager 守护程序试图通过管理主网络连接和其他网络接口 (如以太网,Wi-Fi和移动宽带设备) 来使网络的配置和操作尽
可能轻松自如. 

当网络连接可用时, NetworkManager会连接该网络设备, 除非该行为被禁用. 


为了响应网络事件, NetworkManager 将按字母顺序在 `/etc/NetworkManager/dispatcher.d` 目录或子目录中执行脚本. 每
个脚本应该是 `root` 拥有的常规可执行文件. 此外, 它允许 `group` 或 `other` 的用户写入, 也不可以 `setuid`.

每个脚本都接收两个参数, 第一个是操作发生的设备的接口名称, 第二个是操作. 对于设备操作, 该接口是适合IP配置的内核接口的名称.
因此, 如果适用, 它可以是 `VPN_IP_IFACE`, `DEVICE_IP_IFACE`, `DEVICE_IFACE`. 对于 `hostname`, 设备名称始终为
"none", 对于 `connectivity-change`, 该名称为空.

*Action* 是:

- **pre-up**

该 `interface` 已连接到网络, 但尚未完全激活. 必须将处理此事件的脚本放在 `dispatcher.d/pre-up.d` 目录中, 或将其符
号链接到 `dispatcher.d/pre-up.d` 目录中, NetworkManager将等待脚本执行完成,然后再向应用程序指示该接口已完全激活.


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


1, 读取配置文件 `/etc/NetworkManager/NetworkManager.conf`, 同时会读取以下目录的配置文件:

- `/usr/lib/NetworkManager/conf.d`
- `/run/NetworkManager/conf.d`
- `/etc/NetworkManager/conf.d`

> `/etc/netplan` (Ubuntu18.04之后新的网络配置方式) 目录下的 yaml 文件最终会转换成 conf 文件, 存放在 
`/run/NetworkManager/conf.d/netplan.conf`.
> 如果一个 key 出现多次, 则使用最后一次出现的 key.

配置文件的格式:

```
[device-mac-addr-change-wifi]
match-device=driver:rtl8723bs,driver:rtl8189es,driver:r8188eu,driver:8188eu,driver:eagle_sdio,driver:wl
wifi.scan-rand-mac-address=no
```

将上面目录下所有的 `.conf` 的内容都合并成一个, 作为最终 NetworkManager 的配置. 在此过程中NetworkManger 会校验每一
个 `[section].key` 是否合法, 如果非法, 则会忽略, 并在日志当中记录.

2, 读取 state 文件

- `/var/lib/NetworkManager/NetworkManager.state`

3, netns 

- 创建新的 netns (network namaespace), 参数 `(net:8, mnt:9)`

- 针对 lo, 

4, monitoring

- `monitoring kernel firmware directory '/lib/firmware'` 
- `monitoring ifupdown state file '/run/network/ifstate'`

5, hostname

- `create NMHostnameManager`
- 设置 `hostname` 为 `/etc/hostname` 配置的内容

6, dns

- `create NMDnsManager`

- 根据 `main.dns` 的配置初始化 `dns-mgr`, `init: dns=dnsmasq, rc-manager=resolvconf, plugin=dnsmasq` (
这个 dns 使用的是 `dnsmasq`), `init: dns=systemd-resolved rc-manager=symlink, plugin=systemd-resolved`(
这个 dns 使用的是 `systemd-resolved`)

> `dnsmasq` 是 Ubuntu 16.04 当中的配置, `systemd-resolved` 是 Ubuntu 18.04 之后的配置


6, dispatcher

- dhcp-init

7, settings

- `timestamps-keyfile`
- `seen-bssids-keyfile`

8, ifupdown
- `management mode`
- `interfaces file`
- `unmanaged-specs`
- `load connections`

9, settings
- `settings-connection`

10, new connection
- `new connection`


4, 按照配置文件的优先级, 初始化

到此为止, NetworkManager 已经启动, 接下来是初始化 `network interface device`

5, 解析 `/etc/network/interfaces`, `/etc/network/interfaces.d` 下的 `interface` 配置文件.

设置 `management mode`, `managed` 或者 `unmanaged`

6, 创建 `network interface device`


```
<trace> [1598180286.9161] platform-linux: event-notification: RTM_NEWLINK, flags multi, seq 1, in-dump: 1: lo <UP,LOWER_UP;loopback,up,running,lowerup> mtu 65536 arp 772 loopback? not-init addrgenmode eui64 addr 00:00:00:00:00:00 rx:114675,294937541 tx:114675,294937541
<trace> [1598180286.9162] ethtool[1]: ETHTOOL_GDRVINFO, lo: failed: 不支持的操作

<debug> [1598180286.9162] platform: signal: link   added: 1: lo <UP,LOWER_UP;loopback,up,running,lowerup> mtu 65536 arp 772 loopback? not-init addrgenmode eui64 addr 00:00:00:00:00:00 driver unknown rx:114675,294937541 tx:114675,294937541
<trace> [1598180286.9162] ethtool[2]: ETHTOOL_GDRVINFO, enp1s0: success
<trace> [1598180286.9163] platform-linux: event-notification: RTM_NEWLINK, flags multi, seq 1, in-dump: 2: enp1s0 <UP;broadcast,multicast,up> mtu 1500 arp 1 ethernet? not-init addrgenmode eui64 addr 34:17:EB:53:A5:C9 rx:0,0 tx:0,0
<trace> [1598180286.9163] ethtool[2]: ETHTOOL_GDRVINFO, enp1s0: success

<debug> [1598180286.9163] platform: signal: link   added: 2: enp1s0 <UP;broadcast,multicast,up> mtu 1500 arp 1 ethernet? not-init addrgenmode eui64 addr 34:17:EB:53:A5:C9 driver r8169 rx:0,0 tx:0,0
<trace> [1598180286.9164] ethtool[3]: ETHTOOL_GDRVINFO, wlp2s0: success
<trace> [1598180286.9164] platform-linux: event-notification: RTM_NEWLINK, flags multi, seq 1, in-dump: 3: wlp2s0 <DOWN;broadcast,multicast> mtu 1500 arp 1 wifi? not-init addrgenmode eui64 addr A0:88:69:81:7F:04 rx:254095,208985694 tx:167754,18648308
<trace> [1598180286.9164] ethtool[3]: ETHTOOL_GDRVINFO, wlp2s0: success
<debug> [1598180286.9165] platform: signal: link   added: 3: wlp2s0 <DOWN;broadcast,multicast> mtu 1500 arp 1 wifi? not-init addrgenmode eui64 addr A0:88:69:81:7F:04 driver iwlwifi rx:254095,208985694 tx:167754,18648308
```


```
<info>   NetworkManager (version 1.10.8) is starting... (after a restart)
<info>   Read config: /etc/NetworkManager/NetworkManager.conf
<info>   manager[0x55d39c75a050]: monitoring kernel firmware directory '/lib/firmware'.
<info>   monitoring ifupdown state file '/run/network/ifstate'.
<info>   hostname: hostname: using hostnamed
<info>   hostname: hostname changed from (none) to "master"
<info>   dns-mgr[0x55d39c76d130]: init: dns=default, rc-manager=resolvconf
<info>   rfkill0: found WiFi radio killswitch (at /sys/devices/LNXSYSTM:00/LNXSYBUS:00/DELLABCE:00/rfkill/rfkill0) (platform driver dell-rbtn)
<info>   rfkill1: found WiFi radio killswitch (at /sys/devices/pci0000:00/0000:00:1c.3/0000:02:00.0/ieee80211/phy0/rfkill1) (driver iwlwifi)
<info>   manager[0x55d39c75a050]: rfkill: WiFi hardware radio set enabled
<info>   manager[0x55d39c75a050]: rfkill: WWAN hardware radio set enabled
Started Network Manager.
<error>  dispatcher: could not get dispatcher proxy! 为 org.freedesktop.nm_dispatcher 调用 
StartServiceByName 出错：GDBus.Error:org.freedesktop.systemd1.NoSuchUnit: Unit 
dbus-org.freedesktop.nm-dispatcher.service not found.
<info>   init!
<info>         interface-parser: parsing file /etc/network/interfaces
<info>         interface-parser: source line includes interfaces file(s) /etc/network/interfaces.d
<info>         interface-parser: finished parsing file /etc/network/interfaces
<info>   management mode: managed
<info>   devices added (path: /sys/devices/pci0000:00/0000:00:1c.0/0000:01:00.0/net/enp1s0, iface: enp1s0)
<info>   device added (path: /sys/devices/pci0000:00/0000:00:1c.0/0000:01:00.0/net/enp1s0, iface: enp1s0): no ifupdown configuration found.
<info>   devices added (path: /sys/devices/pci0000:00/0000:00:1c.3/0000:02:00.0/net/wlp2s0, iface: wlp2s0)
<info>   device added (path: /sys/devices/pci0000:00/0000:00:1c.3/0000:02:00.0/net/wlp2s0, iface: wlp2s0): no ifupdown configuration found.
<info>   devices added (path: /sys/devices/virtual/net/lo, iface: lo)
<info>   device added (path: /sys/devices/virtual/net/lo, iface: lo): no ifupdown configuration found.
<info>   devices added (path: /sys/devices/virtual/net/oray_vnc, iface: oray_vnc)
<info>   device added (path: /sys/devices/virtual/net/oray_vnc, iface: oray_vnc): no ifupdown configuration found.
<info>   end _init.
<info>   settings: loaded plugin ifupdown: (C) 2008 Canonical Ltd.  To report bugs please use the NetworkManager mailing list. (/usr/lib/x86_64-linux-gnu/NetworkManager/libnm-settings-plugin-ifupdown.so)
<info>   settings: loaded plugin keyfile: (c) 2007 - 2016 Red Hat, Inc.  To report bugs please use the NetworkManager mailing list.
<info>   (-1669857536) ... get_connections.
<info>   (-1669857536) connections count: 0
<info>   keyfile: new connection /etc/NetworkManager/system-connections/517 (e71c2949-e7f8-4975-b989-f6cb02bd04cb,"517")
<info>   keyfile: new connection /etc/NetworkManager/system-connections/1602 (29917d82-df10-4e30-9195-d887bec0c596,"1602")
<info>   manager: rfkill: WiFi enabled by radio killswitch; enabled by state file
<info>   manager: rfkill: WWAN enabled by radio killswitch; enabled by state file
<info>   manager: Networking is enabled by state file
<info>   dhcp-init: Using DHCP client 'dhclient'
<info>   Loaded device plugin: NMBondDeviceFactory (internal)
<info>   Loaded device plugin: NMBridgeDeviceFactory (internal)
<info>   Loaded device plugin: NMDummyDeviceFactory (internal)
<info>   Loaded device plugin: NMEthernetDeviceFactory (internal)
<info>   Loaded device plugin: NMInfinibandDeviceFactory (internal)
<info>   Loaded device plugin: NMIPTunnelDeviceFactory (internal)
<info>   Loaded device plugin: NMMacsecDeviceFactory (internal)
<info>   Loaded device plugin: NMMacvlanDeviceFactory (internal)
<info>   Loaded device plugin: NMPppDeviceFactory (internal)
<info>   Loaded device plugin: NMTunDeviceFactory (internal)
<info>   Loaded device plugin: NMVethDeviceFactory (internal)
<info>   Loaded device plugin: NMVlanDeviceFactory (internal)
<info>   Loaded device plugin: NMVxlanDeviceFactory (internal)
<info>   Loaded device plugin: NMWifiFactory (/usr/lib/x86_64-linux-gnu/NetworkManager/libnm-device-plugin-wifi.so)
<info>   Loaded device plugin: NMWwanFactory (/usr/lib/x86_64-linux-gnu/NetworkManager/libnm-device-plugin-wwan.so)
<info>   Loaded device plugin: NMTeamFactory (/usr/lib/x86_64-linux-gnu/NetworkManager/libnm-device-plugin-team.so)
<info>   Loaded device plugin: NMBluezManager (/usr/lib/x86_64-linux-gnu/NetworkManager/libnm-device-plugin-bluetooth.so)
<info>   Loaded device plugin: NMAtmManager (/usr/lib/x86_64-linux-gnu/NetworkManager/libnm-device-plugin-adsl.so)
<info>   device (lo): carrier: link connected
<info>   manager: (lo): new Generic device (/org/freedesktop/NetworkManager/Devices/1)
<info>   manager: (enp1s0): new Ethernet device (/org/freedesktop/NetworkManager/Devices/2)
<info>   keyfile: add connection in-memory (a638a2a5-a19a-39d6-a0e0-2840da5a0ca2,"有线连接 1")
<info>   settings: (enp1s0): created default wired connection '有线连接 1'
<info>   device (enp1s0): state change: unmanaged -> unavailable (reason 'managed', sys-iface-state: 'external')
<info>   manager: (oray_vnc): new Tun device (/org/freedesktop/NetworkManager/Devices/3)
<info>   keyfile: add connection in-memory (e337ff38-7609-4f50-8cbd-aeb292af4d31,"oray_vnc")
<info>   device (oray_vnc): state change: unmanaged -> unavailable (reason 'connection-assumed', sys-iface-state: 'external')
<info>   device (oray_vnc): state change: unavailable -> disconnected (reason 'connection-assumed', sys-iface-state: 'external')
<info>   device (oray_vnc): Activation: starting connection 'oray_vnc' (e337ff38-7609-4f50-8cbd-aeb292af4d31)
<info>   wifi-nl80211: (wlp2s0): using nl80211 for WiFi device control
<info>   device (wlp2s0): driver supports Access Point (AP) mode
<info>   manager: (wlp2s0): new 802.11 WiFi device (/org/freedesktop/NetworkManager/Devices/4)
<info>   device (wlp2s0): state change: unmanaged -> unavailable (reason 'managed', sys-iface-state: 'external')
<info>   device (oray_vnc): state change: disconnected -> prepare (reason 'none', sys-iface-state: 'external')
<info>   modem-manager: ModemManager available
<info>   supplicant: wpa_supplicant running
<info>   device (wlp2s0): supplicant interface state: init -> starting
<info>   device (oray_vnc): state change: prepare -> config (reason 'none', sys-iface-state: 'external')
<info>   device (oray_vnc): state change: config -> ip-config (reason 'none', sys-iface-state: 'external')
<info>   device (oray_vnc): state change: ip-config -> ip-check (reason 'none', sys-iface-state: 'external')
<info>   device (oray_vnc): state change: ip-check -> secondaries (reason 'none', sys-iface-state: 'external')
<info>   device (oray_vnc): state change: secondaries -> activated (reason 'none', sys-iface-state: 'external')
<info>   manager: NetworkManager state is now CONNECTED_LOCAL
<info>   device (oray_vnc): Activation: successful, device activated.
<info>   sup-iface[0x55d39c733990,wlp2s0]: supports 5 scan SSIDs
<info>   device (wlp2s0): supplicant interface state: starting -> ready
<info>   device (wlp2s0): state change: unavailable -> disconnected (reason 'supplicant-available', sys-iface-state: 'managed')
<info>   policy: auto-activating connection '1602'
<info>   device (wlp2s0): Activation: starting connection '1602' (29917d82-df10-4e30-9195-d887bec0c596)
<info>   device (wlp2s0): state change: disconnected -> prepare (reason 'none', sys-iface-state: 'managed')
<info>   manager: NetworkManager state is now CONNECTING
<info>   device (wlp2s0): state change: prepare -> config (reason 'none', sys-iface-state: 'managed')
<info>   device (wlp2s0): Activation: (wifi) access point '1602' has security, but secrets are required.
<info>   device (wlp2s0): state change: config -> need-auth (reason 'none', sys-iface-state: 'managed')
<info>   sup-iface[0x55d39c733990,wlp2s0]: wps: type pbc start...
<info>   device (wlp2s0): state change: need-auth -> prepare (reason 'none', sys-iface-state: 'managed')
<info>   device (wlp2s0): state change: prepare -> config (reason 'none', sys-iface-state: 'managed')
<info>   device (wlp2s0): Activation: (wifi) connection '1602' has security, and secrets exist.  No new secrets needed.
<info>   Config: added 'ssid' value '1602'
<info>   Config: added 'scan_ssid' value '1'
<info>   Config: added 'bgscan' value 'simple:30:-80:86400'
<info>   Config: added 'key_mgmt' value 'WPA-PSK'
<info>   Config: added 'auth_alg' value 'OPEN'
<info>   Config: added 'psk' value '<hidden>'
<info>   device (wlp2s0): supplicant interface state: ready -> authenticating
<info>   device (wlp2s0): supplicant interface state: authenticating -> associating
<info>   device (wlp2s0): supplicant interface state: associating -> 4-way handshake
<info>   device (wlp2s0): supplicant interface state: 4-way handshake -> completed
<info>   device (wlp2s0): Activation: (wifi) Stage 2 of 5 (Device Configure) successful.  Connected to wireless network '1602'.
<info>   device (wlp2s0): state change: config -> ip-config (reason 'none', sys-iface-state: 'managed')
<info>   dhcp4 (wlp2s0): activation: beginning transaction (timeout in 45 seconds)
<info>   dhcp4 (wlp2s0): dhclient started with pid 6906
DHCPREQUEST of 192.168.1.115 on wlp2s0 to 255.255.255.255 port 67
DHCPACK of 192.168.1.115 from 192.168.1.1
<info>   dhcp4 (wlp2s0):   address 192.168.1.115
<info>   dhcp4 (wlp2s0):   plen 24 (255.255.255.0)
<info>   dhcp4 (wlp2s0):   gateway 192.168.1.1
<info>   dhcp4 (wlp2s0):   lease time 7200
<info>   dhcp4 (wlp2s0):   nameserver '103.85.85.222'
<info>   dhcp4 (wlp2s0):   nameserver '114.114.114.114'
<info>   dhcp4 (wlp2s0):   domain name 'DHCP'
<info>   dhcp4 (wlp2s0):   domain name 'HOST'
<info>   dhcp4 (wlp2s0): state changed unknown -> bound
<info>   device (wlp2s0): state change: ip-config -> ip-check (reason 'none', sys-iface-state: 'managed')
<info>   device (wlp2s0): state change: ip-check -> secondaries (reason 'none', sys-iface-state: 'managed')
<info>   device (wlp2s0): state change: secondaries -> activated (reason 'none', sys-iface-state: 'managed')
<info>   manager: NetworkManager state is now CONNECTED_LOCAL
bound to 192.168.1.115 -- renewal in 2779 seconds.
<info>   manager: NetworkManager state is now CONNECTED_SITE
<info>   policy: set '1602' (wlp2s0) as default for IPv4 routing and DNS
<info>   device (wlp2s0): Activation: successful, device activated.
<info>   manager: startup complete
```


```
<info>  [1597840115.9191] NetworkManager (version 1.20.4) is starting... (for the first time)
<info>  [1597840115.9191] Read config: /etc/NetworkManager/NetworkManager.conf (lib: 10-dns-resolved.conf, 10-globally-mana
<warn>  [1597840115.9192] config: unknown key 'wifi.cloned-mac-address' in section [device-mac-addr-change-wifi] of file '/
<warn>  [1597840115.9192] config: unknown key 'ethernet.cloned-mac-address' in section [device-mac-addr-change-wifi] of fil
<info>  [1597840115.9255] bus-manager: acquired D-Bus service "org.freedesktop.NetworkManager"
systemd[1]: Started Network Manager.
<info>  [1597840115.9583] manager[0x557b8892a060]: monitoring kernel firmware directory '/lib/firmware'.
<info>  [1597840115.9583] monitoring ifupdown state file '/run/network/ifstate'.
<info>  [1597840116.2385] hostname: hostname: using hostnamed
<info>  [1597840116.2385] hostname: hostname changed from (none) to "tao-pc"
<info>  [1597840116.2387] dns-mgr[0x557b8890f290]: init: dns=systemd-resolved rc-manager=symlink, plugin=systemd-resolved
<info>  [1597840116.2389] manager[0x557b8892a060]: rfkill: Wi-Fi hardware radio set enabled
<info>  [1597840116.2389] manager[0x557b8892a060]: rfkill: WWAN hardware radio set enabled
<info>  [1597840116.4866] Loaded device plugin: NMWifiFactory (/usr/lib/x86_64-linux-gnu/NetworkManager/1.20.4/libnm-device
<info>  [1597840116.5837] Loaded device plugin: NMWwanFactory (/usr/lib/x86_64-linux-gnu/NetworkManager/1.20.4/libnm-device
<info>  [1597840116.6898] Loaded device plugin: NMTeamFactory (/usr/lib/x86_64-linux-gnu/NetworkManager/1.20.4/libnm-device
<info>  [1597840116.8002] Loaded device plugin: NMBluezManager (/usr/lib/x86_64-linux-gnu/NetworkManager/1.20.4/libnm-devic
<info>  [1597840116.8339] Loaded device plugin: NMAtmManager (/usr/lib/x86_64-linux-gnu/NetworkManager/1.20.4/libnm-device-
<info>  [1597840116.8341] manager: rfkill: Wi-Fi enabled by radio killswitch; enabled by state file
<info>  [1597840116.8342] manager: rfkill: WWAN enabled by radio killswitch; enabled by state file
<info>  [1597840116.8342] manager: Networking is enabled by state file
<info>  [1597840116.8343] dhcp-init: Using DHCP client 'internal'
<info>  [1597840116.8816] settings: Loaded settings plugin: ifupdown ("/usr/lib/x86_64-linux-gnu/NetworkManager/1.20.4/libn
<info>  [1597840116.8817] settings: Loaded settings plugin: keyfile (internal)
<info>  [1597840116.8817] ifupdown: management mode: unmanaged
<warn>  [1597840116.9153] ifupdown: interfaces file /etc/network/interfaces doesn't exist
<info>  [1597840116.9996] device (lo): carrier: link connected
<info>  [1597840116.9998] manager: (lo): new Generic device (/org/freedesktop/NetworkManager/Devices/1)
<info>  [1597840117.0003] manager: (eno1): new Ethernet device (/org/freedesktop/NetworkManager/Devices/2)
<info>  [1597840117.0012] settings: (eno1): created default wired connection 'Wired connection 2'
<info>  [1597840117.0014] device (eno1): state change: unmanaged -> unavailable (reason 'managed', sys-iface-state: 'extern
<warn>  [1597840117.2165] Error: failed to open /run/network/ifstate
<info>  [1597840117.2303] modem-manager: ModemManager available
<info>  [1597840122.0332] device (eno1): carrier: link connected
<info>  [1597840122.0338] device (eno1): state change: unavailable -> disconnected (reason 'carrier-changed', sys-iface-sta
<info>  [1597840122.0355] policy: auto-activating connection 'Wired connection 2' (b2a2bb78-9680-39e1-8071-1cecb5187959)
<info>  [1597840122.0369] device (eno1): Activation: starting connection 'Wired connection 2' (b2a2bb78-9680-39e1-8071-1cec
<info>  [1597840122.0371] device (eno1): state change: disconnected -> prepare (reason 'none', sys-iface-state: 'managed')
<info>  [1597840122.0378] manager: NetworkManager state is now CONNECTING
<info>  [1597840122.0380] device (eno1): state change: prepare -> config (reason 'none', sys-iface-state: 'managed')
<info>  [1597840122.0384] device (eno1): state change: config -> ip-config (reason 'none', sys-iface-state: 'managed')
<info>  [1597840122.0386] dhcp4 (eno1): activation: beginning transaction (timeout in 45 seconds)
<info>  [1597840122.0864] dhcp4 (eno1): state changed unknown -> bound
<info>  [1597840122.0874] device (eno1): state change: ip-config -> ip-check (reason 'none', sys-iface-state: 'managed')
<info>  [1597840122.1261] device (eno1): state change: ip-check -> secondaries (reason 'none', sys-iface-state: 'managed')
<info>  [1597840122.1266] device (eno1): state change: secondaries -> activated (reason 'none', sys-iface-state: 'managed')
<info>  [1597840122.1277] manager: NetworkManager state is now CONNECTED_LOCAL
<info>  [1597840122.1301] manager: NetworkManager state is now CONNECTED_SITE
<info>  [1597840122.1304] policy: set 'Wired connection 2' (eno1) as default for IPv4 routing and DNS
<info>  [1597840122.1316] device (eno1): Activation: successful, device activated.
<info>  [1597840122.1336] manager: startup complete
<info>  [1597840124.7201] manager: NetworkManager state is now CONNECTED_GLOBAL
<info>  [1597840149.4350] agent-manager: req[0x7f961c001ee0, :1.327/org.gnome.Shell.NetworkAgent/1000]: agent registered
```