## 反向代理配置

### proxy_pass

**proxy_pass指令**用来设置被代理服务器的地址. 可以是主机名,IP地址加端口号等形式.

```
proxy_pass URL;
```

*URL*为要设置的被代理服务器的地, 包含传输协议, 主机名称(或IP地址+端口号), URI等要素.
传输协议通常是"http"或"https". 指令同时还可以接受以"unix"开始的UNIX-domain套接字
路径.

案例:

```
proxy_pass http://www.baidu.com/uri;
proxy_pass uinx:/tmp/backend.sock;
```

注意:
在使用该指令过程中还需要注意, URL中是否包含有URI, nginx服务器的处理方式是不同的. 
如果URL中不包含URI, nginx服务器不会改变原地址的URI;
如果URL中包含了URI, nginx服务器会使用新的URI代替原来的URI.

```
server {
    listen 80;
    server_name www.baidu.com;
    location /server/ {
        proxy_pass http://192.168.1.1;
    }
}
```
如果客户端使用 `http://www.baidu.com/server` 发起请求, 由于**proxy_pass指令的不包含URI**,
所以转向的地址是**http://192.168.1.1/server**.

```
server {
    listen 80;
    server_name www.baidu.com;
    location /server/ {
        proxy_pass http://192.168.1.1/local/;
    }
}
```
如果客户端使用 `http://www.baidu.com/server` 发起请求, 由于**proxy_pass指令的包含URI**,
所以转向的地址是**http://192.168.1.1/local/**.


### proxy_hide_header

**proxy_hide_header指令**用于设置nginx服务器在发送HTTP响应时, 隐藏一些头域信息.

```
proxy_hide_header FIELD;
```
*FIELD*是需要隐藏的头域, 该指令可以在http块, server块,或者location块中进行配置.


### proxy_pass_header

**proxy_pass_header指令**设置代理服务响应的头域信息.  默认情况下, nginx服务器在发送响应的时候,
报文头中不包含"Date", "Server", "X-Accel"等来自代理服务器的头域信息.

```
prox_pass_header FIELD;
```
*FIELD*是需要发送的头域, 该指令可以在http块, server块,或者location块中进行配置.


### proxy_pass_request_body

**proxy_pass_request_body指令**用于配置是否将`客户端的请求体`发送给代理服务器.

```
proxy_pass_request_body on|off;
```
默认是开启(on), 该指令可以在http块, server块,或者location块中进行配置.


### proxy_pass_request_headers

**proxy_pass_request_headers指令**用于配置是否将`客户端的请求头`发送给代理服务器.

```
proxy_pass_request_headers on|off;
```
默认是开启(on), 该指令可以在http块, server块,或者location块中进行配置.


### proxy_set_header

**proxy_set_header指令**用于更改nginx服务器接收到的**客户端请求的请求头信息**, 然后将新的请求头发
送给被代理的服务器.

```
proxy_set_header FIELD VALUE;
```
*FIELD*, 要修改的头域.
*VALUE*, 更改的值, 支持使用文本, 变量或者变量的组合.


### proxy_set_body

**proxy_set_body指令**用于更改nginx服务器接收到的**客户端请求的请求体**, 然后将新的请求体发
送给被代理的服务器.

```
proxy_set_body VALUE;
```
*VALUE*, 更改的信息, 支持使用文本, 变量或者变量的组合.


### proxy_connect_timeout
**proxy_connect_timeout指令**配置nginx服务器到被代理服务器尝试建立连接的超时时间.
默认是60s.

### proxy_read_timeout
**proxy_read_timeout指令**配置nginx服务器到被代理服务器发生read请求后, 等待响应的超时时间.
默认是60s.

### proxy_send_timeout
**proxy_send_timeout指令**配置nginx服务器到被代理服务器发生write请求后, 等待响应的超时时间.
默认是60s.


### proxy_http_version
**proxy_http_version指令**设置nginx服务器提供代理服务器的HTTP协议版本. 默认是1.0. 1.1版本
支持服务器组中的keepalive指令.


### proxy_method

### proxy_ignore_client_abort

### proxy_ignore_headers

### proxy_redirect

### proxy_intercept_errors

### proxy_headers_hash_max_size

### proxy_headers_hash_bucket_size

### proxy_next_upstream

### proxy_ssl_session_reuse