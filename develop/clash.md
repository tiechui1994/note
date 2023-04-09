# Clash 配置解读

## Proxy 配置

### ss 类型

- server, 服务器 IP 地址

- port, 服务器监听的端口

- password, 服务器设置的连接密码

- udp, 是否启用UDP

- plugin: v2ray-plugin, obfs

- plugin-opts: plugin 配置参数, map

```
v2ray-plugin:
- mode: websocket | quic
- tls, 是否启用 tls
- host, 伪装域名
- path, 路径
- mux, websocket 模式下是否启用多路复用
- headers, 请求 header

obfs:
- mode: tls
- host, 伪装域名
```


### vmess 类型

- server, 服务器 IP 地址

- port, 服务器监听端口

- uuid, 服务器配置的 UUID

- udp, 是否启用UDP

- network, 使用哪种方式连接服务器. 例如: ws, http, h2

- tls, 当 network 是 ws, http, h2 时, 是否开启 TLS 认证.

- ws-opts, ws 方式的参数, 包含 headers(map), path 等.

- http-opts, http 方式的参数, 包含 headers(map), method, path(array).

- h2-opts, h2 方式的参数, 包含 host(array), path.

- servername, 如果设置, 可以覆盖 ws-opts, http-opts 中 headers 的 Host 参数

### trojan 类型

- server, 服务器 IP 地址

- port, 服务器监听端口

- password, 服务器设置的连接密码
