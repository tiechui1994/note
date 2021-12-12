# interface 配置

在 Ubuntu 系统当中, 网卡的配置的文件主要有以下:

- /etc/network/interfaces, /etc/network/interfaces.d

- /etc/netplan/*.yaml(在Ubuntu 18.04之后的版本出现的)

> 注:
> 1. 如果使用 `netplan` 配置网络, 在 `/etc/netplan/` 目录下的每个 yaml 文件有一个对应的网络配置文件, 该文件在
`/run/systemd/network/` 当中. 
> 2. 如果使用 `networks` 配置网络, 网卡对应的配置文件在 `/run/NetworkManager/system-connections` 目录或 
`/etc/NetworkManager/system-connections` 目录.

## 使用 interfaces 

/etc/network/interfaces 文件是 由零个或多个 "iface", "mapping", "auto", "allow-", "rename", "source", 和
"source-directory" section 组成.

以 "auto" 开头的行用于标识使用 `-a` 选项运行 ifup 时要启动的物理interface. interface 名称紧跟在 "auto" 后面.

以 "allow-" 开头的行用于标识子系统自动启动的interface. 这可以使用诸如 "ifup --allow=hotplug eth0 eth1" 之类的命
令来完成. 如果 eth0 或 eth1 出现在 "allow-hotplg" 行后面, 则会对 eth0 或 eth1 启用 hotplg 子系统.

以 "rename" 开头的行用于重命名interface. 它采用 "CUR=NEW" 的格式来重命名interface. 其中CUR为现有interface名称,
NEW是新名称. 每当调用 "ifup" 时, interface 就会被重命名. 例如: 

```
rename foo=bar
auto foo
iface bar ...
```

以 "mapping" 开头的行用于确定如何为要启动的interface选择逻辑接口名称, 紧跟其后的是 shell glob 语法中的模式. 每一个
"mapping" 必须包含一个脚本, 该脚本以interface名称作为参数运行, 并在其标准输入中提供给它 "mapping" 后续的内容(不包含,
"maping" 行). 在脚本退出之前, 脚本必须在其标准输出打印一个字符串. 脚本参考 `/usr/share/doc/ifupdown/examples`.


以 "iface" 开头的行用于定义逻辑interface, 接下来是interface名称. 在interface名称后面紧跟这个interface使用的地址
协议族. TCP/IP网络("inet"), IPX网络("ipx"), IPv6网络("inet")等. 接下来的是用于配置interface的方法. 在后续的行
当中可以提供其他配置选项.

可以为同一个interface提供多个 "iface" section, 这种情况下, 在启动该interface时将应用该interface的所有配置地址和
选项.


可以定义一个模板, 并使用 `inherits` 关键字继承该模板.

```
iface ethernet inet static
    mtu 1500
    hwaddress 11:22:33:44:55:66

iface eth0 inet static inhertits ethernet
    mtu 1500
    hwaddress 11:22:33:44:55:66
```


INET ADDRESS FAMILY 支持的配置网卡的方法:

1. loopback 
该方法用于定义 IPv4 环路网口.

2. static
该方法用于定于以太网静态分配的 IPv4 地址. 包含的选项有:

```
- address <address>, 其中 <address> 可以包含子网掩码

- netmask <mask>

- broadcast <broadcast_address>

- metric <metric>, 默认网关的路由度数(整数)

- gateway <address>, 路由网关

- pointopoint <address>

- hwadress <address>, mac地址或"random"

- mtu <size>, MTU大小

- scope global|link|host, 地址有效范围
```

3. manual
该方法用于定于默认情况下不进行配置的interface. 此类interface可以通过 up 或 down 命令或 `/etc/network/if-*.d` 脚
本手动设置. 包含的选项有:

```
- hwadress <address>, mac地址或"random"

- mtu <size>, MTU大小
```

4. dhcp
此方法用于使用任何工具通过DHCP获取地址: dhclient, pump, udhcpc, dhcpcd. 包含的选项:

```
- hostname <hostname>, 请求的主机名(pump, dhcpcd, udhcpc)

- metric <metric>, 网关的路由度数(dhclient)

- leasehours <leasehours> 租赁时长,小时(pump)

- leasetime <leasetime> 租赁时长,秒(dhcpcd)

- vendor <vendor> 供应商类别标识符(dhcpcd)

- client <client> 客户端标识符(dhcpcd)

- hwadress <address>, mac地址
```

5. tunnel
此方法用于创建GRE或IPIP隧道. 需要从iproutr包中获取ip二进制文件. 对于 GRE 隧道, 需要为IPIP隧道加载 ip_gre 和 ipip
模块. 包含的选项:

```
- address <address> Local地址

- mode <tyoe> 隧道类型(GRE, IPIP)

- endpoint <address> 其他隧道端点的地址

- dstaddr <address> Remote地址

- local <address> local 端点地址

- metric <metric> 默认网关路由度

- gateway <address> 默认网关

- ttl <time> TTL

- mtu <size>
```

6. ppp
该方法使用 pon/poff 配置的 PPP 网口. 可选的选项:

```
- provider <name> 使用provider(/etc/ppp/peers目录下)的名称

- unit <number> 使用 number 作为 ppp 单元号

- options <string> 将字符串作为附加选项传递给pon
```

> 地址协议族还有 "IPX ADDRESS FAMILY", "INET6 ADDRESS FAMILY", "CAN ADDRESS FAMILY". 由于这些地址协议族不太
经常使用. 可以使用 `man interfaces` 参考相关的节.


## 使用 netplan