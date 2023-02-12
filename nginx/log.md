## nginx 日志

### access_log

nginx 请求访问日志.

格式:

```
access_log path [format [buffer=size] [gzip=[level]]  [flush=time] [if=condition]];
access_log off;
```

> 位置: http, server, location, if in location, limit_except

默认配置: `access_log logs/access.log combined;`

如果使用 buffer 或 gzip (1.3.10, 1.2.7) 参数, 则将缓冲写入日志.

当启用缓冲后, 数据将写入文件的时机:
- 如果下一条日志超出缓冲区大小;
- 如果缓冲的数据在超过flush参数指定的值时间范围内没有写入;
- 当worker进程重新打开日志文件或正在关闭时.

注: access_log 的默认格式是 `combined`.


案例:

```
# 自定义格式
log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                '$status $body_bytes_sent "$http_referer" '
                '"$http_user_agent" "$http_x_forwarded_for"';
access_log /logs/access.log main;


# 使用nginx自带的格式
access_log /path/to/log.gz combined gzip flush=5m;
```

> 注: 如果要想实现 flush 属性, 一定要先带上 buffer 属性.


### log_format

格式:

```
log_format name [escape=default|json|none] string...;
```

> 位置: http

默认配置: `log_format combined "..."`;

escape参数(1.11.8)允许设置在变量中转义的json或default字符, 默认情况下, 使用 `default`. none(1.13.10)禁用转义.

常用的string:

- $connection, 连接序列号
- $msec, 以秒为单位的时间, 日志写入时的分辨率为毫秒
- $request_time, 请求处理时间(以秒为单位); 从客户端读取第一个字节之间经过的时间,并将最后一个字节发送到客户端后的日志写入
- $status, 响应状态码
- $time_local, 本地时间

```
log_format main '$remote_addr - $remote_user [$time_local] '
                '"$request" $status $body_bytes_sent "$http_user_agent"';
```


### error_log

nginx 的错误日志(包括nginx启动, 停止, 运行过程中产生的错误日志等)

格式:

```
error_log file [level];
```

> 位置: http, mail, stream, server, location

默认配置: `error_log logs/error.log error`;

level, 日志级别, `debug, info, notice, warn, error, crit, alert, emerg`. 默认的级别是 `error`.


### 应用

[文档](https://www.docs4dev.com/docs/zh/nginx/current/reference/syslog.html)

- nginx日志重定向

将日志重定向到本地 syslog 当中:

```
error_log syslog:server=unix:/dev/log info;
access_log syslog:server=unix:/dev/log main;
```

`syslog:server=unix:/dev/log` 替换的是 `error_log` 和 `access_log` 当中的 `path`. 


将日志重定向到其他的服务器:

```
access_log syslog:server=[172.16.0.10]:12345,facility=daemon,tag=nginx main;
```

> syslog 配置讲解
> server=addres, 定义系统日志服务器的地址. 该地址可以是域名或IP递增(可带端口号), 也可以为在 "unix:" 前缀之后指定的
> UNIX 套接字路径. 如果未指定端口, 则使用UDP端口514. 注: 这里使用的服务需要是UDP端口.
>
> facility=string, 设置系统日志消息的功能. 可以是 "kern", "user", "mail", "daemon", "auth" 等
>
> severity=string, 设置系统日志的级别. 默认值是 "info"
>
> tag=string, 设置系统日志的标签. 默认值是 "nginx"
>
> nohostname, 禁止将 "主机名" 字段添加带日志系统消息头.


- 利用 nginx 的 access_log 进行流量统计.

