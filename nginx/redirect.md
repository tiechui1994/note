## nginx的重定向功能的实现

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


### rewrite 语法

```
rewrite regex replacement [flag]
```

flag标志位:

- `last`: 表示**完成 rewrite**
- `break`: 停止执行 **当前虚拟主机** 的 **后续rewrite指令集**
- `redirect`: 返回302临时重定向, 地址栏会显示跳转后的地址
- `permanent`: 返回301永久重定向, 地址栏会显示跳转后的地址

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


### 常用案例

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

