## netplan

netplan "network renderer" 读取 `/{lib,etc,run}/netplan/*.yaml` 并将配置写入到 `/run/systemd/network`, 从
而将设备的控制权交给指定的网络守护进程.

- 配置的设备默认由 systemd-networkd 管理, 除非明确标记为由特点渲染器(NetworkManager)管理

- 不会生成持久化的配置, 只保留原始的 YAML 配置.

- 解析器支持配置多个配置文件, 以允许 libvrit, lxd 等应用程序打包预期的网络配置(virbr0, lxdbr0), 或更改全局默认策略
以使用NetworkManager来处理所有事情.

**netplan 配置生效:**

```
# apply
sudo netplan --debug generate
sudo netplan --debug apply

# 重启 netplan 使用的 renderer
sudo systemctl restart NetworkManager.service
sudo systemctl restart systemd-networkd.service
```

#### Physical Device 

- match (mapping)

这将通过各种硬件属性选择可用物理设备的子集. 一旦匹配, 以下配置将应用于所有匹配的设备. 所有指定的属性必须匹配.

1) name, 当前interface名称. 支持 Glob, 并且是匹配的主要选项. 注意: 目前只有 networkd 支持 Glob, NetworkManager
不支持.

2) macaddress, 设备的 MAC 地址, 格式为 "XX:XX:XX:XX:XX:XX"

3) driver, 内核驱动程序名称, 对应于 DRIVER udev 属性. 支持 Glob. 只有networkd支持匹配驱动程序.

例子: 驱动是 ixgbe 的网口
```yaml
match:
    driver: ixgbe
    name: en*s0
```

- wakeonlan, 是否启用LAN唤醒. 默认值是 no

#### Common

- renderer, 定义使用给定的网络后端. 目前支持 networkd 和 NetworkManager. 此属性可以在网络中全局指定. 默认值是
networkd.

renderer 属性对于 vlan 类型还有一个额外的值: sriov. 如果使用 SRIOV 虚拟功能网口的 sriov 渲染器定义 valn, 这会导
致 netplan 为其设置硬件 VLAN 过滤器. 每个 VF 只能定义已过去.

- dhcp4, 是否为 IPv4 启用 DHCP. 默认值是 no

- dhcp6, 是否为 IPv6 启用 DHCP. 默认值是 no

- addresses, 除了通过DHCP或RA接收的地址外, 可以为网口设置静态地址. 每个条目采用CIDR表示法, 即 addr/prefixlen.

对于虚拟设备(bridge, bond, valn), 如果没有配置地址并且禁用了 DHCP, 网口依然会联机, 但无法从网络寻址.

案例:
```yaml
addresses: [192.168.14.2/24, "2001:1::1/64"]
```

> 注: `addresses`, `dhcp4`, `dhcp6` 可以同时使用, 这样可以为一个网卡配置多个IP地址. 一个网卡是支持配置多个IP地址
的, 但是一般情况下只是配置了一个IP.

- gateway4, 为 IPv4 设置默认网关, 用于手动地址配置. 

案例:
```yaml
gateway4: 172.16.0.1
```

- nameservers (mapping), 设置DNS服务器和搜索域, 用于手动地址配置. 支持两个字段: addresses, 类似于 gateway4 的
IPv4 的地址列表. search, 搜索域列表.

案例:
```yaml
ethernets:
    id0:
      nameservers:
        search: [lab, home]
        addresses: [8.8.8.8. "FEDC::1"]
```

- macaddress, 设备MAC地址

- mtu, 设置MTU大小, 默认值是1500

- routes (mapping), 设备的静态路由配置. 参考下面的 `路由属性`.

#### Route

使用 netplan 可以实现复杂的路由. 通过网络后端支持标准静态路由以及使用路由表的策略路由.

- routes (mapping), 路由块定义网口的标准静态路由. 必须指定 to 和 via 属性.

1) from, 为通过的路由的流量设置 Source IP地址.

2) to, 为路由设置 Destination IP地址.

3) via, 路由的网关地址.

4) on-link, 当设置为 "yes" 时, 指定路由直接连接到网口.

5) metric, 路由的相对优先级. 必须是正整数值.

6) type, 路由类型. 有效选项为 "unicast"(默认), "unreachable", "blackhole" 或 "prohibit".

7) scope, 路由范围, 是针对网络的范围有多广. 有效选项为"global", "link" 或"host".

8) table, 用于路由的表号. 在某些情况下, 在单独的路由表中设置路由可能很有用. 它还用于指代也接受表参数的路由策略规则. 允
许的值是从1开始的正整数. 一些值已用于引用特定的路由表: 参考 `/etc/iproute2/rt_tables`

#### Auth

netplan 支持通过 auth 认证以太网和wifi, 以及单个 wifi 网络的高级身份认证设置.

- auth (mapping) 指定类型为 ethernet 的设备身份验证设置, 或 wifi 设备上的

1) key-management, 支持的密钥管理模式. none(无密钥管理), psk(带有预共享密钥的WPA-PSK, 常见于家庭wifi), eap(WPA
with EAP, 常见于企业wifi), 802.1x(主要用于有线以太网连接).

2) password, EAP 的密码字符串, 或 WPA-PSK 的预共享密钥.

如果 key-manageent 是 eap 或 802.1x, 可以使用以下属性:

3) method, EAP 认证使用的方法. 支持的方法有: tls(TLS), peap(Protected EAQ), ttls(Tunneled TLS)

4) identity, EAP 身份

5) ca-certificate, 具有一个或多个受信任的证书颁发机构 (CA) 证书的文件的路径

6) client-certificate, 客户端在身份验证期间使用的证书的文件的路径.

7) client-key, 客户端证书对应的私钥的文件的路径

8) client-key-password, 用于解密 client-key 中指定的私钥(如果已加密)的密码.

#### Wifi interface

注意: systemd-networkd 本身并不支持 wifi, 因此如果让 networkd 渲染器处理 wifi, 则需要安装 wpasupplicant.

- access-points (mapping), 提供到NetworkManager 的预配置连接. 注意, 用户当然可以选择其他接入点/SSID. 

1) password, 启用 WPA2 身份认证并为其设置密码. 如果既没有当前设置, 也没有auth块, 则认为wifi网络是开放的.

```yaml
password: "S3Amazon"
```

等价于:

```yaml
auth:
    key-management: psk
    password: "S3Amazon"
```

#### VLAN interface

- id, VLAN ID, 整数(在0-4094之间)

- link, 在其上创建此 VLAN 的底层设备定义的 netplan ID.

例子:

```yaml
ethernets:
  eth0: {....}

vlans:
  en-intra:
    id: 1
    link: eth0
    dhcp4: yes
  en-vpn:
    id: 2
    link: eth0
    addresses: [192.168.1.10]
```

> 针对虚拟网口 VLAN, 最好使用 `addresses` 配置静态地址. 
