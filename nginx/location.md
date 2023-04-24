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

```
语法: root path
默认值: root html
可以配置的位置: http, server, location, if
```

- alias

```
语法: root path
可以配置的位置: location
```

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

```
语法:
try_files file ... uri;     
try_files file ... =code;
     
配置的位置: server, location
```

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

```
语法: 
index file [file...];

配置的位置: http, server, location
```

默认值: `index index.html`

```
index  index.$geo.html  index.0.html  /index.html;
```
