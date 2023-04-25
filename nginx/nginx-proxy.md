## proxy

#### resolver

`resolver` 用于设置DNS服务器的IP地址. DNS服务器主要工作是进行域名解析, 将域名映射为对应的IP地址. 语法如下:

```
resolver ADDRESS ... [valid=TIME] [ipv4=on|off] [ipv6=on|off];
```

作用上下文: http, server, location

*ADDRESS*, DNS服务器的IP地址. 如果不指定端口号, 默认使用53端口号.

*TIME*, 设置数据包在网路中的有效时间. 出现该指令定主要原因是, 在访问站点的时, 有很多情况下使得数据包在一定时间内不能被
传递到目的地, 但是又不能让该数据包无限期的存在, 于是就需要设定一段时间, 当数据包在这段时间内没有到达目的地, 就会被丢弃, 
然后发生者会接收到一个消息, 并决定是否要重发该数据包.


例子:
```
resolver 127.0.0.1 [::1]:5353 valid=30s;
```


#### resolver_timeout

`resolver_timeout` 用于设置DNS服务器域名解析超时时间.

```
resolver_timeout TIME;
```

作用上下文: http, server, location

例子:
```
resolver_timeout 30s;
```


#### proxy_pass

`proxy_pass` 用于设置代理服务器的协议和地址, `它不仅仅用于nginx服务器的代理服务, 更主要的是用于反向代理服务`

```
proxy_pass URL;
```

作用上下文: location, if in location, limit_except

*URL*, 即为设置的 `代理服务器协议和地址`. 在代理服务器配置当中, 该指令的设置相对固定.

```
proxy_pass http://$http_host$request_uri;
```

其中, 代理服务器协议设置为 HTTP, $http_host 和 $request_uri 两个变量是 NGINX 配置支持的用于自动获取主机和URI的变量.


案例:

```
server {
    resolver 8.8.8.8;
    listen 80;
    location / {
        proxy_pass http://$http_host$request_uri;
    }
}
```


## 反向代理配置

#### proxy_pass

`proxy_pass` 用来设置被代理服务器的地址. 可以是主机名,IP地址加端口号等形式.

```
proxy_pass URL;
```

作用上下文: location, if in location, limit_except


设置上游服务器的协议和地址, 还可以设置可选的URI以定义本地路径和上游服务器的映射关系. 可以设置的协议是"http"或"https". 
而地址既可以使用域名或者IP地址加端口号(可选)的形式来定义:

```
proxy_pass http://localhost:8080/uri/;
```

又可以使用UNIX域套接字路径来定义. 该路径接在"unix"字符串后面, 两端由冒号(:)所包围:

```
proxy_pass http://unix:/tmp/bacend.socket:/uri/;
```

如果解析一个域名得到多个地址, 所有的地址都会以轮询的方式被使用. 

> - 如果 proxy_pass 使用了URI, 当请求到上游服务器时, "规范化以后的请求路径"与"配置中的路径"的匹配部分将被替换为"指令
中定义的URI":
>```
> location /api/ {
>   proxy_pass http://127.0.0.1/remote/;
> }
>```
>
>> 言外之意, 如果客户端到nginx请求uri是 "/api/name", 那么到上游服务器的uri将变成"/remote/name", 其中"/api/"是
规范化的请求路径和配置中的路径的相同部分, 被指令中定义的URI("/remote/")替换. 也就是说, 配置中的路径和指令中定义的URI
在格式上需要保持一致.
>
> - 如果 proxy_pass 没有使用 URI, 到上游服务器的请求URI一般是客户端发起的原始URI, 如果nginx改变了请求URI, 则到后端
服务器的URI是nginx改变以后完整的规范化URI:
>```
> location /api/ {
>   proxy_pass http://127.0.0.1;
> }
>```
>
> - 使用正则表达式定义路径. 这种状况下, 指令不应该使用URI
>
> - 在需要代理的路径中, 使用`rewrite`指令改变了URI, 但仍使用相同配置处理请求(break), 在这种状况下, 本指令设置的URI会
被忽略, 改变后的URI将被发送给上游服务器.
>```
> location /api/ {
>   rewrite /api/([^/]+) /users?name=$1 break;
>   proxy_pass http://127.0.0.1;
> }
>```
>  
>> 言外之意, 如果客户端到nginx请求uri是"/api/zhangsan", 那么到上游服务器的uri将变成"/users?name=zhangsan".
`break`表示终止当前server的匹配,那么最终会执行`proxy_pass`. 在可以也可以使用`last`. 

