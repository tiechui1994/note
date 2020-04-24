## 正向代理配置

### resolver

**resolver指令**用于指定DNS服务器的IP地址. DNS服务器主要工作是进行域名解析, 将域名映射为对应的IP地址. 语法
结构如下:

```
resolver ADDRESS ... [valid=TIME];
```

*ADDRESS*, DNS服务器的IP地址. 如果不指定端口号, 默认使用53端口号.

*TIME*, 设置数据包在网路中的有效时间. 出现该指令定主要原因是, 在访问站点的时, 有很多情况下使得数据包在一定
时间内不能被传递到目的地, 但是又不能让该数据包无限期的存在, 于是就需要设定一段时间, 当数据包在这段时间内没有
到达目的地, 就会被丢弃, 然后发生者会接收到一个消息, 并决定是否要重发该数据包.


例子:

```
resolver 127.0.0.1 [::1]:5353 valid=30s;
```


### resolver_timeout

**resolver_timeout指令**用于设置DNS服务器域名解析超时时间.

```
resolver_timeout TIME;
```


### proxy_pass

**proxy_pass指令**用于设置代理服务器的协议和地址, `它不仅仅用于nginx服务器的代理服务, 更主要的是用于反向代理服务`

```
proxy_pass URL;
```

*URL*, 即为设置的**代理服务器协议和地址**. 

在代理服务器配置当中, 该指令的设置相对固定.

```
proxy_pass http://$http_host$request_uri;
```

其中, 代理服务器协议设置为HTTP, $http_host和$request_uri两个变量是NGINX配置支持的用于自动获取主机和URI的变量.


---

## 案例

```
server {
    resolver 8.8.8.8;
    listen 80;
    location / {
        proxy_pass http://$http_host$request_uri;
    }
}
```

---


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


---


### proxy_pass_request_headers(请求)

**proxy_pass_request_headers指令**用于配置是否将`客户端的请求头`发送给代理服务器.

```
proxy_pass_request_headers on|off;
```
默认是开启(on), 该指令可以在http块, server块,或者location块中进行配置.


### proxy_hide_header(请求)

**proxy_hide_header指令**用于设置nginx服务器在发送HTTP响应时, 隐藏一些头域信息.

```
proxy_hide_header FIELD;
```
*FIELD*是需要隐藏的头域, 该指令可以在http块, server块,或者location块中进行配置.


### proxy_set_header(请求)

**proxy_set_header指令** 用于更改nginx服务器接收到的 **客户端请求的请求头信息**, 然后将新的请求头发
送给被代理的服务器.

```
proxy_set_header FIELD VALUE;
```
*FIELD*, 要修改的头域.
*VALUE*, 更改的值, 支持使用文本, 变量或者变量的组合.

```
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forward-For $proxy_add_x_forwarded_for;
```

### proxy_pass_header(响应)

**proxy_pass_header指令** 设置  *代理服务响应的头域信息*.  默认情况下, nginx服务器在发送响应的时候,
报文头中不包含"Date", "Server", "X-Accel"等来自代理服务器的头域信息.

```
prox_pass_header FIELD;
```
*FIELD*是需要发送的头域, 该指令可以在http块, server块,或者location块中进行配置.


### proxy_ignore_headers(响应)

**proxy_ignore_headers指令** *设置一些HTTP响应头的头域*. nginx服务器接收到被代理服务器的响应数据之后,不会
处理处理被设置的头域.

```
proxy_ignore_headers FIELD ...;
```
*FIELD*是要设置的HTTP响应头的头域. 例如: `X-Accel-Redirect`, `X-Accel-Expires`, `Set-Cookie`,
`Cache-Control`等.


**区别:**

```
请求路径:

client -> nginx -> server

执行顺序如下:

proxy_pass_request_headers (nginx->server, 客户端的请求头是否发送)
proxy_set_header (nginx->server, 修改请求的头)
proxy_hide_header (nginx-server, 隐藏请求的头)

响应路径:

server -> nginx -> client

proxy_pass_header (server->nginx, server可以发送给nginx的响应头)
proxy_ignore_headers (nginx->client, nginx可以发送给client的响应头)
```

