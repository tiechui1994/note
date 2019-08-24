# nginx 多个虚拟主机的实现

## listen参数说明

listen 格式:

```
listen address[:port] 
        [default_server] 
        [backlog=number]  
        [deferred] 
        [bind] 
        [ipv6only=on|off] 
        [ssl] 
```

参数说明:

default_server, 

backlog=number, 在listen()调用中设置backlog参数, 该参数限制挂起连接队列的最大长度. 默认情况下, backlog在FreeBSD,
DragonFly BSD和macOS上设置为-1, 在其他平台上设置为511.

deferred, 指示在Linux上使用延迟的accept() (TCP_DEFER_ACCEPT套接字选项)

bind, 指示对给定的 'address:port' 对进行单独的 bind() 调用. 这很有用, 因为如果有多个 listen 指令具有相同的端口但
地址不同, 并且其中一个 listen 指令侦听给定端口('*:port')的所有地址, 则 nginx 将 bind() 仅绑定到"\*:port". 应该
注意的是, 在这种情况下将进行 getsockname() 系统调用以确定接受连接的地址. 如果使用 setfib, backlog, rcvbuf, sndbuf,
accept_filter, deferred, ipv6only 或 so_keepalive 参数, 那么对于给定的 'address:port' 对将始终进行单独的 
bind() 调用.


案例:

```
listen *:80             # 默认值
listen 127.0.0.1:8000;   
listen 127.0.0.1;       # 默认的端口是80
listen 8000;            # 默认的ip的本地ip
listen *:8000;          
listen localhost:8000;
```

> 注: 请求到达Nginx时, 先进行 **listen** 匹配, 当 listen 匹配完毕之后, 然后进行 **server_name** 匹配.


## server_name参数说明

```
nginx中的server_name指令主要用于配置基于名称虚拟主机.

请求Header当中的Host参数:
    当请求url是 http://127.0.0.1/index.html, 则Host为 "127.0.0.1"
    当请求url是 http://localhost/index.html, 则Host为 "localhost"
当请求到达nginx时, 首先会根据 Host 参数去匹配 server_name, 确定 server 之后,
会根据location的信息, 将请求 "送达" 到指定的服务器.
```

- 匹配顺序, server_name指令在接到请求后的匹配顺序如下:
 1. 确切的server_name匹配
 ```
   server {
      listen       80;
      server_name  www.example.com example.com;
      ...
   }
 ```
 
 2. 以*通配符开始的最长字符串(最左匹配)
 ```
   server {
      listen       80;
      server_name  *.test.com;
      ...
   }
 ```
 
 3. 以*通配符结束的最长字符串(最右匹配)
 ```
   server {
      listen       80;
      server_name  www.*;
      ...
   }
 ```
 
 说明: 通配符名字只可以在名字的起始处或结尾处包含一个星号, 并且星号与其他字符之间用点分隔. 所以,
 "www.*.example.org" 和 "w*.example.org" 都是非法的. 有一种情况,如".example.org"的特殊通配符,
 它可以既匹配确切的名字"example.org", 又可以匹配一般的通配符名字"*.example.org"
 
 4. 匹配正则表达式 (正则匹配)
 ```
   server {
      listen       80;
      server_name  ~^(?<www>.+)\.sklinux\.com$;
      ...
   }
 ```
 
 5. 默认server匹配 (默认匹配)
 ```
   当以上都不匹配的时候, 会选择默认的server. 默认的server只能有一个
 
   server {
     listen       80  default_server;
     server_name  www.default.com;
     ...
   }
   
   server {
     listen       80  default;
     server_name  www.default.com;
     ...
   }
 ```
 
 6. 第一个确切的server匹配
 ```
   以上都不匹配, 且没有默认的server的时候, 会选择监听端口号下的第一个确切的server作为匹配
 ```

# 端口转发案例

- 基于多个server配置

对外是多个server, 但是只有一个公网 ip:port. 请求的路径不做限制

```
server {
    listen 80;
    server_name www.test.com;
    
    location / {
        http://127.0.0.1:8000;
    }
}

server {
    listen 80;
    server_name www.example.com;
    
    location / {
        http://127.0.0.1:8001;
    }
}
```

- 基于多个location配置

对外是一个server, 且只有一个公网 ip:port. 请求的路径不同

```
server {
    listen 80;
    server_name www.test.com;
    
    location /test {
        http://127.0.0.1:8000;
    }
    
    location /example {
        http://127.0.0.1:8001;
    }
}
```
