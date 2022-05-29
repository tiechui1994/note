# SDP

## SDP 协议

https://www.rfc-editor.org/rfc/rfc4566

SDP 格式:

```
# 1. 会话级
v=  (protocol version)
o=  (origin and session identifier)
s=  (session name)
i=* (session information)
u=* (URI of description)
e=* (email address)
p=* (phone number)
c=* (connection information -- not required if included in all media)
b=* (zero or more bandwidth information lines)

t=  (time the session is active)
r=* (zero or more repeat times)
z=* (time zone adjustments)

k=* (encryption key)

a=* (zero or more session attribute lines)

# 2. 媒体级
m=  (media name and transport address)
i=* (media title)
c=* (connection information -- optional if included at session level)
b=* (zero or more bandwidth information lines)
k=* (encryption key)
a=* (zero or more media attribute lines)
```

## SDP 属性

### origin

```
o=<username> <session-id> <session-version> <nettype> <addrtype> <unicast-address>
```

`<username>` 是用户在主机上的登录名, 如果主机不支持用户 ID 的概念, 则为"-".

`<session-id>`, 数字字符串. origin 所有的字段想成一个全局唯一标识符. `<session-id>`分配的方法取决于创建的工具.

`<session-version>` 会话版本号.

`<nettype>` 和 `<addrtype>`, 分别表示网络类型和地址类型. 

`<unicast-address>`, 创建会话的机器的地址. 对于 IP4 地址类型, 是机器的完全限定性域名或机器IPv4地址.

> 通常，"o=" 字段用作此会话描述的此版本的全局唯一标识符, 并且除了版本之外的子字段一起标识会话, 而与任何修改无关.

### connection

```
c=<nettype> <addrtype> <connection-address>
```

会话描述必须在每个媒体描述中至少包含一个 `c=` 属性, 或在会话级别包含一个 `c=` 属性.

`<nettype>` 和 `<addrtype>`, 分别表示网络类型和地址类型.

`<connection-address>`, 连接地址. 根据 `<addrtype>` 字段的值，可以在连接地址之后添加可选子字段

1) 如果会话是多播的, 则连接地址是 IP 多播组地址. 如果会话不是多播, 则连接地址包含由附加属性字段确定的预期数据源或数据中继或数据接收器的单播
IP地址.

2) 除了多播地址为, 使用 IPv4 多播连接地址的会话必须具有TTL值. TTL和address共同定义了本次会话发送组播数据包的发送范围. TTL只必须在 0-255
范围内. 会话 TTL 使用斜杠作为分隔符附加到地址. 例如:

```
c=IN IP4 224.2.36.42/127
```

分层或分层编码方案是数据流, 其中来着单个media source的编码会被分成多个层. receiver 可以通过仅订阅这些层的子集来选择所需的quality(以及带
宽). 这种分层编码通常在多个组播中传输, 以允许多播修剪. 对于需要多播组的应用程序, 使用下面的连接地址格式:

```
<base mutilcast address>[/<ttl>]/<number of address>
```

如果没有给定 `<number of address>`, 则假定是1个.

如此分配的多播地址在基地址只是连续分配, 例如:

```
c=IN IP4 224.2.1.1/127/3
```

将地址 `224.2.1.1`, `224.2.1.2`, `224.2.1.3` 将以 127 的 TTL 使用.

> 注: 只有当为分层或分层编码方案中不同层提供多播地址时, 才能在每个 Media 的基础上指定多播地址.

### media

```
m=<media> <port> <proto> <fmt> ...
```

media 描述

`<media>`, media 类型, 当前定义的值包含: "audio", "video", "text", "application", "message"

`<port>` media steam 发送的端口. 传输端口依赖于 `c=` 当中指定正在使用的网络, 以及 `<proto>` 子字段定义的传输协议.

media 应用程序使用其他的端口(例如, RTCP端口可以通过算法从 base media port 派生, 或者可以在单独的属性中指定`[例如, "a=rtcp:"]`)

如果使用非连续的端口或者它们不遵循偶数RTP端口和奇数RTCP端口的奇偶校验, 则必须使用 "a=rtcp:" 属性. 请求将 RTP 发送到`<port>`, 将 RTCP
发送到 "a=rtcp:" 指定的端口.