---


### proxy_pass_request_body

**proxy_pass_request_body指令**用于配置是否将`客户端的请求体`发送给代理服务器.

```
proxy_pass_request_body on|off;
```
默认是开启(on), 该指令可以在http块, server块,或者location块中进行配置.


### proxy_set_body

**proxy_set_body指令**用于更改nginx服务器接收到的**客户端请求的请求体**, 然后将新的请求体发
送给被代理的服务器.

```
proxy_set_body VALUE;
```
*VALUE*, 更改的信息, 支持使用文本, 变量或者变量的组合.


---


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

**proxy_method指令**用于设置nginx服务器请求被代理服务器时使用的方法, 一般是POST或者GET. 设置
了该指令, 客户端的请求方法将被忽略.

```
proxy_method METHOD;
```


### proxy_ignore_client_abort

**proxy_ignore_client_abort指令**用于设置在客户端中断请求时, nginx服务器是否中断对代理服务器的请求.

```
proxy_ignore_client_abort on|off;
```
默认是off. 即当客户端中断网络请求时, nginx服务器中断对被代理服务器的请求.


### proxy_redirect

**proxy_redirect指令**修改*被代理服务器返回的响应头中的Location头域和Refresh头域*, 与**proxy_pass**
配合使用. 例如, nginx服务器通过proxy_pass指令将client的请求重写为被代理服务器的地址, 那么nginx服务器在
返回给客户端响应头中的Location头域显示的地址和client发起请求的地址相对应, 而不是代理服务器直接返回的地址信息.

```
proxy_redirect REDIRECT REPLACE;
proxy_redirect default;
proxy_redirect off;
```
*REDIRECT*匹配Location头域值的字符串, 支持变量使用和正则表达式
*REPLACE*用于替换REDIRECT变量内容的字符串, 支持变量的使用.

使用*default*,代表使用Location块的uri变量作为REPLACE, 并使用proxy_pass变量作为REDIRECT
下面的两个配置是等价的:
```
location /server/ {
    proxy_pass http://proxy/source/;
    proxy_redirect default;
}

location /server/ {
    proxy_pass http://proxy/source/;
    proxy_redirect http://proxy/source/ /server/;
}

location /server/ {
    proxy_redirect off;
    proxy_pass http://proxy/source/;
}
```

*off*当前作用域下所有的proxy_redirect指令配置全部无效.


### proxy_intercept_errors

**proxy_intercept_errors指令**用于配置一个状态是开启还是关闭. 在开启该状态时, 如果被代理的服务器
返回的HTTP状态码是400或者大于400, 则nginx服务器使用自己定义的错误页面(使用error_page指令); 如果是
关闭状态, nginx服务器直接将被代理服务器返回的HTTP状态返回给客户端.

```
proxy_intercept_errors on|off;
```


### proxy_next_upstream

在配置nginx服务器反向代理功能时, 如果使用upstream指令配置了一组服务器作为被代理服务器, 服务器组中各个服务
器的请求规则遵循upstream指令配置的轮训规则, *同时可以使用该指令在发生异常状况时, 将请求顺次交由下一个组内
的服务器处理*

```
proxy_next_upstream STATUS ...;
```
*STATUS*是设置的服务器返回的状态, 可以是一个或者多个, 这些状态包括:
- error, 在建立连接, 向被代理的服务器发生请求或者读取响应头时服务器发生连接错误.
- timeout, 在建立连接, 向被代理的服务器发生请求或者读取响应头时服务器发生连接超时.
- invalid_header, 被代理的服务器返回的响应头为空或者无效
- http_500|http_502|http_503|http_504|http_404, 被代理服务器返回500,502,503,504,或者404状态码
- off, 无法将请求发生给被代理的服务器.


### proxy_ssl_session_reuse

**proxy_ssl_session_reuse指令**配置是否使用基于SSL安全协议的会话连接(https)被代理的服务器.

```
proxy_ssl_session_reuse on|off;
```
默认设置为开启(on)状态. 如果在错误日志中发生"SSL3_GET_FINSHED:digest check failed"的状况, 可以将该
指令配置为关闭(off)状态.
