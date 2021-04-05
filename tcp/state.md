## TCP 链接的状态转换

TCP的状态转换图:

![image](/images/tcp_state.png)

TCP 状态转换的两条主线:

对客户端(也可以是服务器, 客户端主动打开链接, 服务器被动打开):

```
CLOSED -> SYN_SENT -> ESTABLISHED -> FIN_WAIT_1 -> FIN_WAIT_2 -> TIME_WAIT -> CLOSED
```

> 注: 若客户端到达 FIN_WAIT_1, 它同时接收到服务器的FIN, ACK, 则它会直接跳过FIN_WAIT_2而到达
TIME_WAIT状态

对服务端:

```
CLOSED -> LISTEN -> SYN_RCVD -> ESTABLISHED -> CLOSE_WAIT -> LAST_ACK -> CLOSED
```

>注: 客户端和服务器端可能同时打开连接或同时关闭连接(很少), 这时处理稍微不大一样.


状态说明:

CLOSED - 初始状态, 表示 TCP 连接是"关闭着的"或"未打开的".

LISTEN - 表示服务器端的某个 SOCKET 处于监听状态, 可以接受客户端的连接.

SYN_SENT - 这个状态与 SYN_RCVD 状态相呼应, 当客户端 SOCKET 执行 connect() 进行连接时, 它首先发送 SYN 报文, 然后
随即进入到 SYN_SENT 状态, 并等待服务端的发送三次握手中的第 2 个报文. SYN_SENT 状态表示客户端已发送 SYN 报文.

SYN_RECV - 表示接收到了 SYN 报文. 在正常情况下, 这个状态是服务器端的 SOCKET 在建立 TCP 连接时的三次握手会话过程中的
一个中间状态, 很短暂, 基本上用 netstat 很难看到这种状态(除非故意写一个监测程序, 将三次 TCP 握手过程中最后一个 ACK 报
文不予发送). 当 TCP 连接处于此状态时, 再收到客户端的 ACK 报文, 它就会进入到 ESTABLISHED 状态.

ESTABLISHED - 表示 TCP 连接已经成功建立, 数据可以传送给用户;


**FIN_WAIT_1** - 其实 FIN_WAIT_1 和 FIN_WAIT_2 两种状态的真正含义都是表示等待对方的 FIN 报文. 而这两种状态的区别
是: FIN_WAIT_1 状态实际上是当 SOCKET 在 ESTABLISHED 状态时, 它想主动关闭连接, 向对方发送了 FIN 报文, 此时该 SOCKET 
进入到 FIN_WAIT_1 状态. 而当对方回应 ACK 报文后, 则进入到 FIN_WAIT_2 状态. 当然在实际的正常情况下, 无论对方处于任
何种情况下, 都应该马上回应 ACK 报文, 所以 FIN_WAIT_1 状态一般是比较难见到的, 而 FIN_WAIT_2 状态有时仍可以用 netstat 
看到.


**FIN_WAIT_2** - 上面已经解释了这种状态的由来, 实际上 FIN_WAIT_2 状态下的 SOCKET 表示半连接, 即有一方调用close() 
主动要求关闭连接. 注意: `FIN_WAIT_2 是没有超时的 (不像 TIME_WAIT 状态), 这种状态下如果对方不关闭(不配合完成 4 次挥手
过程), 那这个 FIN_WAIT_2 状态将一直保持到系统重启, 越来越多的 FIN_WAIT_2 状态会导致内核崩溃.`


**CLOSE_WAIT** - 表示正在等待关闭. 当对方 close() 一个 SOCKET 后发送 FIN 报文给自己, 你的系统毫无疑问地将会回应一
个 ACK 报文给对方, 此时 TCP 连接则进入到 CLOSE_WAIT 状态. 接下来呢, 你需要检查自己是否还有数据要发送给对方, 如果没有
的话, 那你也就可以 close() 这个 SOCKET 并发送 FIN 报文给对方, 即关闭自己到对方这个方向的连接. 有数据的话则看程序的策
略, 继续发送或丢弃. 简单地说, 当你处于 CLOSE_WAIT 状态下, 需要完成的事情是等待你去关闭连接. 这个状态可以用 netstat 
看到.


**CLOSING** - 这种状态在实际情况中应该很少见, 属于一种比较罕见的例外状态. 正常情况下, 当一方发送 FIN 报文后, 按理来说
是应该先收到(或同时收到)对方的 ACK 报文, 再收到对方的 FIN 报文. 但是 CLOSING 状态表示一方发送 FIN 报文后, 并没有收到
对方的 ACK 报文, 反而却也收到了对方的 FIN 报文. 什么情况下会出现此种情况呢? 那就是当双方几乎在同时 close() 一个 SOCKET 
的话, 就出现了双方同时发送 FIN 报文的情况, 这时就会出现 CLOSING 状态, 表示双方都正在关闭 SOCKET 连接.


