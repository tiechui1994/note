# 虚拟网络设备

Bridge, 802.1.q, VLAN device, VETH, TAP

## bridge

bridge是Linux提供的一种虚拟网卡设备之一. 其工作方式非常类似于物理的网络交换机设备. Linux bridge 可以工作在二层, 也可
以工作在三层, 默认工作在二层.工作在二层时, 可以在同一网络的不同主机之间转发以太网报文; 一旦给一个 Linux bridge 分配了
IP地址, 也就开启了该 bridge 的三层工作模式.

bridge是Linux上工作在内核协议栈二层的虚拟交换机. 虽然是软件实现的, 但它与普通的二层物理交换机功能一样. 可以添加若干个网
络设备(em1,eth0,tap,..) 到 bridge 上(brctl addif)作为其接口, 添加到 bridge 上的设备被设置为只接受二层数据帧并且
转发所有收到的数据包到 bridge 中(bridge内核模块), 在 bridg e中会进行一个类似物理交换机的查 MAC 端口映射表,转发,更新
MAC端口映射表这样的处理逻辑, 从而数据包可以被转发到另一个接口/丢弃/广播/发往上层协议栈, 由此 bridge 实现了数据转发的功
能. 如果使用 tcpdump 在 bridge 接口上抓包, 是可以抓到桥上所有接口进出的包.

> 跟物理交换机不同的是, 运行 bridge 的是一个 Linux 主机, Linux 主机本身也需要IP地址与其它设备通信. 但被添加到 bridge
上的网卡是不能配置IP地址的, 他们工作在数据链路层(2层), 对路由系统不可见. 

不过 bridge 本身可以设置IP地址, 可以认为当使用 `brctl addbr br0` 新建一个 `br0` 网桥时, 系统自动创建了一个同名的
隐藏 br0 网络设备. br0 一旦设置 IP 地址, 就意味着 br0 可以作为路由接口设备(三层), 参与 IP 层的路由选择(可以使用 `route -n`
查看最后一列 Iface). 因此只有当 br0 设置IP地址时, bridg e才有可能将数据包发往上层协议栈.

Linux 下, 可以使用 `ip link` 或 `brctl` 对 bridge 进行管理.

```
# 创建 br0
ip link add br0 type bridge
brctl addr br0

# 删除 br1
ip link del br0
brtctl delbr br0

# 将 eth0 加入网桥 br0
ip link set dev eth0 master br0
brctl addif br0 eth0

# 从网桥 br0 删除 eth0
ip link set dev eth0 nomaster
brctl delif br0 eth0

# 查看网桥
bridge link
brctl show 
```

- bridge工作过程

![image](/images/net_type_bridge.png)

介绍: 主机有em1和em2两块网卡, 网桥br0.  用户空间进程app1, app2等是普通网络应用, OpenVPN进程P1, 以及一台或多台kvm
虚拟机P2(kvm虚拟机实现为主机上的一个qemu-kvm进程, 下文使用qemu-kvm进程表示虚拟机). 

**bridge处理数据包流程**

br0有N个**TAP**类型的接口(tap0, ..., tapN), TAP设备名称可能不同, 例如:`tap45400fa0-9c`, `vnet*`, 但都是TAP设
备.  一个"隐藏"的br0接口(可设置IP), 以及物理网卡em2的一个**VLAN**子设备em2.100(简单看做有一个网卡桥接到br0上), 它们
都是工作在链路层(Link Layer).

数据从外部网络(A)发往虚拟机(P2)qume-kvm的过程: 首先数据包从em2(B)物理网卡进入, 之后em2将数据包转发给其VLAN子设备
em2.100, 经过`Bridge check`(L)发现子设备em2.100属于网桥接口设备, 因此数据包不会发往协议栈上层(T), 而是进入Bridge
代码处理逻辑, 从而数据包从em2.100接口(C)进入br0, 经过`Bridging decision`(D)发现数据包应当从tap0(E)接口发出, 此时
数据包离开主机网络协议栈(G), 发往被用户空间进程qemu-kvm打开的字符设备`/dev/net/tun`(N), qemu-kvm进程执行系统调用
read()从字符设备读取数据. (A->B->L->C->D->E->M->P2)

