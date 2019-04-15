# 负载均衡

## HTTP Balance

- Round Robin(轮训)

```
upstream backend {
    server backend1.example.com;
    server backend2.example.com;
}
```

- Least Connections(最少连接)

```
upstream backend {
    least_conn;
    server backend1.example.com;
    server backend2.example.com;
}
```

- IP Hash

```
upstream backend {
    ip_hash;
    server backend1.example.com;
    server backend2.example.com;
}
```

- Hash

```
upstream backend {
    hash $request_uri consisent; # 使用请求uri hash
    server backend1.example.com;
    server backend2.example.com;
}
```

- Random

```
upstream backend {
    random two last_time=last_byte;
    hash $request_uri consisent; # 使用请求uri hash
    server backend1.example.com;
    server backend2.example.com;
}
```

**random指令**:

random模式 提供了一个参数 `two`, 当这个参数被指定时, nginx会先随机地选择两个服务器(考虑**weight**),
然后用以下几种方法选择其中的一个服务器:

```
least_conn: 最少连接
least_time=header: 接收到 response header的最短平均时间($upstream_header_time, nginx plus版本)
least_time=last_byte: 接收到完整response的最短平均时间($upstream_response_time, nginx plus版本)
```
