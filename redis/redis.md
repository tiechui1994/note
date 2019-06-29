## PUB/SUB

- SUBSCRIBE channel [channel ...]

```
订阅给指定频道的消息. 一旦客户端进入订阅状态, 客户端就可以接受订阅相关命令SUBSCRIBE,
PSUBSCRIBE, UNSUBSCRIBE, PUNSUBSCRIBE, 除了这些命令, 其他命令一律时效
```

- PSUBSCRIBE pattern [pattern ...]

```
订阅给定的模式(patterns)
例如: h?llo -> hello, hxllo
     h*llo -> hello, hyyyyllo
     h[ae]llo -> 只能是 hello 或者 hallo
```

- UNSUBSCRIBE [channel [channel ...]]

```
取消订阅来自给定频道的客户端, 或者如果没有给出, 则从所有频道取消订阅.
如果未指定频道, 则取消订阅所有先前订阅的频道. 在这种情况下, 每个未订阅频道的消息将被发送
到客户端.
```

- PUNSUBSCRIBE [pattern [pattern ...]]

```
从给定模式取消订阅客户端, 或者如果没有给出, 则取消订阅所有模式.
如果未指定模式, 则客户端将取消订阅所有先前订阅的模式. 在这种情况下, 每个未订阅模式
的消息将被发送到客户端.
```

- PUBLISH channel message

```
将信息message发送到指定的频道channel
```


- PUBSUB subcommand [arg [arg ...]]

```
PUBSUB CHANNELS [pattern]
列出当前active channel. active channel是具有一个或多个订户的Pub/Sub信道
(不包括订阅模式的客户端). 如果未指定模式, 则列出所有通道, 否则如果指定了pattern,
则仅列出与指定的glob样式模式匹配的通道.

PUBSUB NUMSUB [channel-1 ... channel-N]
返回指定channel的订阅数量(不包括订阅模式的客户端)

PUBSUB NUMPAT
返回模式的预订数(使用PSUBSCRIBE命令执行). 请注意,这不仅仅是订阅模式的客户端数量,
而是所有客户端订阅的模式总数.
```