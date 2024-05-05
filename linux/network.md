# linux 网络工具(dig, nslookup, host, netstat, ss, telnet, nc)

## DNS 解析

### dig

dig 是域名信息搜索器的简称(Domain Information Grouper), 使用 dig 命令可以执行查询域名相关的任务.

```
$ dig baidu.com

# dig 程序的版本号和要查询的域名
; <<>> DiG 9.11.3-1-Debian <<>> baidu.com

# 表示可以在命令后面加选项
;; global options: +cmd

# 以下是获取信息的内容
;; Got answer:

# 信息的头部, 包含以下内容:
# opcode: 操作码, QUERY代表查询操作; 
# status: 状态, NOERROR代表没有错; 
# id: 编号, 16bit数字
# flags: 标记, 如果出现就表示有标志, 如果不出现就表示为设置标志. 
#        qr query, 表示查询操作, 
#        rd recursive desired, 表示递归查询操作
#        ra recursive available, 表示查询的服务器支持递归查询操作
#        aa authorization answer, 表示查询结果由管理域名的域名服务器而不是缓存服务器提供的.
# 
# QUERY: 查询数, 1表示一个查询,  对应下面 QUESTION SECTION的记录数
# ANSWER: 结果数, 2表示2个结果, 对应下面 ANSWER SECTION 的记录数
# AUTHORITY: 权威域名服务器记录数, 对应下面 AUTHORITY SECTION 的记录数
# ADDITIONAL: 格外记录数, 对应下面的 ADDITIONAL SECTION 的记录数
#
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 19160
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 1


;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096

# 查询部分, 从左到右含义
# 1. 查询的域名, 这里是 baidu.com., '.' 代表根域名, com 代表顶级域, baidu 代表二级域名
# 2. class, 查询信息的类别. IN代表类别为IP协议.
#    CH代表CHAOS类
#    HS
# 3. type, 查询的记录类型, A记录(Address), 代表ipv4, AAAA记录,代表ipv6地址. 
#    NS记录(Name Server), 解析服务器. SOA记录(start of a zone of authority), 标记权威区域的开始. 
#    MX记录(mail exchange),代表发送到此域名的邮件将被解析到的服务器IP地址
#    CNAME记录, 别名记录. PTR记录, 反向解析记录
;; QUESTION SECTION:
;baidu.com.            IN	A

# 响应部分, 回应的都是A记录, 含义如下
# 1. 对应的域名
# 2. TTL, 缓存时间, 单位是秒
# 3. class, 查询信息的类别
# 4. type, 查询的记录记录类型
# 5. 域名对应的ip地址
;; ANSWER SECTION:
baidu.com.        0	IN	A	220.181.38.148
baidu.com.        0	IN	A	39.156.69.79

# 查询耗时
;; Query time: 86 msec

# 查询使用的DNS服务器地址和端口号
;; SERVER: 103.85.85.222#53(103.85.85.222)

# 查询时间
;; WHEN: Sun May 17 22:15:20 CST 2020

# 响应大小, 单位是字节
;; MSG SIZE  rcvd: 70
```

- 格式

```
dig [domain] [@global-server] [q-class] [q-type] {q-opt}
              host [@local-server] {local-d-opt}
             [host [@local-server] {local-d-opt} [...]]
```

```
q-class  is one of (in,hs,ch,...) [default: in]

q-type   is one of (a,any,mx,ns,soa,hinfo,axfr,txt,...) [default:a]
         (Use ixfr=version for type ixfr)
         
q-opt    is one of:
         -4                  (use IPv4 query transport only)
         -6                  (use IPv6 query transport only)
         -b address[#port]   (bind to source address/port)
         -f filename         (batch mode)
         -i                  (IPv6反向域名解析)
         -k keyfile          (specify tsig key file)
         -c class            (specify query class)
         -p port             (specify port number)
         -q name             (specify query name)
         -t type             (specify query type)
         -x dot-notation     (IPv4反向域名解析)

d-opt    is of the form +keyword[=value], where keyword is:
         +[no]aaonly         (Set AA flag in query (+[no]aaflag))
         +[no]all            (Set or clear all display flags)
         +[no]answer         (Control display of answer section)
         +[no]authority      (Control display of authority section)
         +[no]besteffort     (Try to parse even illegal messages)
         +[no]cl             (Control display of class in records)
         +[no]cmd            (Control display of command line)
         +[no]search         (Set whether to use searchlist)
         +[no]short          (Display nothing except short form of answer)
         +[no]trace          (Trace delegation down from root [+dnssec])
```

