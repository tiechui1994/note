## 后端服务器组指令

### upstream

**upstream指令**是设置 `后端服务器组` 的主要指令. 其他指令都在该指令中进行配置. **upstream指令** 
类似**http块**, **server块**等, 语法结构如下:

```
upstream NAME  {
    ...
}
```

其中 `NAME` 是 `后端服务器组` 的组名(类似server的server_name). 花括号中列出后端服务器组中包含的服务器. 
其中可以使用后面介绍的指令.

默认情况下, 某个服务器组接收到请求之后, 按照**轮询(RR)策略**顺序选择组内服务器处理请求. 如果一个服务器在
处理请求的过程中出现错误, 请求会被顺次交给组内的下一个服务器进行处理, 以此类推, 直到返回正常响应. 但如果组
内服务器都出错, 则返回最后一个服务器的处理结果.


### server

**server指令**用于设置组内的服务器. 语法结构如下:

```
server ADDRESS [PARAMETERS];
```

*ADDRESS*, 服务器的地址, 可以是包含端口号的IP地址(IP:Port), 域名 或者 以"unix:"为前缀用于进程间通信的
Unix Domain Socket.

*PARAMETERS*, 为当前服务器配置更多属性. 包括以下内容:

```
weight=N, 为组内服务器设置权重, 权重高的服务器优先用于处理请求. 此时组内服务器的选择策略是加权轮询策略. 组内
所有服务器的权重默认是1

max_fails=N, 设置一个请求失败的次数. 在一定时间范围内, 当对前服务器请求失败的次数超过该变量设置的值时, 认为
该服务器无效(down). 请求失败的各种情况与 proxy_next_upstream 指令的配置相配置. 默认设置为1. 如果设置为0,
则不使用上述的办法检查服务器是否有效.

注: HTTP 404 状态不认为是请求失败.

fail_timeout=time, 两个作用, 一是设置max_fails指令尝试请求某台组内服务器的时间, 即 max_fails 当中说的
"一定时间范围内". 二是检查服务器是否有效, 如果一台服务器被认为是无效(down)的, 该变量设置的时间为服务器无效的持
续时间. 在这个时间范围内不再检查该服务器的状态, 并一直认为它是无效(down)的. 默认设置是10s.

backup, 将某台组内服务器标记为备用服务器, 只有当正常的服务器处于无效(down)状态或者繁忙(busy)状态时, 该服务
器才被用来处理客户端的请求.

down, 将组内的某台服务器标记为永久的无效状态, 通常与ip_hash配合使用
```


### 负载均衡策略

#### ip_hash(策略)

**ip_hash指令**用于实现会话保持功能, 将某个客户端的多次请求定向到组内同一台服务器上, 保证客户端与服务器之间建
立稳定的会话. 只有当该服务器处于无效(down)状态时, 客户端请求才会被下一个服务器接收和处理.

```
ip_hash;
```

> 注意:
首先, **ip_hash指令**不能与*server指令中的weight变量*一起使用. 其次, 由于ip_hash技术主要根据客户端IP地址
分配服务器, 因此在整个系统中, Nginx服务器应该是处于最前段的服务器, 这样才能获取到客户端的IP地址, 否则它得到的
IP地址将是位于它前面服务器地址, 从而产生问题.

案例:

```
http {
    upstream servers.mydomain.com {
        server 192.168.2.3:80; // 端口可改
        server 192.168.2.4:80; 
        ip_hash;
    }
    
    server { 
        listen 80; 
        server_name www.mydomain.com; 
        location / { 
            proxy_pass http://servers.mydomain.com; 
            proxy_set_header Host $host; 
            proxy_set_header X-Real-IP $remote_addr; 
        } 
    } 
}
```


其中, *CONNECTIONS*为服务器的每一个工作进程允许该服务器组保持的空闲网络连接数的上限值. 如果超过该值, 工作
进程将采用**最近最少使用**的策略关闭网络连接.


#### hash(策略)

**hash指令**: 使用hash算法调度.

>注: nginx 1.7.2 以上的版本

