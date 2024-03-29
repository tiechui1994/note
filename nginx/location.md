## location

```
location = / {
    # 精确匹配/, 主机名后不带任何字符串
}

location ^~ xxx {
    # 匹配任何以 xxx(例如: /static 和 /static/ 是有区别的, 前者可以匹配/static/a.jpeg, /staticfile/a.jpeg, 
    # 后者只能匹配/static/a.jpeg) 开头的地址, 匹配符合以后, 停止向下搜索正则, 采用这一条
}

location ~ xxx {
    # 正则匹配的地址, 匹配符合之后, 还要继续向下搜索
    # 只有后面想正则表达式没有匹配到时, 才会采用这一条匹配
} 

location ~* xxx {
   # 正则匹配的地址, 匹配符合之后, 还要继续向下搜索
   # 只有后面想正则表达式没有匹配到时, 才会采用这一条匹配
}

location xxx {
    # 匹配任何以 xxx(例如: /static/, /static等) 开头的地址, 匹配符合以后, 还要继续向下搜索
    # 只有后面的正则表达式没有匹配到时, 才会采用这一条匹配
}

location / {
    # 匹配所有请求, 但是正则和最长字符串会优先匹配
}
```

- 以 `=` 开头表示精确匹配. 且location当中只能使用root作为静态资源路径. 使用alias会追加/

- 以 `^~` 开头表示uri匹配某个常规字符串开头, 不是正则匹配.

- 以 `~` 开头表示区分大小写的正则匹配

- 以 `~*` 开头表示不区分大小写的正则匹配

- `/`, 通用匹配, 如果没有其他匹配, 任何请求都会匹配到

优先级:

(location =) > (location 完整路径) > (location ^~ 路径) > (location ~, ~* 路径) > (location 部分路径) > 
(location /)


**命名location**

作用: 重定向

```
location @named {
    ...
}
```

```
server {
    try $uri @tornado;
    
    location @tornado {
        proxy_pass_header Server;
        proxy_set_header Host $http_host;
        proxy_set_header X-Real-IP $remote_addr;
        
        proxy_pass http://127.0.0.1:1234;
    }
}
```

---

## nginx 文件路径

nginx指定文件路径的方式: root 和 alias

- root

语法:
```
root path;
```

作用上下文: http, server, location, if

> 默认值: root html;

- alias

语法:
```
root path;
```

作用上下文: location

### alias 与 root 区别

- alias与root的主要区别在于: **如何解释location后面的uri**

root的处理结果: root路径 + **请求URI**

alias的处理结果: 使用alias路径替换**已匹配的location路径**

> 注意: alias的后面必须要以"/"结束


### 案例

```
location ^~ /t/ {
     root /www/root/html/;
}
```

如果请求的URI是/t/a.html, web服务器返回的/www/root/html/t/a.html文件.


```
location ^~ /t/ {
 alias /www/root/html/new/;
}
```

如果请求的URI是/t/a.html, web服务器返回的/www/root/html/new/a.html文件.

## try_files 

按顺序检查文件是否存在, 返回第一个找到的文件 或 文件夹(结尾加"/"表示为文件夹), 如果所有的文件或文件夹都找不到, 会进行
一个内部重定向到最后一个参数.

语法:
```
try_files file ... uri;     
try_files file ... =code;
```

作用上下文: server, location

> **只有最后一个参数可以引起一个内部重定向**, 之前的参数都只设置内部 URI 的指向. 最后一个参数是回退 URI 且必须存在,  
否则会出现内部500错误. 
>
> 命名的 location 也可以使用使用在最后一个参数中. 与 rewrite 指令不同, 如果回退 URI 不是命名的 location 那么 $args 
> 不会自动保留, 如果想保留 $args, 则必须明确声明.


- try_files 会根据 index 指令指示的文件, 设置内部指向

```
root /web;
location / {
    index index.html;
    try_files /static/ $uri $uri/ @callback;
}
```

> nginx会依次查找 `/web/static` 目录, `/web$uri`文件, `/web$uri/` 目录, 前面一旦找到存在的响应的文件, 则立即
> 返回文件内容. 都找不到内容重定向到 @callbak 处理. 当请求 $uri 是以 "/" 结尾的, 这上述的 $uri 会被替换为 "$uriindex.html"

> @callback 可以是一个文件, 也可以是一个状态码 (=404)

> nginx 在获取到目录时, 会产生一个 301 重定向, 再次进行请求.

> 注: try_files 当中的 **路径(包括绝对路径与相对路径)** 是以 root 或 alias 指令配置的路径作为根目录. 其中以 "/" 
> 结尾的表示目录, 否则表示文件.

- 跳转到后端服务

```
upstream tornado {
    server 127.0.0.1:8001;
}

server {
    server_name rumenz.com;
    return 301 $scheme://www.rumenz.com$request_uri; # 301 重定向
}

server {
    listen 80;
    server_name rumenz.com www.rumenz.com;
    
    root /web/www;
    index index.html index.htm;
    
    # 查询 /web/www$uri 或 重定向到 @tornado
    try_files $uri @tornado; 
    
    # 命名 location
    location @tornado {
        proxy_pass_header Server;
        proxy_set_header Host $http_host;
        proxy_set_header X-Reql-IP $remote_addr;
        proxy_set_header X-Scheme $scheme;
        
        proxy_pass http://tornado;
    }
}
```

