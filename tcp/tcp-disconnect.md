# TCP 链接问题
 
## write: broken pipe

tcpdump 关于 tcp 连接的细节:

> client 关闭连接后, server两次向client发送数据
```
# 建立连接
17:18:40.953658 IP localhost.52938 > localhost.1234: Flags [S], seq 3712756688, win 43690, options [mss 65495,sackOK,TS val 1424896580 ecr 0,nop,wscale 7], length 0
17:18:40.953666 IP localhost.1234 > localhost.52938: Flags [S.], seq 719482259, ack 3712756689, win 43690, options [mss 65495,sackOK,TS val 1424896580 ecr 1424896580,nop,wscale 7], length 0
17:18:40.953672 IP localhost.52938 > localhost.1234: Flags [.], ack 1, win 342, options [nop,nop,TS val 1424896580 ecr 1424896580], length 0

# 数据传输
17:18:40.953735 IP localhost.52938 > localhost.1234: Flags [P.], seq 1:6, ack 1, win 342, options [nop,nop,TS val 1424896580 ecr 1424896580], length 5
17:18:40.953739 IP localhost.1234 > localhost.52938: Flags [.], ack 6, win 342, options [nop,nop,TS val 1424896580 ecr 1424896580], length 0

# 断开连接
17:18:40.953748 IP localhost.52938 > localhost.1234: Flags [F.], seq 6, ack 1, win 342, options [nop,nop,TS val 1424896580 ecr 1424896580], length 0
17:18:40.993847 IP localhost.1234 > localhost.52938: Flags [.], ack 7, win 342, options [nop,nop,TS val 1424896620 ecr 1424896580], length 0
17:18:44.954014 IP localhost.1234 > localhost.52938: Flags [P.], seq 1:7, ack 7, win 342, options [nop,nop,TS val 1424900580 ecr 1424896580], length 6
17:18:44.954047 IP localhost.52938 > localhost.1234: Flags [R], seq 3712756695, win 0, length 0
```

客户端(client): localhost.52938
服务端(server): localhost.1234

client 与 server 正常建立连接.

client向server发送数据, 发送完毕之后, client关闭连接.

server读取client发送的数据之后, 短暂sleep(保证client关闭连接), server向client两次发送数据, 其中第二次产生了错误 
**write: broken pipe**

关闭过程:
完全关闭: 直接关闭输入和输出
半关闭(Output): 关闭输出
半关闭(Input): 关闭输入

## read: connection reset by peer

> client 退出(没有关闭连接), server读取连接的数据.
```
15:17:28.534823 IP 192.168.1.9.48912 > 192.168.1.5.1234: Flags [S], seq 252184786, win 29200, options [mss 1460,sackOK,TS val 3174478527 ecr 0,nop,wscale 7], length 0
15:17:28.534967 IP 192.168.1.5.1234 > 192.168.1.9.48912: Flags [S.], seq 4123407632, ack 252184787, win 28960, options [mss 1460,sackOK,TS val 577110 ecr 3174478527,nop,wscale 7], length 0
15:17:28.534983 IP 192.168.1.9.48912 > 192.168.1.5.1234: Flags [.], ack 1, win 229, options [nop,nop,TS val 3174478527 ecr 577110], length 0

15:17:29.035244 IP 192.168.1.9.48912 > 192.168.1.5.1234: Flags [P.], seq 1:6, ack 1, win 229, options [nop,nop,TS val 3174479027 ecr 577110], length 5
15:17:29.035265 IP 192.168.1.9.48912 > 192.168.1.5.1234: Flags [P.], seq 6:11, ack 1, win 229, options [nop,nop,TS val 3174479027 ecr 577110], length 5
15:17:29.035461 IP 192.168.1.5.1234 > 192.168.1.9.48912: Flags [.], ack 6, win 227, options [nop,nop,TS val 577235 ecr 3174479027], length 0
15:17:29.035494 IP 192.168.1.5.1234 > 192.168.1.9.48912: Flags [.], ack 11, win 227, options [nop,nop,TS val 577235 ecr 3174479027], length 0
15:17:33.036805 IP 192.168.1.5.1234 > 192.168.1.9.48912: Flags [P.], seq 1:7, ack 11, win 227, options [nop,nop,TS val 578235 ecr 3174479027], length 6
15:17:33.036848 IP 192.168.1.9.48912 > 192.168.1.5.1234: Flags [.], ack 7, win 229, options [nop,nop,TS val 3174483029 ecr 578235], length 0
15:17:33.041289 IP 192.168.1.9.48912 > 192.168.1.5.1234: Flags [R.], seq 11, ack 7, win 229, options [nop,nop,TS val 3174483033 ecr 578235], length 0
```

// golang测试的时候, 出现神奇的8效应. 当同时建立连接的数量在8以为(包括8), 读取不会发生此错误.错误是 `EOF`, 但是超过8
之后, 才会产生 `read: connection reset by peer`


