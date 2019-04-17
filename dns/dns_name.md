# DNS 主配置文件

DNS, 域名解析服务, 目前主要使用的是Bind. 下面的对域名解析服务Bind的主配置文件 **named.conf** 的解析.

**name.conf的配置语句:**

- acl: 定义访问控制列表, 参考 acl

- options: 定义全局配置选项.

- logging: 定义日志的记录规范, 参考 *BIND9* 的高级配置的 "BIND 日志部分"

- controls: 定义 **rndc** 命令使用的控制通道, *若省略此句, 则只允许经过 rndc.key 认证的 
127.0.0.1 的 rndc 控制*, 参考 rndc


- key: 定义用于 *TSIG* 的授权密钥

- lwres: 将 **named** 同时配置成一个轻量级的解析器.

- trusted-keys: 为服务器定义 `DNSSEC` 加密密钥.

- server: 设置每个服务器的特有的选项.

- view: 定义域名空间的一个视图, 参考 *BIND 9* 的高级配置的 "View 语句部分"

- include: 将其他文件包含到本配置文件当中.

- zone: 定义一个区

> Ubuntu 将 options 语句分离放置于 /etc/bind/named.conf.options 文件中.
Ubuntu 将本机解析的权威区的声明语句 zone 放置于 /etc/bind/named.conf.local 文件中.


## 常用的options配置

- directory: 服务器的工作目录. **配置文件中的任何非绝对路径名都将被视为相对于此目录**. 大多数服务器
输出文件(例如named.run)的默认位置是此目录. 如果未指定目录,则工作目录默认为".", 即启动服务器的目录. 指
定的目录应该是绝对路径, 并且必须可以由指定进程的有效用户ID写入.

- key-directory: 执行安全区域的动态更新时, 需要找到公有和私有DNSSEC密钥文件的目录(当前选项配置的目录).
>注意, 此选项对包含非DNSSEC密钥的文件的路径没有影响, 例如bind.keys, rndc.key或session.key.

- managed-keys-directory: 指定用于存储跟踪托管DNSSEC密钥的文件的目录. 默认情况下, 和工作目录一致.该
目录必须可由指定进程的有效用户标识写入.

如果named未配置为使用view, 则将使用名为 `managed-keys.bind` 的文件作为跟踪服务器的托管密钥的文件. 
否则, 将在单独的文件中跟踪托管密钥, 每个视图一个文件, 文件名是视图名称 (或者, 如果它包含与用作文件名不
兼容的字符, 视图名称的SHA256哈希值作为文件名), 后跟扩展名.mkeys.

> 注意: 在以前的版本中, 视图的文件名始终使用视图名称的SHA256哈希. 为了确保升级后的兼容性, 如果发现使用旧名
称格式的文件存在, 将使用它而不是新格式.

- dump-file: 当使用 `rndc dumpdb` 做备份时, 服务器将数据库转储到的文件的路径名. 如果未指定, 则默认为
named_dump.db.

- memstatistics-file: 服务器在退出时将内存使用情况统计信息写入的文件的路径名.如果未指定,默认是named.memstats.

- pid-file: 服务器写入其进程ID的文件的路径名. 如果未指定, 默认是/var/run/named/named.pid. PID文件由
想要将信号发送到正在运行的名称服务器的程序使用. **指定pid-file none将禁用PID文件的使用**  - 不会写入任何
文件，并且将删除任何现有文件. 
> 注意, none不是关键字, 不是文件名, 因此不包含在双引号中.

- statistics-file: 服务器在执行 `rndc stats` 命令时, 会在该文件中添加一条统计信息. 如果未指定, 则缺省值
为服务器当前目录中的named.stats. 

- bindkeys-file: 用于覆盖 `named` 提供的内置的可信密钥的文件的路径名. 如果未指定, 则默认为/etc/bind.keys.

- port: 服务器用于接收和发送DNS协议流量的UDP/TCP端口号. 默认值为53. 此选项主要用于服务器测试; 使用53以外的端
口的服务器将无法与全局DNS通信.

**布尔选项**
布尔选项的值是yes或者no.

- allow-new-zones: 如果是yes, 则可以在运行时通过 `rndc addzone` 添加zone. 默认值为no.

- auth-nxdomain: 如果是yes, 那么 AA 位将一直设置成 NXDOMAIN 响应, 甚至在服务器不是授权服务器的情况下
都是这样的. 默认值是 no; 这与BIND8不同. 如果用户使用的是非常老版本的DNS软件, 则有必要把它设置成yes.