**LAST_ACK** - 当被动关闭的一方在发送 FIN 报文后, 等待对方的 ACK 报文的时候, 就处于 LAST_ACK 状态. 当收到对方的 
ACK 报文后, 也就可以进入到 CLOSED 可用状态了.


**TIME_WAIT** - 等待足够的时间以确保远程 TCP 接收到连接中断请求的确认; 表示收到了对方的 FIN 报文, 并发送出了 ACK 报文.
TIME_WAIT 状态下的 TCP 连接会等待 2*MSL (Max Segment Lifetime, 最大分段生存期, 指一个 TCP 报文在 Internet 上的
最长生存时间. 每个具体的 TCP 协议实现都必须选择一个确定的 MSL 值, RFC 1122 建议是 2 分钟, 但 BSD 传统实现采用了 30 秒,
Linux 可以 `cat /proc/sys/net/ipv4/tcp_fin_timeout` 看到本机的这个值), 然后即可回到 CLOSED 可用状态了. 
如果 FIN_WAIT_1 状态下, 收到了对方同时带 FIN 标志和 ACK 标志的报文时, 可以直接进入到 TIME_WAIT 状态, 而无须经过 
FIN_WAIT_2 状态.

## 三次握手

- 一般状况:(3次)

```
主动方:
CLOSED -> SYN_SENT -> ESTABLISHED

被动方:
CLOSED -> SYN_RCVD -> ESTABLISHED
```

- 双方同时打开:(4次)

```
CLOSED -> SYN_SENT -> ESTABLISHED
```


## 四次挥手

- 一般状况:(4次)

```
主动方:
ESTABLISHED -> FIN_WAIT_1 -> FIN_WAIT_2 -> TIME_WAIT -> CLOSED

被动方:
ESTABLISHED -> CLOSE_WAIT -> LASK_ACK -> CLOSED
```

- 双方基本同时关闭:(4次)

当双方同时断开连接时, 都会主动发送 `FIN`. 

```
ESTABLISHED -> FIN_WAIT_1 -> CLOSING -> TIME_WAIT -> CLOSED
```

- 特殊状况:(3次)

当主动方准备断开连接时, 被动方刚好数据传输完毕(但是未发送FIN). 此时被动方在接收到`FIN`后, 回复`FIN+ACK`

```
主动方:
ESTABLISHED -> FIN_WAIT_1 -> TIME_WAIT -> CLOSED

被动方:
ESTABLISHED -> LASK_ACK -> CLOSED
```

## 常见问题

1) 为什么建立连接协议是三次握手，而关闭连接却是四次握手呢？

这是因为, 服务端的 LISTEN 状态下的 SOCKET 当收到 SYN 报文的连接请求后, 它可以把 ACK 和 SYN (ACK 起应答作用, 而 
SYN 起同步作用) 放在一个报文里来发送. 但关闭连接时, 当收到对方的 FIN 报文通知时, 它仅仅表示对方没有数据发送给你了; 但
未必你所有的数据都全部发送给对方了, 所以你可以未必会马上会关闭 SOCKET, 也即你可能还需要发送一些数据给对方之后, 再发送 
FIN 报文给对方来表示你同意现在可以关闭连接了, 所以它这里的 ACK 报文和 FIN 报文多数情况下都是分开发送的.


2) 为什么 TIME_WAIT 状态还需要等 2MSL 后才能返回到 CLOSED 状态?

A. 可靠地实现 TCP 全双工连接的终止

TCP 协议在关闭连接的四次握手过程中, 最终的 ACK 是由主动关闭连接的一端(后面统称 A 端)发出的, 如果这个 ACK 丢失, 对方(
后面统称 B 端)将重发出最终的 FIN, 因此 A 端必须维护状态信息(TIME_WAIT)允许它重发最终的 ACK. 如果 A 端不维持 TIME_WAIT 
状态, 而是处于 CLOSED 状态, 那么 A 端将响应 RST 分节, B 端收到后将此分节解释成一个错误(在 java 中会抛出 connection 
reset 的 SocketException).

因而, 要实现 TCP 全双工连接的正常终止, 必须处理终止过程中四个分节任何一个分节的丢失情况, 主动关闭连接的 A 端必须维持 
TIME_WAIT 状态.


B. 允许老的重复分节在网络中消逝(实际也就是`避免同一端口对应多个套接字`)

