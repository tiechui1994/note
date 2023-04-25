# ssl server 配置

## SSL证书生成 (使用openssl)

- 生成秘钥key(server.csr)

```
openssl genrsa -des3 -out server.key 2048
```

会有两次输入密码, 输入同一个即可. 然后会得到一个server.key文件.

说明: 以后使用此文件(通过openssl命令)可能经常要求输入密码, 如果想去除输入密码的步骤, 可以使用如下的命令, 重新生成一个
server.key以替换原来的文件:

```
openssl rsa -in server.key -out server.key
```

- 创建服务器证书的申请文件 server.csr

```
openssl req -new -key server.key -out server.csr
```

会要求输入以下的内容:
```
C: Country, 单位所在国家，为两位字母的国家缩写,如:CN就是中国
ST: State/Province,单位所在州或省
L: Locality, 单位所在城市或县区
O: Organization, 此网站的单位名称;
OU: Organization Unit, 下属部门名称; 也常常用于显示其他证书相关信息,如证书类型,证书产品名称或身份验证类型或验证内容等;
CN: Common Name, 网站的域名;
EA: Email Address, 网站管理员邮箱.
```

如果不想输入内容, 可以在命令当中指定:
```
openssl req -new -key server.key -out server.csr \
-subj "/C=CN/ST=ZheJiang/L=HangZhou/O=Apache/OU=Web Security/CN=www.test.com"
```

- 创建CA证书(ca.crt, ca.srl)

```
openssl req -new -x509 -key server.key -out ca.crt -days 3650
```

说明: -days <num> 用于指定CA证书的有效时间, 单位是天


- 创建服务器证书(server.crt)

```
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey server.key -CAcreateserial -out server.crt
```

说明: -days <num> 指定证书的有效期.


**注:到目前为止,当前目录一共生成了5个文件, ca.crt ca.srl server.crt server.csr server.key. 其中
`server.crt`, `server.key`是nginx的证书文件**


**简化生成服务器证书版本**
```
1. 生成秘钥server.key和服务器证书申请文件server.csr
openssl req -new -newkey rsa:2048 -sha256 -nodes -out server.csr -keyout server.key \
-subj "/C=CN/ST=ZheJiang/L=HangZhou/O=BroadLink/OU=Web Security/CN=sf.test.com"

2. 生成CA文件ca.crt和ca.srl
openssl req -new -x509 -key server.key -out ca.crt -days 3650 \
-subj "/C=CN/ST=ZheJiang/L=HangZhou/O=BroadLink/OU=Web Security/CN=sf.test.com"

3. 服务器证书server.crt
openssl x509 -req -days 3650 -in server.csr -CA ca.crt -CAkey server.key -CAcreateserial -out server.crt
```


**上面使用openssl参数说明**

```
req, 配置参数
-x509, 指定使用X.509证书签名请求管理(certificate signing request)[CSR]
-nodes, 告诉openssl生产证书时忽略密码环节.
-days <num>, 证书有效时间,单位天
-newkey rsa:2048, 同时产生一个新证书和一个新的SSL key(加密强度为RSA-2048)
-keyout, SSL输出文件名
-out, 证书生成文件名
```

## SSL 相关指令

### ssl_certificate 

给 server 指定一个带有 PEM 格式证书的文件. 

```
ssl_certificate file;
```

作用上下文: http, server

如果除 primary 证书外还应指定 intermediate 证书, 则应按以下顺序在同一文件中指定它们: 首先是 primary 证书, 然后
是 intermediate 证书.

从 1.11.0 版本开始, 可以多次指定该指令以加载不同类型的证书, 例如 RSA 和 ECDSA:

```
server {
    listen              443 ssl;
    server_name         example.com;

    ssl_certificate     example.com.rsa.crt;
    ssl_certificate_key example.com.rsa.key;

    ssl_certificate     example.com.ecdsa.crt;
    ssl_certificate_key example.com.ecdsa.key;

    ...
}
```

### ssl_certificate_key 

给 server 指定一个带有 PEM 格式证书的秘钥文件.
 
```
ssl_certificate_key file;
```

作用上下文: http, server

### ssl_ciphers

指定加密算法. 以 OpenSSL 库理解的格式指定.

```
ssl_ciphers ciphers;
```

作用上下文: http, server

例如:

```
ssl_ciphers HIGH:!aNULL:!MD5;
```


### ssl_protocols 

启用指定的协议.

```
ssl_protocols [SSLv2] [SSLv3] [TLSv1] [TLSv1.1] [TLSv1.2] [TLSv1.3];
```

作用上下文: http, server

例子:
```
ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
```


### ssl_client_certificate

指定具有 PEM 格式的受信任 CA 证书的文件, 验证 client 证书和 OCSP 响应(ssl_stapling开启状况下)

```
ssl_client_certificate file;
```

作用上下文: http, server

证书列表将发送给 client. 如果不需要, 可以使用 ssl_trusted_certificate 指令.

### ssl_trusted_certificate 

指定具有 PEM 格式的受信任 CA 证书的文件, 验证 client 证书和 OCSP 响应(ssl_stapling开启状况下).

```
ssl_trusted_certificate file;
```

作用上下文: http, server

与 ssl_client_certificate 设置的证书相反，这些证书的列表不会发送给客户端.

### ssl_stapling

启用或禁用 Server OCSP(Online Certificate Status Protocol) 响应 stapling 

```
ssl_stapling on | off;
```

作用上下文: http, server

在启用 OCSP 情况下, 服务器证书颁发者(CA)的证书应该是已知的. 如果 ssl_certificate 文件不包含中间证书,  服务器证书
颁发者(CA)的证书应该配置在 ssl_trusted_certificate 文件当中.

为了解析 OCSP 响应的 hostname, 是需要指定 resolver 指令.

> 默认情况下, ssl_stapling 是关闭的


### ssl_stapling_file

如设置, OCSP 响应将从指定的文件中获取, 而不是去查询 OCSP 响应.  

```
ssl_stapling_file file;
```

作用上下文: http, server

> 该文件应采用 "openssl ocsp" 命令生成的 DER 格式


### ssl_verify_client

启用客户端证书的验证. 验证结果存储在 $ssl_client_verify 变量当中.

```
ssl_verify_client on | off | optional;
```

作用上下文: http, server


## SSL server 配置

```
server { 
    listen       443;
    server_name  localhost;
    
    # 开启SSL
    ssl                     on;
    # 配置证书位置(crt文件)
    ssl_certificate         /root/Lee/keys/server.crt;
    # 配置秘钥位置
    ssl_certificate_key     /root/Lee/keys/server.key;
    
    # 开启双向认证, 以及认证客户端的CA证书(一般是自己私有的CA)
    #ssl_verify_client on;
    #ssl_client_certificate ca.crt;
    
    # ssl session 超时时间
    ssl_session_timeout         5m;
    # ssl 协议
    ssl_protocols               SSLv2 SSLv3 TLSv1;
    # ssl 加密算法
    ssl_ciphers                 ALL:!ADH:!EXPORT56:RC4+RSA:+HIGH:+MEDIUM:+LOW:+SSLv2:+EXP;
    # server 端加密算法优先于客户端加密算法
    ssl_prefer_server_ciphers   on;
    
    # 还有其他的配置 ... 
}
```
