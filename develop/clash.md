# Clash 背后的协议

clash 配置主要包含 3 部分:

1) 基础配置, 包括 clash 的监听的端口(HTTP, SOCKS代理端口, UI管理端口), 网卡, DNS 等配置

2) proxies 与 proxy-groups, proxies 是所有代理节点配置的集合, proxy-groups 是针对代理节点划分成组, 不同的组有
不同通途(例如: 针对 YOUTUBE 视频与针对 NETFLIX 就会有不同的组)

3) rules: 代理匹配规则, 针对不同的网站, 走不同的 proxy-groups 去代理上网.

## Proxy 目前支持的类型及其设置

### ss 类型

- server, 服务器 IP 地址

- port, 服务器监听的端口

- password, 服务器设置的连接密码, 服务端与客户端对称加密的秘钥

- cipher, 对称加密算法, 常用的有 'chacha20-ietf-poly1305'

- udp, 是否启用UDP, 默认只使用 TCP 传输

- plugin: v2ray-plugin, obfs

- plugin-opts: plugin 配置参数的额外参数, 其对应与 ssserver 配置当中的 "plugin_opts"

```
// 使用 Go 实现, 目前比较主流.
v2ray-plugin:
- mode: websocket | quic
- tls, 是否启用 tls
- host, 伪装域名
- path, 路径
- mux, websocket 模式下是否启用多路复用
- headers, 请求 header

// 使用 C 实现, 目前已不推荐使用. 
obfs:
- mode: tls, http  // 对应 plugin_opts 当中的 obfs
- host, 伪装域名    // 对应 plugin_opts 当中的 obfs-host
```

### vmess 类型

- server, 服务器 IP 地址

- port, 服务器监听端口

- uuid, 服务器配置的 UUID

- alterId, 默认值是 0

- cipher, 协议头的加密方式, 支持的方式, "aes-128-gcm", chacha20-poly1305", "auto", "none"(不加密, 会数据校验),
 "zero"(不加密, 不进行校验), 如果使用了 TLS, 且数据不经过中转(CDN就需要中转), 建议使用 "none" 或 "zero"

- network, 使用哪种方式连接服务器. 例如: ws, http, h2, tcp(默认值)

- tls, 针对 network 是 ws, http, h2 时, 是否开启 TLS 认证. 开启了 tls 认证, 则需要证书 https 网站.

- ws-opts, ws 方式的参数, 包含 headers(map), path 等.

- http-opts, http 方式的参数, 包含 headers(map), method, path(array).

- h2-opts, h2 方式的参数, 包含 host(array), path.

> vmess 节点可使用 v2ray 搭建. 

## Proxy-Group 设置

- name, 组名称, 后续的 Rules 直接对接到组名称

- type, 组类型, 支持的有 fallback(备选方案), url-test(定期测速), select(直接被 rules 使用的组)

- url, 进行网速测试的网站. 一般是 http://www.gstatic.cn/generate_204

- proxies, 该 group 当中包含的节点数组(来自 proxies 节点, fallback, url-test 类型的组)

- interval, 测速的周期

- tolerance, 在 fallback, url-test 当中切换节点的容忍度

## Rules 配置规则

- 'DOMAIN', 完整域名匹配, 例如: 'DOMAIN,ifconfig.me,Netflix', 对于 ifconfig.me 网站请求, 使用 Netflix 组节点

- 'DOMAIN-SUFFIX', 域名后缀匹配, 例如: 'DOMAIN-SUFFIX,tmall.com,DIRECT', 天猫网站请求, 直接不走代理

- 'DOMAIN-KEYWORD', 域名关键字匹配, 例如: 'DOMAIN-KEYWORD,gmail,Proxy', 对于域名当中带有 gmail 词, 使用 Proxy 组节点

- 'DST-PORT', 目标端口号, 例如: 'DST-PORT,25,DIRECT', 对于目标端口号是 25, 直接不走代理

- 'IP-CIDR', 目标网站IP地址匹配, 例如: 'IP-CIDR,127.0.0.0/8,DIRECT,no-resolve', 本地的环路地址, 直接不走代理.
对于私有的IP地址段, 都是不用走代理. 通常在 rules 的开头

- 'GEOIP', IP 归属位置匹配, 例如: 'GEOIP,CN,DIRECT', 对于解析的IP地址属于中国的请求, 直接不走代理. 通常用于靠最后的规则.

- 'MATCH', MATCH 规则用于路由剩余的数据包. 该规则是必需的, 通常用作最后一条规则. 

# 节点搭建

## ss 节点(sserver + obfs/v2ray-plugin)

ss 协议是一个基于 TCP 的协议.

// ss + obfs, 最简单的 ss 节点
```
{
    "server":"0.0.0.0",
    "server_port": 9527,
    "password":"ssa7181291191171",
    "timeout":600,
    "method":"chacha20-ietf-poly1305",
    "fast_open":false,
    "nameserver":"8.8.8.8",
    "mode":"tcp_only",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=tls;obfs-host=www.bing.com;failover=127.0.0.1:7890;"
}
```

## vmess 节点 (v2ray)

vmess 协议是一个基于 TCP 的协议.

// vmess + tcp 

```
{
  "inbounds": [
    {
      "port": 8388, 
      "protocol": "vmess",    
      "settings": {
        "clients": [
          {
            "id": "af41686b-cb85-494a-a554-eeaa1514bca7",  
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "tcp"
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",  
      "settings": {}
    }
  ]
}
```

// vmess + tcp + tls, 这是完整, 真正的 TLS
```
{
  "inbounds": [
    {
      "port": 8388, 
      "listen":"127.0.0.1",
      "protocol": "vmess",    
      "settings": {
        "clients": [
          {
            "id": "af41686b-cb85-494a-a554-eeaa1514bca7",  
            "alterId": 0,
            "security": "none"
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [
            {
              "certificateFile": "/usr/local/etc/v2ray/server.crt", 
              "keyFile": "/usr/local/etc/v2ray/server.key" 
            }
          ]
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```

// vmess + ws + tls + web, 这里通过 web 转发了 ws 流量, 因此不需要 tls 设置
```
{
  "inbounds": [
    {
      "port": 8388,
      "listen":"127.0.0.1",
      "protocol": "vmess",
      "settings": {
        "clients": [
          {
            "id": "af41686b-cb85-494a-a554-eeaa1514bca7",
            "alterId": 0
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/ray"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "settings": {}
    }
  ]
}
```
