## TCP 相关的内核配置参数

```
net.ipv4.tcp_mem = 34809	46415	69618

确定 TCP 栈应该如何反映内存使用, 每个值的单位都是内存页(通常是4kb). 第一个值是内存使用的下限; 第二个值是内存压力模式开
始对缓冲区使用应用压力的上限; 第三个值是内存使用的上限; 在这个层次上可以将报文丢弃, 从而减少对内存的使用.
```

```
net.ipv4.tcp_wmem = 4096	16384	4194304

为自动调优定义socket使用的内存. 第一个值是为socket发送缓冲区分配的最少字节数; 第二个值是默认值(该值会被wmem_default
覆盖), 缓冲区在系统负载不重的情况下可以增长到这个值; 第三个值是发送缓冲区空间的最大字节数(该值会被wmem_max覆盖)

net.core.wmem_default = 212992
net.core.wmem_max = 212992

socket发送缓冲区默认和最大大小.
```

```
net.ipv4.tcp_rmem = 4096	87380	6291456

为自动调优定义socket使用的内存. 第一个值是为socket接收缓冲区分配的最少字节数; 第二个值是默认值(该值会被rmem_default
覆盖), 缓冲区在系统负载不重的情况下可以增长到这个值; 第三个值是接收缓冲区空间的最大字节数(该值会被rmem_max覆盖)

net.core.rmem_default = 212992
net.core.rmem_max = 212992

socket发送缓冲区默认和最大大小.
```