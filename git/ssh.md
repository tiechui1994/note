## ssh 配置

ssh, 远程连接工具, 包括服务端(openssh-server, sshd) 和 客户端(openssh-client, ssh) 两部分. 默认状况下, 其全局
配置文件位于 `/etc/ssh` 目录下, 分别是 sshd_config(sshd) 和 ssh_config(ssh).

对于不同的用户, 可以在 `~/.ssh/config` 下可以自定义 ssh 配置文件.

- ssh 配置

```
Host host
    HostName host
    IdentityFile file
    UserKnownHostsFile file
    Port port
    Compression yes|no
    CompressionLevel 1-9
    LogLevel QUIET|FATAL|ERROR|INFO|VERBOSE|DEBUG
    LocalForward forword
    RemoteForward forword
    DynamicForward forword
    PermitLocalCommand yes|no
    LocalCommand command
    ProxyCommand command 
    ServerAliveInterval interval
    ServerAliveCountMax count
    ControlMaster auto | autoask | yes | ask | no
    ControlPath ~/.ssh/master-%r@%h:%p
    ControlPersist  0 | yes | no 
```

`Host host`: 主机匹配, 其中 host 可以使用正则表达式.

`HostName host`: 指定要登录的真实主机名. 这可用于指定主机的昵称或缩写. 默认值是命令行上给出的名称. 也可以使用 IP 地址.

`IdentityFile file`: 指定登录认证的私钥文件.

`UserKnownHostsFile file`: 指定用户的 known_hosts 文件.

`Port port`: 指定 ssh 远程登录的端口, 默认值是 22

`Compression`: 是否进行压缩.

`CompressionLevel`: 当 `Compression` 是 `yes` 时有效, 指定压缩级别.

`LogLevel`: 日志级别.

---

`LocalForward`: 将发送到本地端口(`[local:]port`)的请求通过 `HostName` 转发到目标端口(`host:port`). 第一个参是 
`[local:]port`, 表示本地"监听"的端口号; 第二个参数是 `host:port`, 表示远程局域网监听的端口号.

`RemoteForward`: 将发送到远程端口(`[local:]port`)的请求通过 `HostName` 转发到目标端口(`host:port`). 第一个参数
是 `[local:]port`, 表示远程"监听"的端口号; 第二个参数是 `host:port`, 表示本地局域网监听的端口号.

举个例子: A是本地主机, B是远程主机, 现在通过主机A连接到主机B

```
ssh -L 8080:127.0.0.1:80 root@B

ssh -R 53:127.0.0.1:5353 root@B
```

对于情况1, 访问本地 http://127.0.0.1:8080 的请求会直接转发到远程主机 B 的 80 端口

对于情况2, 访问远程主机 B http://1.1.1.1:53(假设B主机的IP为1.1.1.1) 的请求会直接转发到本地主机 A 的 5353 端口

> LocalForward vs RemoteForward 
> 相同: 先建立一个 ssh 连接, 然后将发送到远程或本地的数据通过连接进行转发.
> 区别: LocalForward 数据是先发送到本地, 然后转发到 HostName 的局域网的主机.
>      RemoteForward 数据是先发送到远程, 然后通过 HostName 转发到本地局域网的主机.

`DynamicForward`: 将发送到本地端口(`[local:]port`)的请求通过 `HostName` 转发到目标端口. 目标端口是由发起请求决定
的.

---

`PermitLocalCommand`: 是否允许指定 `LocalCommand`, 默认值是 no

`LocalCommand`: 指定在连接成功后, 本地主机执行的命令(单纯的本地命令). 只有在 `PermitLocalCommand` 开启的情况下有效.

`ProxyCommand`: 指定连接的服务器需要执行的命令. 可以使用 `%h`, `%p`, `%r`.

```
Host test
    ProxyCommand nc -X 5 -x 127.0.0.1:1086 %h %p
```

> nc: ncat, 一个网络连接工具. `-X` 指定代理协议, 三个值 **4(SOCKS v4), 5(SOCKS v5), connect(HTTPS)**. `-x`, 指
定代理的主机地址和端口. `%h %p`, 变量, 替换 ssh 真正要连接的服务器的主机名(host) 和端口(port)


```
Host test
    ProxyCommand ssh jump@10.10.2.100 -W %h:%p
```

> `-W host:port` 请求将客户端上的标准输入/输出通过安全通道转发到 `host:port`


---

`ServerAliveInterval` 指定向服务器发送 keepalive 消息的时间间隔. 消息通过加密通道发送, 用于检测服务器是否崩溃或网
络是否出现故障. (seconds)

`ServerAliveCountMax` 设置客户端可以发送 keepalive 消息的数量, 而客户端不会从服务器接收任何消息. 当达到此阈值时, 客户
端将终止会话.

---

`ControlMaster`, 允许通过单个网络连接共享多个会话. 当设置为 yes 时, ssh 连接将共享使用 `ControlPath` 参数指定的套接字连接. 当中设置为 
no 时候, 则每次都会使用 `ControlPath` 参数指定的套接字去建立新的连接. 设置为 ask, 表示每次都会询问. 当设置为 auto, autoask 时, 允许多
路复用. **共享连接时, 只需要在第一次输入密码, 后续连接可以共享时则不需要再输入密码.**

`ControlPath`, 指定用于共享连接的控制套接字路径. `%h` 表示目标主机, `%p`, 表示目标端口号, `%r` 表示目标用户。

`ControlPersist`, 当与 ControlMaster 一起使用时, 指定 Master 连接在初始客户端连接关闭后在后台保持打开状态(等待将来的客户端连接). 如果
设置为 no, 则 Master 连接将不会置于后台, 并在初始客户端连接关闭后立即关闭. 如果设置为 yes 或 0, 则 Master 连接将无限期地保留在后台(直到
通过诸如 `ssh -O exit` 之类的机制被杀死或关闭). 设置的数值是以秒为单位的时间. 支持时间格式配置, 例如 `2h, 1d 等`

## 与 ssh 相关命令

- ssh-keygen, 生成秘钥

常用参数:

`-t rsa|dsa|ed25519|ecdsa`, 秘钥算法

`-b size`, 秘钥位数.

`-C comment`, comment信息

`-f file`, 设置输出文件名称

- ssh-add, ssh-agent


- ssh-copy-id, 远程拷贝公钥文件

`-i identity_file`, 公钥文件

`-f` 强制模式
