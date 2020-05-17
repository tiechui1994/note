## DNS 解析命令

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
;baidu.com.			IN	A

# 响应部分, 回应的都是A记录, 含义如下
# 1. 对应的域名
# 2. TTL, 缓存时间, 单位是秒
# 3. class, 查询信息的类别
# 4. type, 查询的记录记录类型
# 5. 域名对应的ip地址
;; ANSWER SECTION:
baidu.com.		0	IN	A	220.181.38.148
baidu.com.		0	IN	A	39.156.69.79

# 查询耗时
;; Query time: 86 msec

# 查询使用的DNS服务器地址和端口号
;; SERVER: 103.85.85.222#53(103.85.85.222)

# 查询时间
;; WHEN: Sun May 17 22:15:20 CST 2020

# 响应大小, 单位是字节
;; MSG SIZE  rcvd: 70
```

### nslookup
