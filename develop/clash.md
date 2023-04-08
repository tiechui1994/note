# Clash 配置解读

## Proxy 配置

### ss 类型

- server, 代理节点的 IP 地址

- port, SS 服务器监听的端口

- password, SS 服务器设置的连接密码

- udp, 是否启用UDP

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
