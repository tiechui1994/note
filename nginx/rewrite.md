## rewrite 说明

- rewrite功能就是, 使用nginx提供的全局变量或自己设置的变量, 结合正则表达式和标志位实现url重写以及重定向.

- rewrite只能放在server{},location{},if{}中, 并且只能对**`域名后边的除去传递的参数外的字符串`**起作用, 
例如`http://seanlook.com/a/we/index.php?id=1&u=str` 只对`/a/we/index.php`重写.

- 如果想对**`域名`**或**`参数字符串`**起作用, 可以使用`全局变量匹配`, 也可以使用`proxy_pass反向代理`.

- 表面上看rewrite和location功能有点类似, 都能实现跳转. 主要区别在于**rewrite是在同一域名内更改获取资源的路径**
而**location是对一类路径做控制访问或反向代理**, 很多情况下`rewrite也会写在location里`, 它们的执行顺序是:

```
1. 执行server块的rewrite指令
2. 执行location匹配
3. 执行选定的location中的rewrite指令
```

**注意:** 如果其中某步URI被重写, 则重新循环执行1-3, 直到找到真实存在的文件; 循环超过10次, 则返回500 Internal Server Error错误.


## rewrite 语法

```
语法: rewrite regex replacement [flag]
可以配置的位置: server, location if
```

**flag标志位**

- `last`: 相当于Apache的`[L]`标记, 表示完成rewrite
- `break`: 停止执行当前虚拟主机的后续rewrite指令集
- `redirect`: 返回302临时重定向, 地址栏会显示跳转后的地址
- `permanent`: 返回301永久重定向, 地址栏会显示跳转后的地址

说明: 因为301和302不能简单的只返回状态码, 还必须有重定向的URI, 这就是return指令无法返回301,302的原因.

last和break区别:

```
1. last一般写在server和if中, 而break一般使用在location中
2. last不终止重写后的url匹配, 即新的url会再从server走一遍流程, 而break终止重写后的匹配
3. break 和 last都能阻止继续执行后面的rewrite指令.
```

**if指令与全局变量**

语法: if(condition){...}, 对给定的condition进行判断

condition可以是下面的内容:

- 当表达式只是一个变量时, 如果值为空或任何以0开头的字符串都当作fasle
- 直接比较变量的内容时, 使用 `=` 或 `!=`
- `~`表示正则表达式匹配, `~*`不区分大小写的正则匹配, `!~` 不匹配


**全局变量**

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
- `$request_method`: 客户端请求方法, POST, GET, PUT, OPTIONS等
- `$request_uri`: 包含请求参数的原始URI, 不包含主机名
- `$request_filename`: 当前请求的文件路径名
- `$uri`: 不包含请求参数的URI, 也不包含主机名

- `$body_bytes_sent`: 已发送的消息体字节数

