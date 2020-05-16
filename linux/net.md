## 网络排查的命令

### netstat

netstat, 打印 `network connections`, `routing tables`, `interface statistics`, 
`masquerade connections(伪装连接)`, 和 `multicast memberships(多播身份)`

```
netstat  [--tcp|-t]  [--udp|-u]  [--raw|-w]  
         [--numeric|-n] [--numeric-hosts] [--numeric-ports] [--numeric-users] 
         [--symbolic|-N]  [--timers|-o]  
         [--all|-a] [--listening|-l]  [--program|-p]  
         [--extend|-e[--extend|-e]] [--verbose|-v] [--continuous|-c]


netstat  {--route|-r}      
         [--numeric|-n] [--numeric-hosts] [--numeric-ports] [--numeric-users] 
         [--extend|-e[--extend|-e]] [--verbose|-v] [--continuous|-c]

netstat  {--interfaces|-i}     
         [--numeric|-n]  [--numeric-hosts] [--numeric-ports] [--numeric-users] 
         [--all|-a] [--program|-p]
         [--extend|-e[--extend|-e]]  [--verbose|-v]  [--continuous|-c]

netstat  {--groups|-g} 
         [--numeric|-n] [--numeric-hosts] [--numeric-ports] [--numeric-users] 
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
--numeric-hosts          don't resolve host names
--numeric-ports          don't resolve port names
--numeric-users          don't resolve user names
-N, --symbolic           resolve hardware names

-e, --extend             display other/more information
-p, --programs           display PID/Program name for sockets
-c, --continuous         continuous listing

-l, --listening          display listening server sockets
-a, --all, --listening   display all sockets (default: connected)
-o, --timers             display timers
-F, --fib                display Forwarding Information Base (default)
-C, --cache              display routing cache instead of FIB
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
-E, --events        continually display sockets as they are destroyed

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
-d, --dccp          display only DCCP sockets
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