### nslookup

```
nslookup [domain|ip]
```

- 解析域名

```
$ nslookup www.baidu.com
Server:        127.0.1.1
Address:    127.0.1.1#53

Non-authoritative answer:
www.baidu.com    canonical name = www.a.shifen.com.
Name:    www.a.shifen.com
Address: 220.181.38.150
Name:    www.a.shifen.com
Address: 220.181.38.149
```

- 反向解析

```
$ nslookup 1.1.1.1
Server:        127.0.1.1
Address:    127.0.1.1#53

Non-authoritative answer:
1.1.1.1.in-addr.arpa    name = one.one.one.one.

Authoritative answers can be found from:
```

### host

```
Usage: host [-aCdlriTwv] [-c class] [-N ndots] [-t type] [-W time]
            [-m flag] hostname [server]
   
   -c specifies query class for non-IN data
   -t specifies the query type
   -W specifies how long to wait for a reply
   -m set memory debugging flag (trace|record|usage)
    
   -r disables recursive processing

   -v enables verbose output
   -w specifies to wait forever for a reply
   -4 use IPv4 query transport only
   -6 use IPv6 query transport only
```


```
$ host -v baidu.com
Trying "baidu.com"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 8240
;; flags: qr rd ra; QUERY: 1, ANSWER: 2, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;baidu.com.            IN	A

;; ANSWER SECTION:
baidu.com.        276	IN	A	39.156.69.79
baidu.com.        276	IN	A	220.181.38.148

Received 59 bytes from 127.0.1.1#53 in 17 ms


Trying "baidu.com"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 10408
;; flags: qr rd ra; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 0

;; QUESTION SECTION:
;baidu.com.            IN	AAAA

;; AUTHORITY SECTION:
baidu.com.        276	IN	SOA	dns.baidu.com. sa.baidu.com. 2012142458 300 300 2592000 7200

Received 70 bytes from 127.0.1.1#53 in 15 ms


Trying "baidu.com"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 55457
;; flags: qr rd ra; QUERY: 1, ANSWER: 5, AUTHORITY: 0, ADDITIONAL: 0

;; QUESTION SECTION:
;baidu.com.            IN	MX

;; ANSWER SECTION:
baidu.com.        4675	IN	MX	20 mx1.baidu.com.
baidu.com.        4675	IN	MX	20 jpmx.baidu.com.
baidu.com.        4675	IN	MX	20 mx50.baidu.com.
baidu.com.        4675	IN	MX	10 mx.maillb.baidu.com.
baidu.com.        4675	IN	MX	15 mx.n.shifen.com.

Received 143 bytes from 127.0.1.1#53 in 17 ms
```

## 网络链接详情

### netstat

netstat, 打印 `network connections`, `routing tables`, `interface statistics`, 
`masquerade connections(伪装连接)`, 和 `multicast memberships(多播身份)`

```
netstat  [--tcp|-t]  [--udp|-u]  [--raw|-w]  
         [--numeric|-n] 
         [--symbolic|-N]  [--timers|-o]  
         [--all|-a] [--listening|-l]  [--program|-p]  
         [--extend|-e] [--verbose|-v] [--continuous|-c]


netstat  {--route|-r}      
         [--numeric|-n]
         [--extend|-e] [--verbose|-v] [--continuous|-c]

netstat  {--interfaces|-i}     
         [--numeric|-n]
         [--all|-a] [--program|-p]
         [--extend|-e]  [--verbose|-v]  [--continuous|-c]

netstat  {--groups|-g} 
         [--numeric|-n]
         [--continuous|-c]

netstat  {--statistics|-s} 
         [--tcp|-t] [--udp|-u] [--raw|-w]
```

- 类别过滤

```
-r, --route              display routing table
-i, --interfaces         display interface table
-g, --groups             display multicast group memberships
-s, --statistics         display networking statistics (like SNMP)
```

- 显示信息 

```
-v, --verbose            be verbose
-n, --numeric            don't resolve names
-N, --symbolic           resolve hardware names

-t, --tcp                display only tcp Proto
-u, --udp                display only udp Proto
-w, --raw                display only raw Proto
-x, --unix               display only unix Proto

-e, --extend             display other/more information
-p, --programs           display PID/Program name for sockets
-c, --continuous         continuous listing

-l, --listening          display listening server sockets
-a, --all                display all sockets (default: connected)
-o, --timers             display timers
```