对于将分层编码流发送到单播地址的应用程序, 可能需要指定多个传输端口. 

```
m=<media> <port>/<number of ports> <proto> <fmt> ...
```

这种情况下, 使用的端口取决于传输协议. 对于 RTP, 默认只有偶数端口用于数据, 对应的+1的奇数端口用于 RTCP. `<number of ports>` 表示RTP会话
数. 例如:

```
m=video 49170/2 RTP/AVP 31
```

将指定端口 49170 和 49171 形成一个 RTP/RTCP 对, 而 49172 和 49173 形成第二个 RTP/RTCP 对. 

如果在属性 "c=" 中指定了多个地址, 并且在 "m=" 属性中指定了多个端口, 则意味着从端口到相应地址的一对一映射. 例如:

```
c=IN IP4 224.2.1.1/127/2
m=video 49170/2 RTP/AVP 31
```

表示地址 224.2.1.1 与端口 49170, 49171 一起使用, 地址 224.2.1.2 与端口 49172, 49173 一起使用.

> 注: 在 RTC 场景中都是使用 ICE candidate 的地址信息进行数据传输的, 因此 `<port>` 并没有用到. 不过, 在 SIP 场景下, `<port>` 就十分
> 重要, 此时 `<port>` 就代表了 RTP 端口.


`<proto>`, 传输协议, 传输协议的含义取决于"c="的地址类型字段. 在 IP4 定义的传输协议:

1) UDP, 表示在 UDP 的协议

2) RTP/AVP, 表示 RTP 在 RTP Profile 下实现, 用于在 UDP 上运行的具有最小控制的 video 和 audio 

3) RTP/SAVP, 表示在 UDP 上运行的安全 SRTP 

`<fmt>` 媒体格式描述. 媒体格式取决于 `<proto>` 子字段的值. 

如果 `<proto>` 字段是 "RTP/AVP" 或 "RTP/SAVP", 则 `<fmt>` 子字段包含 RTP payload type number. 当给出 payload type number 列表
时, 这意味者这些 payload format 都可以在会话中使用, 但这些 format 当中第一个应该用作会话的默认格式.

如果 `<proto>` 子字段是 "UDP", 则数据格式必须使用 UDP 传输. 

## SDP 附加属性

### rtpmap

```
a=rtpmap:<payload type> <encoding name>/<clock rate> [/<encoding parameters>]
```

该属性从 RTP payload type number(例如 "m=" 当中的数字)映射到表示使用的 payload 的编码名称. 它提供有关 clock rate 和 encoding params
的信息. 该属性是媒体级属性.

作为一种 static payload type, 在使用 u-law PCM 编码的单通道 8kHZ sample 的音频, 它在 RTP Audio/Video 中被定义成 payload type 0,
它不需要再使用 `a=rtpmap:` 属性去描述. 例如, 发送到UDP端口 49232 的此类的流媒体可以指定为:

```
m=audio 49232 RTP/AVP 0
```

作为一种 dynamic payload type, 在使用 16-bit 线性编码的 16kHZ sample 的立体音频, 如果想为次流使用 dynamic payload 98, 则需要增加附
加属性对其进行描述:

```
m=audio 49232 RTP/AVP 98
a=rtpmap:98 L16/16000/2
```

可以为 media 定义多个 rtpmap 属性:

```
m=audio 49232 RTP/AVP 96 87 98
a=rtpmap:96 L8/8000
a=rtpmap:97 L16/8000
a=rtpmap:98 L16/110250/2
```

> 对于 Audio, `<encoding parameters>` 表示音频通道数量. 此参数是可选的, 如果通道数是1, 则可以省略.
>
> 对于 Video, `<encoding parameters>` 没有任何含义.
>
> 如果要定义其他编解码参数, 应该在其他属性中添加特定于编解码器的参数(例如, "a=fmtp:").

例子:

