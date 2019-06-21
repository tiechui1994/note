## access_log

格式:

```
access_log path [format [buffer=size] [gzip=[level]]  [flush=time] [if=condition]];
access_log off;
```

可以使用access_log的位置: http, server, location, if in location, limit_except

默认配置: access_log logs/access.log combined;

如果使用buffer 或 gzip (1.3.10, 1.2.7)参数, 则将缓冲写入日志.

当启用缓冲后, 数据将写入文件的时机:
- 如果下一条日志超出缓冲区大小;
- 如果缓冲的数据在超过flush参数指定的值时间范围内没有写入;
- 当worker进程重新打开日志文件或正在关闭时.


案例:

```
access_log /path/to/log.gz combined gzip flush=5m;
```


## log_format

格式:

```
log_format name [escape=default|json|none] string...;
```

使用的位置: http

默认配置: log_format combined "...";

escape参数(1.11.8)允许设置在变量中转义的json或default字符, 默认情况下, 使用default. none(1.13.10)禁用转义.

常用的string:

- $connection, 连接序列号
- $msec, 以秒为单位的时间, 日志写入时的分辨率为毫秒
- $request_time, 请求处理时间(以秒为单位); 从客户端读取第一个字节之间经过的时间,并将最后一个字节发送到客户端后的日志写入
- $status, 响应状态码
- $time_local, 本地时间


## error_log

格式:

```
error_log file [level];
```

可以使用error_log的位置: http, mail, stream, server, location

默认配置: error_log logs/error.log error;

level, 日志级别, debug, info, notice, warn, error, crit, alert, emerg. 默认的级别是error.