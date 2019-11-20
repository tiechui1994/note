## tcpdump

命令行选项:

命令行选项

-i INTERFACE, 指定监听的网卡, 如果要监听所有网卡, 可以使用 any;
-n,  不解析主机名, 而是显示IP地址;
-nn, 不解析主机名和端口对应的服务名, 而是显示IP地址和端口号;

-v, 详细输出, 如TTL, 总长度, IP包选项, IP/ICMP报头校验和, 使用-w写入文件时每隔10秒显示捕获的数据包数量等;
-vv, 更详细的输出, 如打印NFS附加字段, 完全解码SMB数据包等;

-t, 不显示任何时间戳;
-tt, 显示自**1970-01-01 00:00:00 UTC**起的秒数;
-ttt, 显示两个数据包之间的时间差(微秒);

-e, 打印链路层头部(比如MAC地址信息);
-c N, 只捕获N个数据包, 捕获完成后自动退出;
-s SIZE, 定义捕获的数据包大小(字节为单位), 默认是68字节
-l 打印时使用行缓冲, 这在使用管道时非常方便;
-P：指定要抓取的包是流入还是流出的包. 可以给定的值为"in","out"和"inout". 默认为"inout"

-w FILE 将捕获到的数据包保存至pcap文件中;
-r FILE 从pcap文件中读取数据包并进行分析;


过滤表达式:
**type**类型: host, net, port, portrange. 默认是host
- host, 可以是主机名,也可以是IP地址
- net, net 172.16.0.0 mask 255.240.0.0 或 net 172.16.0.0/12
- port, 可以为端口号, 也可以为对应的服务名(/etc/services)
- portrange, 使用减号表示一个端口范围. portrange 100-200

**dir**方向: src, dst, src or dst, src and dst. 默认是src or dst

**proto**协议: ip, ip6, arp, rarp, tcp, udp. 默认是所有可用协议.

顺序: 最前面是proto, 然后是dir, 最后是type; 同时可以使用and, or, not逻辑连接符.

案例:
```
host 1.2.3.4 and not port 80 and not port 8080;

tcp dst port 20 or 21 or 22; <=> tcp dst port 20 or tcp dst port 21 or tcp dst port 22
```