- 输出说明:

```
Recv-Q
   连接到此socket的用户程序(user program)未复制的字节数

Send-Q
   远程主机(remote host)未确认的字节数

Recv-Q, Send-Q 这些值应始终为零; 如果不是, 那么可能会有问题. 数据包不应在任何一个队列中堆积. 
对传出数据包(outgoing packets)进行简短的排队是正常行为. 
如果接收队列(Recv-Q)持续阻塞, 则可能是遭受了拒绝服务攻击(DOS). 
如果发送队列(Send-Q)不能很快清除, 则可能是因为某个应用程序发送它们的速度过快, 或者接收者无法足够快地接受它们.

State
   socket的状态. 在 RAW 模式下没有状态, 并且再 UDP 中通常也没有状态.
   
   ESTABLISHED
          Socket已建立连接
   SYN_SENT
          Socket正在积极尝试建立连接
   SYN_RECV
          已从网络接收到链接请求

   FIN_WAIT1
          Socket已关闭, 并且连接已经关闭
   FIN_WAIT2
          连接已经关闭, Socket正在等待远端关闭.
   TIME_WAIT
          Socket在关闭之后正在等待处理仍在网络中的数据包.
   
   CLOSE  
          未使用该Socket

   CLOSE_WAIT
          远端已关闭, 等待Socket关闭.
   LAST_ACK
          远端已关闭, Socket已关闭. 等待远端的确认.

   LISTEN 
          Socket正在监听传入的连接. 除非指定 --listening(-l) 或 --all(-a), 否则此类Socket不在输出中
          
   CLOSING
          两个Socket均已关闭, 但我们仍未发送所有的数据.

   UNKNOWN
          Socket的未知状态

Type
   Socket的类型

   SOCK_DGRAM
          该Socket在数据报(无连接)模式下使用. UDP
   SOCK_STREAM
          该Socket在流(有连接)模式下使用. TCP
   SOCK_RAW
          该Socket是RAW模式. 

   SOCK_RDM
          这个服务于可靠传递的消息.
   SOCK_SEQPACKET
          这是一个顺序的数据包套接字.
   SOCK_PACKET
          原始接口访问套接字.
```

### ss

`ss` 用于转储套接字统计信息. 它允许显示类似于 `netstat` 的信息. 它可以显示比其他工具更多的 TCP 和状态信息.

```shell
Usage: ss [ OPTIONS ]
       ss [ OPTIONS ] [ FILTER ]
```


```
-n, --numeric       解析端口号, 默认是服务名称
-r, --resolve       解析主机名称为IP

-o, --options       show timer information, 例如, timer:(keepalive,90min,0)
-e, --extended      show detailed socket information(其中包括timer, uid, ino, sk)
-p, --processes     show process using socket, 例如, users:(("speaker",pid=1547,fd=10))
-i, --info          show internal TCP information, 包含信息很多.
-E, --events        实时显示连接事件

-N, --net ns        切换到特定的网络命名空间(network namespace), NS_NET
```


- FILTER ( display部分 )

```
-a, --all           display all sockets
-l, --listening     display only listening sockets

-0, --packet        display PACKET sockets
-4, --ipv4          display only IP version 4 sockets
-6, --ipv6          display only IP version 6 sockets

-t, --tcp           display only TCP sockets
-u, --udp           display only UDP sockets
-w, --raw           display only RAW sockets
-x, --unix          display only Unix domain sockets
```

- FILTER (exp)

