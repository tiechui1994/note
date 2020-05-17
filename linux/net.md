## 网络排查的命令

### netstat

netstat, 打印 `network connections`, `routing tables`, `interface statistics`, 
`masquerade connections(伪装连接)`, 和 `multicast memberships(多播身份)`

```
netstat  [--tcp|-t]  [--udp|-u]  [--raw|-w]  
         [--numeric|-n] 
         [--symbolic|-N]  [--timers|-o]  
         [--all|-a] [--listening|-l]  [--program|-p]  
         [--extend|-e[--extend|-e]] [--verbose|-v] [--continuous|-c]


netstat  {--route|-r}      
         [--numeric|-n]
         [--extend|-e[--extend|-e]] [--verbose|-v] [--continuous|-c]

netstat  {--interfaces|-i}     
         [--numeric|-n]
         [--all|-a] [--program|-p]
         [--extend|-e[--extend|-e]]  [--verbose|-v]  [--continuous|-c]

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