```
server {
    listen 80;
    server_name www.baidu.com;
    location /server/ {
        proxy_pass http://192.168.1.1;
    }
}
```

如果客户端使用`http://www.baidu.com/server`发起请求, 由于**proxy_pass不包含URI**, 到上游服务器的地址是`http://192.168.1.1/server`.

```
server {
    listen 80;
    server_name www.baidu.com;
    location /server/ {
        proxy_pass http://192.168.1.1/local/;
    }
}
```

如果客户端使用`http://www.baidu.com/server`发起请求, 由于**proxy_pass包含URI**, 到上游服务器的地址是`http://192.168.1
.1/local/`.


---


#### proxy_pass_request_headers(请求)

`proxy_pass_request_headers` 用于配置是否将 `原始请求的Header` 发送给上游服务器.

```
proxy_pass_request_headers on|off;
```

作用上下文: http, server, location

> 默认是开启(on).


#### proxy_set_header(请求)

允许在传递给`上游服务器`的请求头当中重新定义或添加字段. 该值可以包含文本, 变量, 及其组合. 当且仅当`当前级别上未定义proxy_set_header`
指令时, `这些指令才从上一级继承`. 默认情况下, 仅重新定义两个字段:

```
proxy_set_header Host       $proxy_host;
proxy_set_header Connection close;
```

作用上下文: http, server, location

如果启用了缓存, 则会从原始请求Header当中的"If-Modified-Since","If-Unmodified-Since","If-None-Match","If-Match",
"Range", 和"If-Range"不会传递到代理服务器.

```
proxy_set_header FIELD VALUE;
```
*FIELD*, 要修改的头域.
*VALUE*, 更改的值, 支持使用文本, 变量或者变量的组合.

`proxy_set_header` 和 `add_header`的区别:

- `proxy_set_header` 是nginx设置 `请求头` 信息给上游服务器, `add_header` 是nginx设置 `响应头` 信息给客户端.
- `proxy_set_header` 针对的是请求头, `add_header` 针对的是响应头.

#### proxy_pass_header, proxy_hide_header (响应)

默认情况下, nginx不会将 `上游服务器` 的响应中的标头字段 "Date", "Server", "X-Pad" 和 "X-Accel-..." 传递给客户端.
`proxy_hide_header` 可以设置其他的不要传递给客户端字段的名称. 

相反, 如果需要允许传递相应的字段给客户端, 则可以使用 `proxy_pass_header` 指令.

> 言外之意是 `proxy_pass_header` 的值只能是 "Date", "Server", "X-Pad" 和 "X-Accel-..." 当中一个. 

```
prox_pass_header FIELD;
proxy_hide_header FIELD;
```

作用上下文: http, server, location

*FIELD*是需要发送的头域.

#### proxy_ignore_headers(响应)

`proxy_ignore_headers` 设置忽略 `上游服务器` 返回的指定响应头.

```
proxy_ignore_headers FIELD ...;
```

作用上下文: http, server, location

*FIELD*是要设置的HTTP响应头的头域. 可选的值包含:"X-Accel-Redirect","X-Accel-Expires","X-Accel-Limit-Rate" 
"X-Accel-Buffering","X-Accel-Charset","Expires","Cache-Control","Set-Cookie","Vary".

如果不被取消, 这些头部的处理可能产生下面的结果:

- "X-Accel-Expires", "Expires", "Cache-Control" 和 "Set-Control",设置响应缓存的参数;
- "X-Accel-Redirect", 执行到指定URI的内部跳转
- "X-Accel-Limit-Rate", 设置响应到客户端的传输速率限制
- "X-Accel-Buffering", 启动或者关闭响应缓冲
- "X-Accel-Charset", 设置响应所需的字符集


上述的header之间关系:

```
请求路径:

客户端 -> nginx -> 上游服务器

执行顺序如下:

proxy_pass_request_headers (nginx->上游服务器, 客户端的请求头是否发送)
proxy_set_header (nginx->上游服务器, 修改请求的头)

响应路径:

上游服务器 -> nginx -> 客户端

proxy_pass_header (上游服务器->nginx, nginx可以允许的响应头, 可选数量比较少)
proxy_hide_header (上游服务器->nginx, nginx可以隐藏的响应头)
proxy_ignore_headers (上游服务器->nginx, 可以忽略的响应头, 可选数量比较少)
```