在这个过程中, 外部网络A发出的数据包是不会也没必要进入主机上层协议栈的, 因为A是与主机网的P2虚拟机通讯, **主机只是起到一个
网桥转发的作用**

如果是从网卡em1(M)进入主机的数据包, 经过`Bridge Check`(L)后, 发现em1非网桥接口, 则数据包会直接发往(T)协议栈IP层, 从
而在`Routine decision`环节决定数据包的去向(A->M->T->K)


**bridging decision**

网桥br0收到数据包后, 根据数据包目的MAC的不同, `Bridging decision`环节(D)对数据包的处理有以下几种:
a)包的目的MAC为Bridge本身的MAC地址(当br0设置有IP地址), 从MAC地址一层来看, 收到发往主机自身的数据包, 交给上层协议栈(D->J)
b)广播包, 转发到Bridge上所有接口(br0,tap0,tap1,...)
c)单播且存在MAC端口映射表, 查表直接转发到对应接口(比如D->E)
d)单播且不存在MAC端口映射表, 泛洪到Bridge连接的所有接口(br0,tap0,tap1,...)
e)数据包目的地址接口不是网桥接口, 网桥不处理, 交给上层协议栈(D->J)

---

- 限制 与 数据流方向

Bridge的实现当前有一个限制: 当一个设备被attach到Bridge上时, 那个设备的IP会的无效, Linux不再使用那个IP在三层接收数据.
例如: 如果eth0本来的ip是192.168.1.2, 此时如果收到一个目标地址是192.168.1.2的数据, Linux的应用程序能通过Socket操作
接收它. 而当eth0被attach到一个bridge0时, 尽管eth0的ip还存在, 但应用程序是无法接收到上述数据的. 此时应该把ip 192.168.1.2
赋予bridge0

数据流的方向. 对于一个被attach到Bridge上的设备来说, 只有它收到数据时, 此包数据才会被转发到Bridge上, 进而完成查表广播等
后续操作. 当请求是发送类型时, 数据是不会转发到Bridge上的, 它会寻找下一个发送出口. 用户在配置网络时经常忽略这一点从而造成
网络故障.

## VLAN 802.1.q

VLAN 又称虚拟网络. 此处主要说的是在物理世界中存在的, 需要协议支持的VLAN. 它的种类很多, 按照协议原理一般分为: MACVLAN
802.1.q VLAN, 802.1.qbg VLAN, 802.1.qbh VLAN.  其中出现较早, 应用广泛且比较成熟的是802.1.q VLAN, 其基本原理是
在二层协议里插入额外的VLAN协议数据(称为 802.1.q VLAN Tag), 同时保持和传统二层设备的兼容性. Linux里的VLAN设备是对
802.1.q协议的一种内部软件实现, 模拟现实世界中的802.1.q交换机.

Linux里802.1.q VLAN 设备是以母子关系成对出现的, 母设备相当于现实世界中交换机TRUNK口, 用于连接上级网络, 子设备相当于
普通接口用于连接下级网络. 

当数据在母子设备间传递时, 内核将会根据802.1.q VLAN Tag 进行对应操作.

母子设备直接是一对多的关系, 一个母设备可以有多个子设备, 一个子设备只有一个母设备.

当一个子设备有一包数据需要发送时, 数据将被加入VLAN Tag, 然后从母设备发送出去. 当母设备接收到一包数据时, 它将会分析其中
的VLAN Tag, 如果有对应的子设备存在, 则把数据转发到那个子设备上并根据设置移除VLAN Tag, 否则丢弃该数据.

在某些设置下, VLAN Tag可以不被移除以满足某些监听程序的需要, 如DHCP服务程序. 例子如下:
eth0作为母设备创建了一个ID为100的子设备eth0.100. 此时如果有程序要求从eth0.100发送一包数据, 数据将打上VLAN 100的tag
从eth0发送出去. 如果eth0收到一包数据, VLAN Tag是100, 数据将被转发到eth0.100上, 并根据设置决定是否移除VLAN Tag. 如
果eth0收到一包数据, tag是VLAN 101, 其将被丢弃.

