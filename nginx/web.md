# nginx 配置

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
 
 2. 以*通配符开始的最长字符串
 ```
   server {
      listen       80;
      server_name  *.test.com;
      ...
   }
 ```
 
 3. 以*通配符结束的最长字符串
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
 
 4. 匹配正则表达式
 ```
   server {
      listen       80;
      server_name  ~^(?<www>.+)\.sklinux\.com$;
      ...
   }
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
