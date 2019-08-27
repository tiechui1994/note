# Linux 基础网络设备

Bridge, 802.1.q, VLAN device, VETH, TAP

## Bridge

Bridge(网桥)是Linux上用来做TCP/IP二层协议转换的设备, 与现实世界中的交换机功能类似.

Bridge设备实例可以和Linux上其他网络设备实例连接, 即attach一个从设备. 当有数据到达时, Bridge会根据报文中的MAC信息进行
广播, 转发, 丢弃处理.

> Bridge的功能主要在内核里实现. 

当一个从设备被attach到Bridge上时, 这时在内核程序会调用注册函数(一个用于接受数据的回调函数被注册).  以后**每当这个从设备
收到数据时**都会调用这个函数可以把数据转发到Bridge上.

当Bridge接收到此数据时, br_handle_frame()被调用,进行一个和现实世界中的交换机类似的处理过程: 判断包的类别(广播/单点),
查询内部MAC端口映射表, 定位目标端口号, 将数据转发到目标端口或丢弃, 自动更新内部MAC端口映射表以自我学习.

> Bridge VS 二层交换机

数据被直接发送到Bridge上, 而不是从一个端口接收. 这种状况可以看做Bridge自己有一个MAC可以主动发送报文, 或者说Bridge自带
了隐藏端口和寄主Linux系统自动连接, Linux上的程序可以直接从这个端口向Bridge上的其他端口发数据. 所以当一个Bridge拥有了一
个网络设备时, 如bridge0加入了eth0时, 实际上bridge0拥有了两个有效MAC地址, 一个是bridge0, 一个是eth0, 它们直接可以
通讯.

比较有趣的是, Bridge可以设置IP地址. 通常来说IP地址是三层协议的内容, 不应该出现在二层设备Bridge上. 但是Linux里Bridge
是通用网络抽象的一种, 只要是网络设备就能够设定IP地址.

当一个Bridge拥有IP后, Linux便可以通过路由表或者IP表规则在三层定位Bridge. 此时相当于Linux拥有了另外一个隐藏的虚拟网卡
和Bridge的隐藏端口相连.

Bridge的实现当前有一个限制: 当一个设备被attach到Bridge上时, 那个设备的IP会的无效, Linux不再使用那个IP在三层接收数据.
例如: 如果eth0本来的ip是192.168.1.2, 此时如果收到一个目标地址是192.168.1.2的数据, Linux的应用程序能通过Socket操作
接收它. 而当eth0被attach到一个bridge0时, 尽管eth0的ip还存在, 但应用程序是无法接收到上述数据的. 此时应该把ip 192.168.1.2
赋予bridge0

## 