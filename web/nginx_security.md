# Nginx 增强安全策略

Nginx是一个轻量级的, 高性能的Web服务器以及反向代理和邮箱 `(IMAP/POP3)` 代理服务器. 它运行在 `UNIX`, 
`GNU /linux`, `BSD` 各种版本, `Mac OS X`, `Solaris` 和 `Windows`. Nginx是少数能处理C10K问题
的服务器之一. 跟传统的服务器不同, Nginx不依赖线程来处理请求. 相反, 它使用了更多的可扩展的事件驱动(异步)架
构. 下面介绍的通过 Nginx 配置提高运行在 `Linux或UNIX` 系统的 `Nginx Web` 服务器的安全性.


## 只允许自己的域名的访问

如果机器人只是随机扫描服务器的所有域名, 那拒绝这个请求.

```
if ( $host !~ ^(google.com|www.google.com|images.google.com)$ ) {
    return 444;
}
```

## 限制可用的请求方法

```
if ( $request_method !~ ^(GET|POST|PUT|DELETE|OPTIONS)$ ) {
    return 444;
}
```

## 拒绝 User-Agent

```
if ( $http_user_agent ~* wget|bbbike ) {
    return 403;
}
```

## 防止图片盗链

图片或HTML盗链的意思是有人用你网站的图片地址来显示在他的网站上.

```
location /images/ {
    valid_referers none blocked www.google.com google.com;
    if ( $invalid_referer ) {
        return 403;
    }
}
```

## 目录限制

- 通过IP地址限制访问

```
location / {
    deny 192.168.1.1; # 禁止192.168.1.1的ip
    allow 192.168.1.0/24; # 允许192.168.1.0/24 网段的
    deny all; # 拒绝其他的ip
}
```

- 通过密码保护目录

第一步: 创建密码文件并增加"user"用户

makdir /usr/local/nginx/conf/.htpasswd/
htpasswd -c /usr/local/nginx/conf/.htpasswd/passwd user

第二步: 编辑nginx.conf
```
# passwd protect /person-images and /delta dir
location ~ /(person-images/.|delta/.) {
    auth_basic "Restricted";
    auth_basic_user_file /usr/local/nginx/conf/.htpasswd/passwd;
}
```

> 一旦密码文件已经生成, 可以通过下面的命令增加允许访问的用户: \
> htpasswd -s /usr/local/nginx/conf/.htpasswd/passwd USER