```
hash KEY [consistent];
```
*KEY*, 包含文本, 变量及其组合.
如果指定了 **consistent** 参数, 则将使用ketama一致性哈希算法. *该方法确保在向组添加服务器或从组中删除服
务器时, 只有少数密钥将重新映射到不同的服务器*. 这有助于为缓存服务器实现更高的缓存命中率.

案例:

```
upstream backend {
    hash $request_uri consisent; # 使用请求uri hash
    server backend1.example.com;
    server backend2.example.com;
}
```


#### least_conn(策略)

**least_conn指令**用于配置nginx服务器使用负载均衡策略为为网络连接分配服务器组内的服务器. 该指令在功能上实
现了**最少连接负载均衡算法**, 在选择组内的服务器时, 考虑各服务器权重的同时,每次选择的都是当前网络连接最少的那
台服务器, 如果这样的服务器有多台, 就采用加权轮询原则选择权重最大的服务器.

```
least_conn;
```

案例:

```
upstream backend {
    least_conn;
    server backend1.example.com;
    server backend2.example.com;
}
```


#### random(策略)

random模式 提供了一个参数 `two`, 当这个参数被指定时, nginx会先随机地选择两个服务器(考虑**weight**),
然后用以下几种方法选择其中的一个服务器:

```
least_conn: 最少连接
least_time=header: 接收到 response header的最短平均时间($upstream_header_time, nginx plus版本)
least_time=last_byte: 接收到完整response的最短平均时间($upstream_response_time, nginx plus版本)
```

#### keepalive

**keepalive指令**用于控制网络连接保持功能. 通过该指令, 能够保持nginx服务器的工作进程为服务器组打开一部分
网络连接, 并且将数量控制在一定的范围之内.

```
keepalive CONNECTIONS;
```

### upstream 与 proxy_pass

nginx 中有两个模块都有 `proxy_pass` 指令:

- `ngx_http_proxy_module` 的 `proxy_pass`

```
语法: proxy_pass URL;
场景: location, if in location, limit_except
说明: 设置后端服务器的 protocol (http或https) 和 addres(domain 或 ip+port, 或 unix-domain socket), 以及
location中可以匹配的一个可选的URL.
```

- `ngx_stream_proxy_module` 的 `proxy_pass`

```
语法: proxy address;
场景: server
说明: 设置后端服务器的地址. 这个 address 可以是一个 domain 或 ip+port, 或 unix-domain socket
```

---

> `ngx_stream_module` 的 `proxy_pass`

使用 ip + port:

```
server {
    listen 127.0.0.1:12345;
    proxy_pass 127.0.0.1:8080;
}
```

使用 unix socket:

```
server {
    listen [::1]:12345;
    proxy_pass unix:/tmp/stream.socket;
}
```

---

> `ngx_http_module` 的 `proxy_pass`

直接使用URL:

```
server {
    listen      80;
    server_name www.test.com;
 
    # 正常代理, 不修改后端url的
    location /path/ {
        proxy_pass http://127.0.0.1;
    }
 
    # 修改后端url地址的代理(本例后端地址中, 最后带了一个 test)
    location /testb {
        proxy_pass http://www.other.com:8801/test;
    }
 
    # 使用 if in location
    location /google {
        if ( $geoip_country_code ~ (RU|CN) ) {
            proxy_pass http://www.google.hk;
        }
    }
 
    location /yongfu/ {
        # 没有匹配 limit_except 的, 代理到 unix:/tmp/backend.socket:/uri/
        proxy_pass http://unix:/tmp/backend.socket:/uri/;
 
        # 匹配到请求方法为: PUT or DELETE, 代理到9080
        limit_except PUT DELETE {
            proxy_pass http://127.0.0.1:9080;
        }
    }
}
```

使用 upstream:

```
upstream local {
    server 172.18.0.6:1234;
}

upstream www.local.com {
    server 172.18.0.1:53;
}

server {
    listen      80;
    server_name www.test.com;
 
    location /path/ {
        proxy_pass http://local;
    }
    
    location /path/ {
        set target www.local.com
        proxy_pass http://local;
    }
}
```

upstream + proxy_pass + resolver 的使用技巧: [文档](https://www.jianshu.com/p/5caa48664da5)