```
-A, --query=QUERY, --socket=QUERY
   QUERY := {all|inet|tcp|udp|raw|unix|unix_dgram|unix_stream|unix_seqpacket|packet|netlink}[,QUERY]
要转储的 socket type 的列表, 用逗号分隔.


-D, --diag=FILE     不显示任何内容, 仅在应用过滤器后将有关TCP套接字的原始信息转储到FILE中. 如果FILE是 `-` 使用
stdout.

-F, --filter=FILE   从FILE读取过滤器信息. FILE的每一行都像单个命令行选项一样被解析. 如果FILE是 - 使用stdin.

[ state STATE-FILTER ] [ EXPRESSION ] 状态,条件过滤

   STATE-FILTER := {all|connected|synchronized|bucket|big|TCP-STATES}
     TCP-STATES := {established|syn-sent|syn-recv|fin-wait-{1,2}|time-wait|closed|close-wait|last-ack|listen|closing}
      connected := {established|syn-sent|syn-recv|fin-wait-{1,2}|time-wait|close-wait|last-ack|closing}
   synchronized := {established|syn-recv|fin-wait-{1,2}|time-wait|close-wait|last-ack|closing}
         bucket := {syn-recv|time-wait}
            big := {established|syn-sent|fin-wait-{1,2}|closed|close-wait|last-ack|listen|closing}
   
     EXPRESSION, 参考 iproute-doc 的文档.
     例如, ss -o state established '( dport = :ssh or sport = :ssh )'
          ss -o state fin-wait-1 '( sport = :http or sport = :https )' dst 193.233.7/24
```


- 输出说明

```
    LISTEN state: Recv-Q 表示当前 listen backlog 队列中的连接数目(等待用户调用 accept() 获取的, 已完成3次握手的 socket 连接数量),
                  Send-Q 表示 listen socket 最大能容纳的 backlog, 即 min(backlog,somaxconn) 值.
            
not LISTEN state: Recv-Q 表示 receive queue 中存在的字节数目;
                  Send-Q 表示 send queue 中存在的字节数;
```

## 端口号检测

### telnet

telnet 命令用于使用 TELNET 协议与另一台主机进行交互通信.

它从命令模式开始, 在那里它打印一个 telnet 提示符("telnet>"). 如果使用主机参数调用 telnet, 它将隐式执行 open 命令;

```
telnet [OPTIONS] [host [port]]
```

常用的选项:

- `-4`, 强制使用 IPv4 地址解析

### nc

nc(netcat) 程序几乎涉及 TCP, UDP 或 UNIX 套接字的任何事情. 它可以打开 TCP 连接, 发送 UDP 数据包, 侦听任意 TCP 和 
UDP 端口, 进行端口扫描以及处理 IPv4 和 IPv6.

与 telnet 不同, nc 脚本很好, 并将错误消息分离到标准错误上, 而不是将它们发送到标准输出.

```
nc [OPTIONS] [destination] [port]
```

常用的选项:

- `-4`, 仅使用 IPv4 地址.

- `-b`, 允许 broadcast

- `-D`, 启用socket的DEBUG调试.

- `-U`, 使用 UNIX-domain socket

- `-u`, 使用 UDP socket

- `-t`, 使用 TCP socket

- `-I length`, 设置 TCP 的 recv buffer 大小

- `-O length`, 设置 TCP 的 send buffer 大小

- `-w timeout`, 超时时间(连接超时, 空闲超时), 单位是秒, `-w` 标志对 `-l` 选项没有影响. 即 nc 将永远侦听连接, 无论
有或没有 `-w` 标志. 默认是没有超时.

- `-l`, 监听 incoming 连接, 而不是启动与远程主机的连接. 要监听的 destination 和 port 非必选参数, 也可以分别与`-s` 
和 `-p` 选项指定. 但是不能与 `-x` 或 `-z` 一起使用. 此外, 使用 `-w` 选项指定的参数被忽略.

- `-s source`, 从具有 source IP 地址的网口发送数据包. 对于 UNIX 域数据报套接字, 指定要创建和使用的本地临时套接字文件,
以便可以接收数据报. 不能与 `-x` 一起使用.

- `-p source_port`, 指定 nc 应使用的源端口, 受权限限制和可用性限制.

- `-z`, 只是扫描监听守护进程, 不向它们发送任何数据. 不能与 `-l` 一起使用.

- `-x proxy_address[:port]`, 使用proxy_address和port的代理连接到目的地. 如果未指定端口, 则使用代理协议的已知端口
(SOCKS是1080, HTTPS为3128). 

- `-X proxy_protocal`, 设置代理使用代理协议. 目前支持的协议有 4 (SOCKS v.4), 5 (SOCKS v.5) 和 connect (HTTPS 代理).
如果未指定协议, 则使用 SOCKS 版本 5.


案例: tcp 端口扫描
```
nc -v -z -t 192.168.50.10 22
``` 

案例: udp 端口扫描
```
nc -v -z -u 192.168.50.10 500
```