TCP 分节可能由于路由器异常而"迷途", 在迷途期间, TCP 发送端可能因确认超时而重发这个分节, 迷途的分节在路由器修复后也会
被送到最终目的地, 这个迟到的迷途分节到达时可能会引起问题. 在关闭"前一个连接"之后, 马上又重新建立起一个相同的 IP 和端口之
间的"新连接", "前一个连接"的迷途重复分组在"前一个连接"终止后到达, 而被"新连接"收到. 为了避免这个情况,`TCP 协议不允许处
于 TIME_WAIT 状态的连接启动一个新的可用连接, 因为 TIME_WAIT 状态持续 2MSL, 就可以保证当成功建立一个新 TCP 连接的时
候, 来自旧连接重复分组已经在网络中消逝.`


3) 关闭 TCP 连接一定需要四次挥手吗?

不一定, 四次挥手关闭 TCP 连接是最安全的做法. 但在有些时候, 我们不喜欢 TIME_WAIT 状态 (如当 MSL 数值设置过大导致服务器
端有太多 TIME_WAIT 状态的 TCP 连接, 减少这些条目数可以更快地关闭连接, 为新连接释放更多资源), 这时我们可以通过设置 
SOCKET 变量的 SO_LINGER 标志来避免 SOCKET 在 close() 之后进入 TIME_WAIT 状态, 这时将通过发送 RST 强制终止 TCP 
连接(取代正常的 TCP 四次握手的终止方式). 但这并不是一个很好的主意, TIME_WAIT 对于我们来说往往是有利的.

## TCP KeepAlive 机制

KeepAlive 机制是 TCP 的一种扩展功能, 用于探测连接的对端是否存活.

需要注意的点:

1. TCP KeepAlive 默认状况下是关闭, 可以被上层应用开启和关闭.

2. TCP KeepAlive 必须在**没有任何数据(包括ACK包)接收之后的周期内才会被发送**, 允许配置这个周期的时间, 默认是7200秒

3. 不包含数据的ACK段被TCP发送时没有可靠性保证, 即一旦发送, 不确保一定发送成功. 

4. TCP 保活探测报文序列号 = 前一个TCP报文序列号 - 1. 即下一次正常报文号等于ACK序列号.

KeepAlive的相关参数:

```
tcp_keepalive_time, 在 TCP KeepAlive开启的状况下, 最后一次数据交换到TCP发送第一个保活探测包的间隔, 即允许持续空闲
的时长, 或者说正常发送心跳的周期, 默认值是 7200 秒. socket 选项是 TCP_KEEPIDLE

tcp_keepalive_probes, 在 tcp_keepalive_time 之后, 没有接收到对方确认, 继续发送保活探测包的次数, 默认值是9. socket
选项是 TCP_KEEPCNT

tcp_keepalive_intvl, 在 tcp_keepalive_time 之后, 没有接收到对方确认, 继续发送保活探测包的发送频率, 默认值是 75
秒. socket的选项是 TCP_KEEPINTVL
```

开启 TCP KeepAlive: 设置 socket 的 `SO_KEEPALIVE` 选项为 `true`.

在 Go 当中, 提供了 `SetKeepAlive()` (开启/关闭 keepalive) 和 `SetKeepAlivePeriod()` (设置 keepalive 的选项 
`tcp_keepalive_time` 和 `tcp_keepalive_intvl`, 两个参数的值是一样的)

> 在 Go 的 TCP 的客户端连接的时候, 默认是开启 KeepAlive, 并且 `TCP_KEEPINTVL` 和 `TCP_KEEPIDELE` 的默认时长是
15秒(除非设置 Dialer.KeepAlive 参数)
>
> 在 Go 的 TCP Server 端 Accept 接收连接的时候, 默认是开启 KeepAlive, 并且`TCP_KEEPINTVL` 和 `TCP_KEEPIDELE` 的默认时长是
15秒(除非设置 ListenConfig.KeepAlive 参数)

使用场景:

- 检测挂掉的连接(导致挂掉的原因很多,服务停止, 网络波动, 宕机, 服务重启等)

- 防止因为网络不活动而断连(NAT代理或者防火墙的时候, 经常出现这种问题)

- TCP层面的心跳检测.

KeepAlive 通过定时发送探测包来探测连接的对端是否存活, 但是通常也会在业务层面处理的, 它们之间的区别:

1. TCP 自带的 KeepAlive 使用简单, 发送的数据包相比应用层心跳检测更小, 仅提供检测连接功能.

2. 应用层心跳包不依赖于传输协议, 无论传输层协议是TCP还是UDP都可以使用.

3. 应用层心跳包可以定制, 可以应对更复杂的情况或传输一些额外信息.

4. KeepAlive 仅代表连接保持着, 而心跳往往代表客户端可正常工作.


TCP KeepAlive 与 HTTP KeepAlive 的区别:

1. HTTP 的 KeepAlive 意图在于连接复用, 同一个连接上串行方式请求-响应数据.

2. TCP 的 KeepAlive 机制意图在于保活, 心跳, 检测连接错误.