- recursion: 如果是yes, 允许递归查询. 默认是no

- auto-dnssec: 为动态DNS配置的区域可以使用此选项来允许不同级别的自动DNSSEC密钥管理.有三种可能的设置:
    auto-dnssec allow; 允许更新密钥, 并在用户发出命令`rndc sign zonename` 时完全重新签名区域.
    
    auto-dnssec maintain; 包括 **auto-dnssec allow** 的操作, 但还根据密钥的计时元数据按计划自动调
    整区域的DNSSEC密钥. `rndc sign zonename` 命令导致named从密钥存储库加载密钥, 并使用所有活动密钥对
    区域进行签名. `rndc loadkeys zonename` 命令导致named从密钥存储库加载密钥并计划将来发生的密钥维护
    事件,但它不会立即签署完整区域。
    注意: 一旦第一次为区域加载了密钥, 无论是否使用`rndc loadkeys`, 都会定期搜索存储库的更改. 重新检查间隔
    由dnssec-loadkeys-interval定义.
    
    auto-dnssec off; 默认设置.

- dnssec-enable 


**转发选项**
转发功能可以用来在一些服务器上产生一个大的缓存, 从而减少到外部服务器链路上的流量. 它可以使用在和`internet`没有
直接连接的内部域名服务器上, 用来提供对外部域名的查询, 只有当服务器是非授权的, 并且缓存中没有相关记录时, 才会进行
转发.

- forward: 此选项只有当 `forwarders` 列表中有内容的时候才有意义. 当值是`first`, 默认情况下, 使服务器先查
询设置的`forwarders`, 如果它没有得到回答, 服务器就会自己寻找答案. 如果设定的是`only`, 服务器就只会把请求转发
到其它服务器上去.

- forwarders: 设定转发使用的`ip`地址. 默认的列表是空的(不转发). 转发也可以设置在每个域上, 这样全局选项中的转
发设置就不会起作用了. 用户可以将不同的域转发到服务器上, 或者者对不同的域可以实现`forward only`或`first` 的不同
方式, 也可以根本就不转发.


**访问控制**
可以根据用户请求使用的**IP地址**进行限制.

- allow-query

- allow-recursion

- allow-transfer: 设定哪台主机允许和本地服务器进行域传输.


**端口**
端口(服务器应答来自于此端口的请求) 可以使用 `listen-on` 选项来设定. `listen-on` 使用可选的端口和一个
地址匹配表列(address_match_list). 服务器将会监听所有匹配地址表列中所允许的端口. 如果没有设定端口, 就将
使用端口 `53`.

- listen-on

```
listen-on [port N] { IP|any|none;};
```

案例:
```
listen-on { 1.2.3.4; };
listen-on port 5353 { !1.2.3.4; 1.2/16; };
listen-on port 53 { any; };
```

- listen-on-v6


**查询地址**
如果服务器查不到要解析的地址, 它将会查询其它域名服务器. `query-source` 可以用来设定这类请求所使用的地址
和端口. 对于使用 `ipv6` 发送的查询, 有一个独立的 `query-source-v6` 选项. 如果 `address` 是 `*` 
或者被省略了, 则将会使用一个通配的 `IP 地址` (INADDR ANY)。如果`port`是`*` 或者被省略了, 则将会使用一
个随机的大于1024的端口.

>默认配置如下:
```
query-source address * port * ;
query-source-v6 address * port * ;
```

> query-source选项中设置的地址是同时使用UPD和TCP两种请求的, 但是port仅仅用于UDP请求.

- query-source


**服务器资源限制**
- recursive-clients: 服务起同时为用户执行的递归查询的最大数量. `默认值1000`, 因为每个递归用户使用
许多位内存, 一般为20KB, 主机上的 `recursive-clients` 选项值必须根据实际内存大小调整。

- tcp-clients: 服务器同时接受的 `TCP` 连接的最大数量, 默认值 100.

- max-cache-size: 服务器缓冲使用的最大内存量, 用bit表示. 但在缓存数据的量达到这个界限, 服务器将会使记
录提早过期这样限制就不会被突破. 在多视图的服务器中, 限制分别使用于每个视图的缓存. 默认值没有限制, 意味着只
有当总的限制被突破的时候记录才会被缓存清除.

