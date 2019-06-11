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



## nginx 文件路径

nginx指定文件路径的方式: root 和 alias

- **root**

```
语法: root path
默认值: root html
可以配置的位置: http, server, location, if
```

- **alias**

```
语法: root path
可以配置的位置: location
```

## alias 与 root 区别

- **alias与root的主要区别在于如何解释location后面的uri**

root的处理结果: root路径 + **`请求URI`**

alias的处理结果: 使用alias路径替换**`已匹配的location路径`**

> 注意: alias的后面必须要以"/"结束


## 案例

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
