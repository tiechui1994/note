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

注意: alias的后面必须要以"/"结束


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
