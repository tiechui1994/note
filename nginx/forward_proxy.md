# 正向代理配置

- **resolver**

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

- **resolver_timeout**

**resolver_timeout指令**用于设置DNS服务器域名解析超时时间.

```
resolver_timeout TIME;
```

- **proxy_pass**

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


# 案例

```
server {
    resolver 8.8.8.8;
    listen 80;
    location / {
        proxy_pass http://$http_host$request_uri;
    }
}
```
