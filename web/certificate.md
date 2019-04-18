# SSL 证书解读

**证书标准**

X.509, 一种证书的标准, 定义了证书中包含的内容.


**编码格式**

同样的X.509证书, 可能有不同的编码格式, 目前有以下两种编码格式:

- PEM (Privacy Enhanced Mail), 文本格式, 以"----BEGIN..."开头, "----END..."结尾,
内容是 **BASE64** 编码

Apache, *NIX 服务器使用

信息查看: openssl x509 -in certificate.pem -txt -noout

- DER (Distinguished Encoding Rules), 二进制格式, 不可读.

Java 和 Windows 服务器使用

信息查看: openssl x509 -in certificate.der **-inform** -txt -noout

**相关的文件扩展名**

- CRT, 证书, 常见 *NIX 系统, 可能是PEM编码, 也可能是DER编码

- CER, 证书, 常见于 Windows 系统, 可能是PEM编码, 也可能是DER编码, 大多数是DER编码

- KEY, 公钥或者私钥, 并非X.509证书, 可能是PEM编码, 也可能是DER编码

查看方法: openssl rsa -in mykey.key -text -noout
        openssl rsa -in mykey.key -text -noout -inform der

- CSR, 证书签名请求(Certificate Signing Request), 这个并不是证书

查看方法: openssl req -text -noout -in my.csr

- PFX/P12, predecessor of PKCS#12, 对 *NIX 服务器来说, 一般CRT和KEY是分开存放在不同的文件中, 
但是Windows的IIS则将它们存在一个PFX文件中.  PFX通常会有一个"提取密码". PFX使用的是DER编码

PFX -> PEM: openssl pkcs12 -in iis.pfx -out iis.pem -nodes

- JKS, Java Key Storage, JAVA专利, keytool工具可以将PFX转为JKS, keytool也能直接生成JKS
