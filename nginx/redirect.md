## nginx 重定向

首先说明两个概念: **地址重写**和**地址转发**.

*地址重写* 是为了实现地址的标准化. 举个例子, 在地址栏当中输入 `www.baidu.com` 和 `www.baidu.cn` 最后都会被重写到了
`www.baidu.com`

*地址转发* 是指在网络数据传输过程中数据分组到达路由器或桥接器后, 该设备通过检查分组地址并将数据转发到最近的局域网的过程.

地址重写和地址转发的区别:

1. 地址重写会改变浏览器的地址, 使之变成浏览器最新的地址. 而地址转发是不会改变浏览器的地址的.
2. 地址重写产生两次请求, 而地址转发只会有一次请求.
3. 地址转发一般发生在同一站点项目内部, 而地址重写不受限制.
4. 地址转发的速度比地址重写快.

### rewrite 的作用

- rewrite 功能就是: 使用nginx提供的全局变量或自己设置的变量, 结合正则表达式和标志位实现**url重写**以及**重定向**.

- rewrite只能放在 `server`,`location`,`if` 中, 并且只能对 **域名后边的除去传递的参数外的字符串** 起作用, 
例如`http://seanlook.com/a/we/index.php?id=1&u=str` 只对 `/a/we/index.php` 重写.

- 如果想对 `域名` 或 `参数字符串` 起作用, 可以使用 `全局变量匹配`, 也可以使用 `proxy_pass反向代理`.

- 表面上看rewrite和location功能有点类似, 都能实现跳转. 主要区别在于**rewrite是在同一域名内更改获取资源的路径**
而**location是对一类路径做控制访问或反向代理**, 很多情况下`rewrite也会写在location里`, 它们的执行顺序是:

```
1. 执行server块的rewrite指令
2. 执行location匹配
3. 执行选定的location中的rewrite指令
```

> 如果其中某步URI被重写, 则重新循环执行1-3, 直到找到真实存在的文件; 循环超过10次, 则返回500 Internal Server Error
错误.


### rewrite 

```
rewrite regex replacement [flag]
```

如果正则表达式 regex 匹配请求 URI, 则 URI 将按照 replacement 字符串当中指定的规则进行更改.

> 如果 replacement 以 "http://", "https://" 或 "$schema" 开头, 则停止处理并将重定向返回给客户端.
>
> regex 当中是不能包含变量的. 
> replacement 可以使用 regex 匹配的结果, 使用 $1..$9 表示.

flag标志位:

- `last`: 表示**完成 rewrite**
- `break`: 停止执行 **当前虚拟主机** 的 **后续rewrite指令集**
- `redirect`: 返回302临时重定向, 地址栏会显示跳转后的地址
- `permanent`: 返回301永久重定向, 地址栏会显示跳转后的地址

作用上下文: server, location, if

> 说明: 因为301和302不能简单的只返回状态码, 还必须有重定向的URI, 这就是return指令无法返回301, 302的原因.

last vs break:

1. last一般写在server和if中, 而break一般使用在location中.
2. break 不终止重写后的url匹配, 即新的url会再从server走一遍流程, 而 last 终止重写后的匹配.
3. break 和 last 都能阻止继续执行后面的rewrite指令.

> if指令与全局变量
>
> 语法: 
> ``` 
> if(condition){
>   ...
> }
> ```
>
> condition可以是下面的内容:
> - 当表达式只是一个变量时, 如果值为空或任何以0开头的字符串都当作fasle
> - 直接比较变量的内容时, 使用 `=` 或 `!=`
> - `~`表示正则表达式匹配, `~*`不区分大小写的正则匹配, `!~` 不匹配


### rewrite_log

```
rewrite_log on|off;
```

启用 rewrite_log, 会将 ngx_http_rewrite_module 模块指令处理结果记录到 error_log 当中(日志级别是 notice) 

作用上下文: 	http, server, location, if


### if

```
if (condition) { ... }
```

作用上下文: server, location

condition 可以是以下当中的任何一种:

```
1. 变量名, 如果变量的值为空字符串或"0", 则为false

2. 使用 "=" 或 "!=" 运算符比较变量和字符串;

3. 使用 "~" (区分大小写匹配) 和 "~*"(不区分大小写匹配) 运算符将变量与正则表达式进行匹配. 正则表达式可以使用 $1..$9 捕获匹配的值. 如果正
则表达式包含 "}" 或 ";" 字符, 整个表达式要使用单引号括起来.

4. 使用 "-f" 和 "!-f" 运算符检查文件是否存在

5. 使用 "-d" 和 "!-d" 运算符检查目录是否存在

6. 使用 "-e" 和 "!-e" 运算符检查文件, 目录或符号链接是否存在
```

例子:

```
if ($http_user_agent ~ MSIE) {
    rewrite ^(.*)$ /msie/$1 break;
}

if ($http_cookie ~* "id=([^;]+)(?:;|$)") {
    set $id $1;
}

if ($request_method = POST) {
    return 405;
}

if ($slow) {
    limit_rate 10k;
}

if ($invalid_referer) {
    return 403;
}
```


### return

```
return code [text];
return code URL;
return URL;
```

停止处理, 并将指定的代码返回给客户端. 可以重定向URL(code 为 301, 302, 303, 307, 308 ) 或响应正文文本(其他code). 响应正文和重定向URL
可以包含变量. 作为一种特殊情况, 可以将重定向 URL 指定为该服务本地的 URI, 这种情况下, 完整的重定向 URL 是根据请求 schema ($schema) 以及
server_name_in_redirect 和 port_in_redirect 指令生成的.

另外, URL 当中还是可以包含变量的.

作用上下文: server, location, if


### 经典案例

1.将到 `test` 环境的请求转发到 `staging` 环境当中. 两个环境的请求API一样, 但是域名不一样. 一般是用来调试web页面.

- 使用 `proxy_pass` 的方式:

> 这里只是重点说明一下 location 的配置.

```
location /api/ {
    add_header Access-Control-Allow-Origin "$http_origin";
    add_header Access-Control-Allow-Credentials "true";
    add_header Access-Control-Allow-Headers "Origin, Authorization, Userid, Content-Type";
    
    proxy_hide_header "Access-Control-Allow-Origin";  
    proxy_hide_header "Access-Control-Allow-Credentials";
    proxy_hide_header "Access-Control-Allow-Headers";
    
    if ($request_method = "OPTIONS") {
        return 200;
    }

    proxy_pass  http://stage.web.com;
}
```

> 上述的配置同时解决了跨域带来的问题. 如果没有跨域的问题, 可以将 `add_header` 和 `proxy_hide_header` 和 `if` 相
> 关指令部分去掉.

- 使用 `redirect` 的方式:

```
location /api/ {
	return 308 http://stage.web.com$request_uri;
}
```

> 将所有的请求都永久重定向到 `stage` 环境. 之所以选择 `307/308` 方式, 是因为 `307/308` 重定向不会修改原来的请求方
> 法和参数. 
> 使用这种方式最大的问题是, 每个请求都会发送两次. 一次是重定向(308), 一次是真正的请求.

- 使用 `rewrite` 的方式:

```
location /api/ {
	rewrite ^/(.*) http://stage.web.com$request_uri last;
}
```

> 此种方式是使用临时重定向(`302`) 的方式, 后续的请求会发送 `GET` 请求, 并且请求参数会被修改. 


2.将请求的域名统一化.

- 使用 `rewrite`:

```
location / {
	rewrite ^/(.*) http://stage.web.com$request_uri break;
}
```

3. 统一将 ws 请求转发到一个后端地址

```
server {
   server_name 127.0.0.1;
   listen 9090;
   
   rewrite_log on; 
   location / {
        if ( $http_upgrade = websocket ) {
            rewrite ^/(.*)$ /ws$request_uri last;
            return 200;
        } 
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        proxy_pass http://192.168.2.182:9090;
   }
  
   location /ws { 
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        
        proxy_connect_timeout 1d;
        proxy_send_timeout 1d;
        proxy_read_timeout 1d;  
        
        proxy_http_version 1.1;
        proxy_set_header Upgrade websocket;
        proxy_set_header Connection Upgrade;
        
        proxy_pass http://192.168.2.182:9090$request_uri;
   }
}
```

### 常用的全局变量

- `$args`: 这个变量等于请求URI中的参数, 同`$query_string`
- `$http_cookie`: 客户端cookie信息
- `$schema`: 所有的协议, 比如http或者https.

- `$content_type`: 请求头当作的Content-Type字段
- `$content_length`: 请求Content-Length字段
- `$host`: 请求Host字段
- `$http_referer`: 请求Referer字段, 引用地址
- `$http_user_agent`: 请求User-Agent字段, 客户端代理
- `$http_origin`: 请求头当中的Origin

- `$remote_addr`: 客户端地址
- `$remote_port`: 客户端端口号
- `$remote_user`: 客户端用户名, 认证使用

- `$request`: 用户请求
- `$request_length`: 请求的长度
- `$request_method`: 客户端请求方法, POST, GET, PUT, OPTIONS等
- `$request_uri`: 包含请求参数的原始URI, 不包含主机名
- `$request_filename`: 当前请求的文件路径名
- `$uri`: 不包含请求参数的URI, 也不包含主机名

- `$body_bytes_sent`: 已发送的消息体字节数
- `$status`: 响应状态码