---


#### proxy_pass_request_body

`proxy_pass_request_body`用于配置是否将`客户端的请求体`发送给上游服务器.

```
proxy_pass_request_body on|off;
```

作用上下文: http, server, location

> 默认是开启(on).

#### proxy_set_body

`proxy_set_body`用于更改nginx服务器接收到的客户端请求的请求体, 然后将新的请求体发送给上游服务器.

```
proxy_set_body VALUE;
```

作用上下文: http, server, location

*VALUE*, 更改的信息, 支持使用文本, 变量或者变量的组合.


#### proxy_connect_timeout
`proxy_connect_timeout`配置nginx服务器到上游服务器建立连接的超时时间. 默认是60s.

#### proxy_read_timeout
`proxy_read_timeout`配置nginx服务器从上游服务器读取响应的超时, 此超时是之相邻两次读操作之间是最长时间间隔, 而不是整
个响应传输完成的最长时间. 如果上游服务器在超时时间段内没有传输任何数据, 连接将被关闭. 默认是60s.

#### proxy_send_timeout
`proxy_send_timeout`配置nginx向上游服务器传输请求的超时. 此超时是之相邻两次写操作之间是最长时间间隔, 而不是整个请求
传输完成的最长时间. 如果上游服务器在超时时间段内没有接收到任何数据, 连接将被关闭. 默认是60s.


#### proxy_http_version
`proxy_http_version`设置nginx服务器提供代理服务器的HTTP协议版本. 默认是1.0, 1.1版本支持服务器组中的keepalive指令.


#### proxy_method
`proxy_method`用于设置nginx服务器请求被代理服务器时使用的方法, 一般是POST或者GET. 设置了该指令, 客户端的请求方法将被
忽略.

```
proxy_method METHOD;
```


#### proxy_ignore_client_abort

`proxy_ignore_client_abort` 用于设置在客户端中断请求时, nginx服务器是否中断对上游服务器的请求.

```
proxy_ignore_client_abort on|off;
```

默认是off. 即当客户端中断网络请求时, nginx服务器中断对上游服务器的请求.


#### proxy_redirect

```
proxy_redirect REDIRECT REPLACE;
proxy_redirect default;
proxy_redirect off;
```

作用上下文: http, server, location

REDIRECT 匹配 Location 头域值的字符串, `支持变量使用和正则表达式`.
REPLACE 用于替换 REDIRECT 变量内容的字符串, `支持变量的使用`.

`proxy_redirect` 设置上游服务器"Location"响应头和"Refresh"响应头的替换文本. 假设上游服务器返回的响应头是:

```
Location: http://localhost:8080/two/some/uri/
```

那么, 指令 `proxy_redirect http://localhost:8080/two http://frontend/one/;` 将把"Location"改写为:

```
Location: http//frontend/one/some/uri/
```

`REPLACE`字符串可以省略服务器名, 即指令等价为`proxy_redirect http://localhost:8080/two /one/`

使用`default`, 代表使用`location块`的uri变量作为REPLACE, 并使用`proxy_pass`的uri作为REDIRECT下面的两个配置是等
价的:

```
location /one/ {
    proxy_pass http://upstream:port/two/;
    proxy_redirect default;
}

location /one/ {
    proxy_pass http://upstream:port/two/;
    proxy_redirect http://upstream:port/two/; /one/;
}
```

>上面的配置两者是一致的.

因为同样的原因, `proxy_pass`指令使用变量事, 不允许`proxy_redirect`使用`default`参数.

除此之外, 可以同时定义多个`proxy_redirect`指令:

```
proxy_redirect default;
proxy_redirect http://localhost:8080/ /;
proxy_redirect http://www.example.com/ /;
```

另外, `off`参数可以使所有相同配置级别的`proxy_redirect`指令无效:

```
proxy_redirect off;
proxy_redirect default;
proxy_redirect http://localhost:8080/ /;
proxy_redirect http://www.example.com/ /;
```

#### proxy_cookie_domain

```
proxy_cookie_domain off;
proxy_cookie_domain DOMAIN REPLACE;
```

作用上下文: http, server, location

*DOMAIN* 和 *REPLACE*配置字符串, 以及`domain`属性中起始的点将被忽略. 匹配过程大小写不敏感.

