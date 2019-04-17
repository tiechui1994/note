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


## 常用的zone配置

```
zone string [ CLASS ] {
    type master | slave | hint | stub | forward ;
    ...
};
```

**TYPE的类型如下:**

```
master: 服务器有一个主域(控制域或主域)的配置文件拷贝, 能够为之提供授权解析服务.
```

```
slave: 辅域(也可以叫次级域)是主域的复制. 主域名服务器定义了一个辅域或多个辅域IP地址.  

默认下, 传输是从服务器上的53端口进行的; 对所有的服务器来说这是可变的, 通过设定一个 `在IP地址表前` 或者 `在IP
地址之后` 基于每个服务器设定端口数字.

对主域名服务器的鉴别也能通过每个服务器上的 `TSIG键` 来完成. 如果文件被指定了, 那么任何主域配置信息改变的时候
就要复制文件, 并且当辅服务器重新启动的时候都会从主域名服务器上重新下载文件. 这可能会导致带宽的浪费和服务器重新启
动次数的增加.

注意: 对每个服务器的数量众多的域来说(数万或者数十万), 最好使用两级方式命名配置.
例如: 一个域的服务器 example.com 可能把域内容放到一个叫做 ex/example.com 的文件中, 在此, ex/只是域名前
两个字符(如果把100K的文件放入一个单独的目录中, 大多数操作系统都会反应缓慢)
```

```
stub: 子根域与辅域类似, 只复制主域的NS记录而不是整个域. 根域不是 DNS 的一个标准部分, 它们是BIND运行的特有
性质. 

根域可以用来避免在本机重新获得该域的NS记录, 代价是保存一个根域入口和一组"named.conf"名称服务器地址. 这个用法
在新设置中并不建议使用, BIND9只在有限的情况下才支持它. 在BIND4/8中当前的域传输包括来自当前域的子根的NS记录.

这表明, 在某些情况下, 用户可以为当前域设置只存在于控制服务器里的子根. BIND9服务器从不以这种方式把来自不同域的
数据混合. 这样的话, 如果一个BIND9控制服务器服务于一个已经设定了子根域的母域, 所有的当前域的次级服务器都需要设
定相同的子根域. 子根域也可以用来作为一种促使一个特定域的解答使用一个授权服务器的特定系. 例如, 在一个使用RFC2157
地址的私用网络上缓存名服务器可以用子根域进行设置.
```

```
forward: 一个 "转发域" 是一种在每个域基础上进行配置转发的一种方式. forward类型的域语句包括一个转发语句和转发
列表, 都应用于在域内的由域名给出的查询. 如果当前没有转发器语句, 就会给出空列表, 在域中就不会转发, 也就取消了所有
在选项中的转发的作用. 

如果你要使用此种域来改变整体转发选项的性态("forward first", "forward only" 但是要用同一服务器作为是全局设
置) 你需要理解全局转发器的特点.
```

```
hint: 根名称服务器的在最初设置时指定使用一个"hint zone". 当配置了"hint zone"的服务器启动的时候, 它使用根线
索的设置找到根的名称服务器并得到根名称服务器的最新表. 如果没有为IN类设定线索域, 服务器使用一个 compiled-in 的
默认根服务器列表.
```

**CLASS类**
域名后面的选项可以对应类. 如果没有指定类, 系统假定为`IN`类. 这在大多数的情况下都是正确的.


