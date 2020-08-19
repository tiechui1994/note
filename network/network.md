## Ubuntu 下 NetworkManger 启动流程分析

1, 加载配置文件 `/etc/NetworkManager/NetworkManager.conf`

2, 监控 `ifupdown state` 文件 `/run/network/ifstate`

3, 设置 `hostname` 为 `/etc/hostname`

4, 初始化 `dns-mgr`

到此为止, NetworkManager 已经启动, 接下来是初始化 `network interface device`

5, 解析 `/etc/network/interfaces`, `/etc/network/interfaces.d` 下的 `interface` 配置文件.

设置 `management mode`, `managed` 或者 `unmanaged`

6, 创建 `network interface device`

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