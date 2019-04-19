# SSL 证书解读

## 证书标准

X.509, 一种证书的标准, 定义了证书中包含的内容.


## 编码格式

同样的X.509证书, 可能有不同的编码格式, 目前有以下两种编码格式:

- PEM (Privacy Enhanced Mail), 文本格式, 以"----BEGIN..."开头, "----END..."结尾,
内容是 **BASE64** 编码

Apache, *NIX 服务器使用

信息查看: openssl x509 -in certificate.pem -txt -noout

- DER (Distinguished Encoding Rules), 二进制格式, 不可读.

Java 和 Windows 服务器使用

信息查看: openssl x509 -in certificate.der **-inform** -txt -noout


## 相关的文件扩展名

- CRT, 证书, **只保存证书,不保存私钥**, 常见 *NIX 系统, 可能是PEM编码, 也可能是DER编码

- CER, 证书, **只保存证书,不保存私钥**, 常见于 Windows 系统, 可能是PEM编码, 也可能是DER编码, 大多数是DER编码

- PFX/P12, predecessor of PKCS#12, **同时包含证书和私钥, 一般有密码保护**. 对 *NIX 服务器来说, 
一般CRT和KEY是分开存放在不同的文件中, 但是Windows的IIS则将它们存在一个PFX文件中. PFX通常会有一个"提取
密码". PFX使用的是DER编码.


从pfx当中提取 **证书**, **私钥**, **公钥**:

```bash
# certificate: pfx -> pem
openssl pkcs12 -in certificate.pfx -nodes -out cert.pem 

# private key
openssl pkcs12 -in certificate.pfx -nocerts -out key.pem

# public key
openssl pkcs12 -in certificate.pfx -clcerts -nokeys -out key.pem
```

- JKS, Java Key Storage, **同时包含证书和私钥, 一般有密码保护**, keytool工具可以将PFX转为JKS, keytool
也能直接生成JKS

从jks当中提取  **证书**, **私钥**, **公钥**:

```bash
# jks -> p12
keytool -importkeystore \
    -srckeystore keystore.jks \
    -destkeystore keystore.p12 \
    -deststoretype PKCS12 \
    -srcalias <jkskeyalias> \
    -deststorepass <password> \
    -destkeypass <password> 

# export certificate: p12 -> pem 
openssl pkcs12 -in keystore.p12  -nokeys -out crt.pem

# export private key
openssl pkcs12 -in keystore.p12  -nodes -nocerts -out key.pem

# export public key
keytool -export \
    -keystore keystore.jks \
    -alias <jkskeyalias> \
    -file key.pem
```


- KEY, 公钥或者私钥, 并非X.509证书, 可能是PEM编码, 也可能是DER编码

查看方法: openssl rsa -in mykey.key -text -noout
        openssl rsa -in mykey.key -text -noout -inform der


- CSR, 证书签名请求(Certificate Signing Request), 这个并不是证书, 而是向 **CA** 获得签名证书的
申请. **核心内容是一个公钥**(当然还附带了一些别的信息), 在生成这个申请的时候, 同时也会生成一个私钥, 私钥
要自己保管好.

查看方法: openssl req -text -noout -in my.csr

生成csr文件:

```bash
# key.pem 是私钥, my.csr是证书签名请求
openssl req -newkey rsa:2048 -new -nodes -keyout key.pem -out my.csr
```
