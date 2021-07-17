# network namespace(网络空间)

network namespace是实现网络虚拟化的重要功能, 它能创建多个隔离的网络空间, 它们有独立的网络栈信息.

ip命令管理的功能很多, 和 network namespace 有关的操作都是在子命令 `ip netns` 下进行的, 可以通过 `ip netns help` 
查看所有操作的帮助信息.

```
ip netns list
ip netns set NAME NETNSID
ip netns add NAME                 // 创建ns
ip [-all] netns delete [NAME]     // 删除ns
ip netns identify [PID]
ip netns pids NAME
ip [-all] netns exec [NAME] cmd ...  // 在ns下, 执行命令
ip netns monitor
ip netns list-id
```

## 创建network namespace

`ip netns`命令创建的 network namespace 会出现在`/var/run/netns/`目录下, 如果需要管理其他不是`ip netns`创建的
network namespace, 只要在这个目录下创建一个指向对应 network namespace 文件的链接就行.

对于每个network namespace来说, 它会有自己独立的网卡, 路由表, ARP表, iptables等和网络相关的资源.

每个namespace在创建的时候会自动创建一个lo的interface, 它的作用和Linux系统中默认的lo一样, 都是为了实现loopback通信.
如果要lo能工作, 需要启用它:
```
ip netns exec net1 ip link set lo up
```

默认情况下, network namespace 是不能和主机网络, 或者其他network namespace通信的.


## network namespace之间通信 -- veth

不同的network namespace之间是隔离的, 它们之间是没有办法通信的. linux 提供了veth pair, 可以把两个网络连接起来. 可
以把veth pair当做是双向的pipe(管道), 从一个方向发送网络数据, 可以直接被另外一端接收到. 

- 创建一对veth pair 
```
ip link add type veth
```

命名veth pair: (vethfoo, vethbar)
```
ip link add vethfoo type veth peer name vethbar
```


> 注: ip link add type veth 创建一对veth pair, veth pair是成对出现了, 无法单独存在, 删除其中一个, 另外一个也会自
动消失.

> 使用 ip link 可以查看当前环境存在的网路接口.


- 将veth pair分别放到两个namespace里面. `ip link set DEV netns NAME`
```
ip link set veth0 netns ns0
ip link set veth1 netns ns1
```

- 为这对veth pair配置ip地址.
```
ns0:
ip link set veth0 up
ip addr add 10.0.1.1/24 dev veth0
ip route

ns1:
ip link set veth1 up
ip addr add 10.0.1.2/24 dev veth1
ip route
```

- 检测ns0与ns1网路的连通性
```
ns0:
ping -c 3 10.10.1.2 
```

## network namespace之间通信 -- bridge

- 创建bridge 
```
ip link add br0 type bridge
ip link set dev br0 up
```

- 创建veth pair
```
ip link add type veth
```

- 将veth pair分别放到namespace和bridge当中.
```
ip link set dev veth1 netns ns0  // namespace

ip link set dev veth0 master br0 // bridge

ns0:
ip link set dev veth1 name eth0
ip addr add 10.0.1.1/24 dev eth0
ip link set dev eth0 up

br0:
ip link set veth0 up
```