```
m=video 9 UDP/TLS/RTP/SAVPF 96 97
a=mid:video

a=rtpmap:96 VP8/90000
a=rtcp-fb:96 goog-remb
a=rtcp-fb:96 transport-cc
a=rtcp-fb:96 ccm fir
a=rtcp-fb:96 nack
a=rtcp-fb:96 nack pli

a=rtpmap:97 rtx/90000
a=fmtp:97 apt=96
```

> `a=mid` 属性可以认为是每个 m 描述的唯一ID. 比如, `a=mid:audio`, 那么 audio 这个字符串就是这个 M 描述的 ID. mid 值一般和

> `rtx` 表示重传, 比如 video 的 97, 就是 apt=96 的重传. 也就是说 97 这个编码格式, 就是在 96(VP8) 基础上增加了重传功能.


### ssrc

ssrc 指定一共要传的媒体流

```
m=video 9 UDP/TLS/RTP/SAVPF 96 97 127 121 125 107 108 109 124 120 123 119 35 36 41 42 98 99 100 101 114 115 116 117 118
a=msid:- 6aae5e17-ac06-47bf-a8bc-3d41fdb2bf29
a=ssrc-group:FID 3498052271 607464475
a=ssrc:3498052271 cname:eWwZORcr3NHhFcN8
a=ssrc:3498052271 msid:- 6aae5e17-ac06-47bf-a8bc-3d41fdb2bf29
a=ssrc:607464475 cname:eWwZORcr3NHhFcN8
a=ssrc:607464475 msid:- 6aae5e17-ac06-47bf-a8bc-3d41fdb2bf29
```

ssrc 包含了需要发送的媒体流. 另外 Offer 和 Answer 中都可以包含 SSRC. `a=msid` 对应了 net steamid, 代表了不同的媒体源.


PlanB 和 UnifiedPlan ?


### candidate

> https://www.rfc-editor.org/rfc/rfc5245.html

candidate 就是传输的候选人, 客户端会生成多个 candidate, 比如有 host, relay, srflx, prflx 类型等

```
a=candidate:2152552911 1 udp 2130706431 172.16.5.4 54097 typ host
a=candidate:2152552911 2 udp 2130706431 172.16.5.4 54097 typ host
a=candidate:233762139  1 udp 2130706431 172.17.0.1 42438 typ host
a=candidate:233762139  2 udp 2130706431 172.17.0.1 42438 typ host
a=candidate:4061774375 1 udp 1694498815 104.215.199.207 1027 typ srflx raddr 0.0.0.0 rport 35046
a=candidate:4061774375 2 udp 1694498815 104.215.199.207 1027 typ srflx raddr 0.0.0.0 rport 35046
a=end-of-candidates
```


格式:

```
a=candidate:<foundation> <component-id> <transport> <priority> <connection-address> <port> typ <cand-type> [raddr <rel-addr>] [rport <rel-port>]
```

- `<connection-address>`, 候选的 IP 地址, 可以是 IPv4, FQDN

- `<port>` 候选端口

- `<transport>` 一般是 UDP. 也可以是 TCP, DCCP

- `<foundation>`, 1到32个 <ice-char> 组成. 它是一个标识符, 相当于两个具有相同类型, 共享相同

- `<component-id>`, 1到256的正整数, 用于标示 media stream 的特定组件. 它必须从1开始, 连续递增. 实际上, media 的 RTP 的 `<component-id>`
必须是 1, RTCP 的 `<component-id>` 必须是2

- `<priority>`, 介于1和(2^31-1) 之间的正整数.

- `<cand type>`, 候选类型. 定义的值有 "host", "srflx", "prflx", "relay"

- `<rel-addr>`, `<rel-port>`, 传输与 candidate 相关的传输地址, 它必须存在于 "srflx", "prflx" 和 "relay" 类型当中. 如果是一个 "srflx"
或 "prflx" 的 candidate, 则 `<rel-addr>` 和 `<rel-port>` 等于该 server 和 peer 的 candidate. 如果是一个 "relay" 的 candidate,
则 `<rel-addr>` 和 `<rel-port>` 等于分配给客户端响应


## 编码确定?

如何确定最后的编码? 对方在 Answer 中给出, 如果在 Offer 中给出了多个编码. 在 Answer 中会选择一个, 如果 Answer 给了多个, 会选择第一个.