```
RR ( Resouce Recods, 资源记录)

MX (Mail eXchanger, 邮件交换器)
CNAME (Canonical NAME 别名)


DNS域名数据库有资源记录和区文件指令组成.
由SOA(Start Of Authority)起始授权机构记录, SOA记录说明了在众多NS记录里那一台才是主名称服务器. 

正向解析文件包括 A internet Address, FQDN --> IP
反向解析文件包括PTR(PTR: PoinTeR, IP --> FQDN)


RR 语法: name　　[TTL]　　IN　　type　　value (字段之间由空格和制表符隔开)

(1) TTL可从全局继承　　
(2) @可用于引用当前区域的名字 　　
(3) 同一个名字可以通过多条记录定义多个不同的值; 此时 DNS服务器会以轮询方式响应 　　
(4) 同一个值也可能有多个不同的定义名字; 通过多个不同的名字指向同一个值进行定义; 此仅表示通过多个不同的名字可以找到同一个主机

SOA记录: name: 当前区域的名字, 例如"heiye.com." 　　
        value: 有多部分组成; 
            1) 当前区域的主DNS服务器的FQDN, 也可以使用当前区域的名字;
            2) 当前区域管理员的邮箱地址: 地址中不能使用@符号, 一般用.替换 如linuxedu.heiye.com
            3) 主从服务区域传输相关定义以及否定的答案的统一的TTL 

例如: heiye.com.　　86400 　　IN 　　SOA 　　ns.heiye.com.

　　　 nsadmin.heiye.com. 　　(
　　　 　　　　2015042201 ;
　　　　　　　 序列号 2H ;
　　　　　　　 刷新时间 10M ;
　　　　　　　 重试时间 1W ;
　　　　　　　 过期时间 1D ;
　　　　　　　 否定答案的TTL值
　　　)

NS记录:  name: 当前区域的名字 　　
        value: 当前区域的某DNS服务器的名字, 例如 ns.heiye.com. 注意: 一个区域可以有多个NS记录

例如: heiye.com. 　　IN 　　NS　　  ns1.heiye.com.  
　　  heiye.com. 　　IN 　　NS 　   ns2.heiye.com.

注意: 1) 相邻的两个资源记录的name相同时, 后续的可省略 
     2) 对NS记录而言, 任何一个ns记录后面的服务器名字, 都应该在后续有一个A记录

MX记录:   name: 当前区域的名字 　　
         value: 当前区域的某邮件服务器(smtp服务器)的主机名, 一个区域内, MX记录可有多个但每个记录的value之前应
         该有一个数字(0-99), 表示此服务器的优先级; 数字越小优先级越高. 例如:
         
heiye.com. 　　IN 　　MX 　　10 　　mx1.heiye.com.
       　　　　 IN 　　MX 　　20 　　mx2.heiye.com.

注意: 对MX记录而言, 任何一个MX记录后面的服务器名字, 都应该在后续有一个A记录


A记录:    name: 某主机的FQDN, 例如www.heiye.com. 　　
         value: 主机名对应主机的IP地址

例如:
www.heiye.com. 　　IN 　　A 　　1.1.1.1 　　
www.heiye.com.　　 IN 　　A 　　2.2.2.2 　　
mx1.heiye.com. 　　IN 　　A 　　3.3.3.3
mx2.heiye.com.    IN 　　A 　　4.4.4.4
*.heiye.com. 　　　 IN 　　A 　　5.5.5.5
heiye.com. 　　　　 IN 　　A 　　 6.6.6.6 　　

避免用户写错名称时给错误答案, 可通过泛域名解析进行解析至某特定地址.

AAAA记录: name: FQDN 　　value: IPv6 　　
　　
PTR记录:  name: IP, 有特定格式, 把IP地址反过来写, 1.2.3.4要写 作4.3.2.1; 而有特定后缀: in-addr.arpa.,
         所以完整写法为: 4.3.2.1.in-addr.arpa. 　　
         value: FQDN
         
例如:
4.3.2.1.in-addr.arpa. 　　IN 　　PTR 　　www.heiye.com.

如1.2.3为网络地址, 可简写成: 
4 　　IN 　　PTR 　　www.heiye.com.

注意: 网络地址及后缀可省略; 主机地址依然需要反着写.

CNAME记录:    name: 别名的FQDN 　　
             value: 真正名字的FQDN

例如: 
www.heiye.com. 　　IN 　　CNAME 　　websrv.heiye.com.

named字段:
	(1)根域以"."结束, 并且只有一个, 没有上级域. 而在Internet中, 根域一般不需要表现出来.
	(2)@: 默认域, 文件使用$ORIGIN domain 来说明默认域.
	(3)ttl全称"Time to Live", 以秒为单位记录该资源记录中存放高速缓存中的时间长度, 通常此处设为空, 表示采用
	SOA的最小ttl值.
	(4)IN: 将该记录标志为一个Internet DNS资源记录.

type字段:
	(1)A记录: 主机名对应的IP地址记录, 用户可将该域名下网站服务器指向自己的Web服务器, 同时也可设置域名的二级域名.
	(2)MX记录: 邮件交换记录可将该域下所有邮件服务器指向自己的邮件服务器, 只需在线填写服务器的IP地址.
	(3)CNAME记录: 别名记录,可允许多个名字映射到同一计算机，通常用于同时提供Web和邮件服务器的计算机.
	(4)SOA记录: 一个授权区的开始,配置文件的第一个记录必须是SOA的开始.
	(5)PTR记录: 用于地址到主机名的映射.
	(6)HINFO记录: 由一组描述主机的信息文件组成,通常包括硬件名称和操作系统名称.

value字段:
	(1)A : 存放IP地址.
	(2)CNAME: 设置主机别名.
	(3)HINFO: 通常为两行, 分别对应Hareware(计算机硬件名称)和OS-type(操作系统名称).
	(4)NS: 域名服务器的名称.
	(5)PTR: 主机真实名称.

测试检查配置文件错误的工具: nslookup、dig、named-checkzone、host、named-checkconf及dlint。
```