`proxy_cookie_domain`设置`Set-Cookie`响应头的`domain`属性的替换文本. 假设上游服务器返回的"Set-Cookie"响应头包
含有属性"domain=localhost", 那么指令`proxy_cookie_domain localhost example.org`将改变这个属性改为"domain=example.org". 


DOMAIN和REPLACE配置字符串可以包含变量:

```
proxy_cookie_domain www.$host $host;
```

DOMAIN和REPLACE 配置字符串可以使用正则表达式. 这事DOMAIN应以"~"标志开头, 且可以使用命名匹配组和位置匹配组, 而且REPLACE
可以引用这些匹配组:

```
proxy_cookie_domain www.$host $host;
proxy_cookie_domain ~\.([a-z]+\.[a-z]+)$ $1;
```

`off`参数可以取消当前配置级别的所有`proxy_cookie_domain`指令.

```
proxy_cookie_domain off;
proxy_cookie_domain www.$host $host;
proxy_cookie_domain ~\.([a-z]+\.[a-z]+)$ $1;
```

#### proxy_cookie_path

```
proxy_cookie_path off;
proxy_cookie_path PATH REPLACE;
```

> 用法和 `proxy_cookie_domain` 类似.



#### proxy_intercept_errors

```
proxy_intercept_errors on|off;
```

当`上游服务器`的响应状态码大于等于400, 决定是否直接将响应发送给客户达. 亦或将响应转发给nginx由`err_page`指令来处理.


#### proxy_next_upstream

```
proxy_next_upstream STATUS ...;
```

STATUS是设置的上游服务器返回的状态, 可以是一个或者多个, 这些状态包括:
- error, 和上游服务器建立连接时, 或者向上游服务器发送请求, 或者从上游服务器接受响应头时, 出现错误.
- timeout, 和上游服务器建立连接时, 或者向上游服务器发送请求, 或者从上游服务器接受响应头时, 出现超时.
- invalid_header, 上游服务器返回的响应头为空或者非法.
- http_500|http_502|http_503|http_504|http_404, 上游服务器返回500,502,503,504,或者404状态码
- off, 停止将请求发送给下一台上游服务器.

指定在何种状况下一个失败的请求应该被发送到下一台上游服务器.


#### proxy_ssl_session_reuse

`proxy_ssl_session_reuse`配置是否使用基于SSL安全协议的会话连接(https)被代理的服务器.

```
proxy_ssl_session_reuse on|off;
```

默认设置为开启(on)状态. 如果在错误日志中发生"SSL3_GET_FINSHED:digest check failed"的状况, 可以将该指令配置为关闭
(off)状态.


## nginx代理配置

使用nginx服务器做代理服务器.

### 静态资源服务器

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
        try_files $uri $uri/ /index.html;
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
```

### 动态代理服务器

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
		proxy_pass http://127.0.0.1:3000;
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
```

### CGI 服务器 - PHP

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
        try_files $uri $uri/ /index.html;
    }
	
    location ~ \.php$ {
        # 404
        try_files $fastcgi_script_name = 404;
        
        # default fastcgi_params
        include fastcgi_params;
        
        # settings
        fastcgi_pass			unix:/var/run/php/php-fpm.sock | 127.0.0.1:9000;
        fastcgi_index			index.php;
        fastcgi_buffers			8 16k;
        fastcgi_buffer_size		32k;
        
        # params
        fastcgi_param DOCUMENT_ROOT     $realpath_root;  #root位置
        fastcgi_param SCRIPT_FILENAME	$realpath_root$fastcgi_script_name; # 脚本文件
        fastcgi_param PHP_ADMIN_VALUE	"open_basedir=$base/:/usr/lib/php/:/tmp/";
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
}
```


### UWSGI 服务器 - Python

```
server {
    listen 80;
    listen [::]:80;

    server_name example.com;
    root /var/www/example/public;
	
    location / {
		# default uwsgi_params
        include uwsgi_params;
        
        # settings
        uwsgi_pass  unix:/tmp/uwsgi.sock | 127.0.0.1:3000;
        
        # params
        uwsgi_param Host                $host;
        uwsgi_param X-Real-IP	        $remote_addr;
        uwsgi_param X-Forwarded-For     $proxy_add_x_forwarded_for;
        uwsgi_param X-Forwarded-Proto   $http_x_forwarded_proto;
    }
    
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "no-referrer-when-downgrade" always;
    add_header Content-Security-Policy "default-src * data: 'unsafe-eval' 'unsafe-inline'" always;
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

```