## index

指定默认文档的文件名, 可以在文件名处使用变量. 如果指定多个文件, 按照指定的顺序逐个查找. 可以在列表末尾加上一个绝对路径名的文件.

语法:
```
index file [file...];
```

作用上下文: http, server, location

案例:
```
# 默认值
index index.html

index index.$geo.html  index.0.html  /index.html;
```

## listen

语法:
```
listen address[:port] [default_server] [ssl] [http2] [backlog=number] [rcvbuf=size] [sndbuf=size] 
[bind] [ipv6only=on|off] [reuseport];

listen port [default_server] [ssl] [http2] [backlog=number] [rcvbuf=size] [sndbuf=size] 
[bind] [ipv6only=on|off] [reuseport];


listen unix:path [default_server] [ssl] [http2] [backlog=number] [rcvbuf=size] [sndbuf=size] 
[bind];
```

作用上下文: server

default_server, 将使 server 成为 address:port 的默认 server. 如果所有的指令都没有 default_server 参数, 那么
将 address:port 的第一个 server 成成为默认 server.

ssl, 允许指定在此端口上接受的所有连接都应在 SSL 模式下工作. 这允许为处理 HTTP 和 HTTPS 请求的服务器提供更紧凑的配置.

http2, 将端口配置为接受 HTTP/2 连接. 通常, 为了使它起作用, 还应该指定 ssl 参数. 但 nginx 也可以配置为接受没有 SSL 
的 HTTP/2 连接.

backlog=number 在 listen() 调用中设置 backlog 参数, 以限制挂起连接队列的最大长度. 默认情况下, backlog 在 FreeBSD, 
DragonFly BSD 和 macOS 上设置为 -1, 在其他平台上设置为 511.

rcvbuf=size, sndbuf=size, TCP 连接的接收和发送缓冲区大小.

案例:

```
listen *:80;

listen 127.0.0.1:8000;
listen 127.0.0.1;
listen 8000;
listen *:8000;
```

## error_page

定义指定错误显示的 URI. uri 值可以包含变量.

语法:
```
error_page code ... [=[responseCode]] uri;
```

作用上下文: http, server, location, if in location

`=[responseCode]`, 可以修改响应的错误码(当 uri 是本地 location, responseCode 缺省值为200, 当 uri 是一个 
http 链接, responseCode 缺省值为302). 默认情况下, 响应错误码不会被修改.

案例1:

```
# 定义 404, 50x 的错误码 uri
error_page 404             /404.html;
error_page 500 502 503 504 /50x.html;
```

这会导致内部重定向到指定的 uri, 并将客户端请求方法更改为 "GET" (对于 "GET" 和 "HEAD" 以外的所有方法).


案例2:
```
# 将 50x 的响应错误码修改为 200
error_page 500 502 503 504 =200 /50x.html;
```

案例3:
```
# 重定向到命名 location
error_page 404 =200 @fallback;

location @fallback {
    proxy_pass http://backend;
}
```

## client 相关指令

### client_max_body_size

客户端 request body 的最大值. 如果 request body 超过该配置值, 将向客户端返回 41 (请求体太大) 错误. 

```
client_max_body_size SIZE;
```

作用上下文: http, server, location

注: 如果将 SIZE 设置为 0, 表示禁止对客户端 request body 大小检查.

默认:

```
client_max_body_size 1m;
```

### client_body_buffer_size 

设置读取 request body 的缓冲区大小. 如果 request body 大小超过缓冲区, 则将整个 request body 或其部分写入到临时
文件. 默认情况下, 缓冲区打钱等于两个内存页. 

```
client_body_buffer_size SIZE;
```

作用上下文: http, server, location

例子:

```
client_max_body_size 16k;
client_max_body_size 8k;
```

### client_body_timeout 

定义读取客户端 request body 的超时时间. **超时仅仅两次连续读取操作之间的时间间隔设置, 而不是真的整个 request body 
的传输.** 

```
client_body_timeout TIME;
```

作用上下文: http, server, location

默认:

```
client_body_timeout 60s;
```

### client_header_buffer_size 

设置读取客户端请求 Header 的缓冲区大小. 对于大多数请求, 1K 字节的缓冲区就足够了. 但是, 如果请求包含长 cookie, 则
它可能不适合 1k. 

```
client_header_buffer_size SIZE;
```

作用上下文: http, server

默认:

```
client_header_buffer_size 1k;
```

### client_header_timeout

定义读取客户端请求 Header 的超时时间. 如果客户端没有在这段时间内传输整个 Header, 请求将终止并出现 408(请求超时) 错
误.

```
client_header_timeout TIME;
```

作用上下文: http, server

默认:

```
client_header_timeout 60s;
```

### keepalive_timeout 

```
keepalive_timeout TIMEOUT [header_timeout];
```

作用上下文: http, server, location

第一个参数设置一个超时时间, 在此期间 `keep-alive` 客户端连接将在服务端保持打开状态. 0 表示禁止保持 `keep-alive` 
客户端连接. 第二个参数在 `Keep-Alive:timeout=time` 响应 Header 中设置一个值. 

默认:
```
keepalive_timeout 75s;
```