上述过程隐含的事实: 对于寄主Linux系统来说, 母设备只能用来收数据, 子设备只能用来发送数据. 和Bridge一样, 母子设备的数据也
是有方向的, 子设备收到的数据不会进入母设备, 同样母设备上请求发送的数据不会被转发到子设备上.

注意: 母子VLAN设备拥有相同的MAC地址, 可以把它当成现实世界中802.1.q交换机的MAC, 因此多个VLAN设备会共享一个MAC. 当一个
母设备拥有多个VLAN子设备, 子设备之间是隔离的, 不存在Bridge那样交换转发关系, 原因如下: 802.1.q VLAN 协议的主要目的是
从逻辑上隔离子网. 现实世界中的802.1.q 交换机存在多个VLAN, 每个VLAN拥有很多个端口, 同一个VLAN端口之间可以交换转发, 不
同VLAN端口之间隔离, 所以其包含两层功能: 交换和隔离. Linux VLAN设备实现的是隔离功能, 没有交换功能. 一个VLAN母设备拥有
两个相同ID的VLAN子设备, 因此就不可能出现数据交换情况. 

如果想让一个VLAN里接多个设备, 就需要交换功能. 在Linux里Bridge专门实现交换功能, 因此将VLAN子设备attach到一个Bridge
上就能完成后续的交换功能. 

总结: VLAN + Bridge = 现实世界的802.1.q交换机

## TAP/TUN

TAP/TUN 设备是一种让用户态程序向内核协议栈注入数据的设备. TAP 等同于一个以太网设备, 工作在二层; 而 TUN 则是一个虚拟点
对点设备, 工作在三层.

> 实现`tun/tap`设备的内核模块为`tun`, 其模块为`Universal TUN/TAP device driver`, 该模块提供了一个设备接口
`/dev/net/tun` 供用户程序读写, 用户程序通过读写 `/dev/net/tun` 向主机内核协议栈注入数据或接收来自主机内核协议的数据,
可以把 `tun/tap` 看成数据管道, 它的一端连接主机协议栈, 另一端连接用户程序.
>
> 为了使用 `tun/tap` 设备, 用户程序需要通过系统调用打开 `/dev/net/tun` 获得一个读写设备文件描述符(FD), 并且调用
ioctl() 向内核注册一个 TUN或TAP 类型的虚拟网卡(实例化一个tun/tap设备), 其名称可能是 `vnetXX/tunXX/tapXX` 等, 此
后, 用户程序可以通过该虚拟网卡与主机内核协议栈交互. 当用户程序关闭之后, 其注册的 TUN或TAP 虚拟网卡以及路由表相关条目(使
用tun可能会产生路由表条目, 例如openvpn) 都会被内核释放. 可以把用户程序看做是网络上另一台主机, 它们通过 tap/tun 虚拟网
卡与主机相连.

TAP 与 TUN 的区别在于, TAP 工作在第2层, TUN 工作在第3层. TAP 连接的用户层程序发出的数据不用穿越主机协议栈的网络层,
直接到达数据链路层.

Linux 上可以使用 `ip tuntap` 来操作 TAP/TUN 设备.

```
# 创建 tap/tun
ip tuntap add dev tap0 mod tap
ip tuntap add dev tun0 mod tun

# 删除 tap/tun
ip tuntap del dev tap0 mod tap
ip tuntap del dev tun0 mod tun
```

## veth

veth 设备总是成对出现, 也称为 veth pair. 一端发送的数据会由另一端接收. 如果 veth-a 和 veth-b 是一对 veth 设备,
veth-a 收到的数据会从 veth-b 发出, 反之已然.

Linux 上可以使用 `ip link` 操作 veth 设备:

```
# 添加
ip link add veth-a type veth peer name veth-b

# 删除
ip link del veth-a
```

当删除 veth pair 时. 只需要删除 veth-a 或 veth-b 其中一个即可. 因为veth pair总是成对出现的.
 