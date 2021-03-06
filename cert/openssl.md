# OpenSSL

OpenSSL是一个加密工具包, 它实现了安全套接字层(SSL v2/v3)和传输层安全性(TLS v1)网络协议以及它们所需的相关加密标准.

openssl程序是一个命令行工具, 用于从shell中使用OpenSSL的加密库的各种加密函数. 它可以用于:

- 创建和管理私钥, 公钥和参数.
- 公钥加密操作
- 创建X.509证书, CSR和CRL
- 消息摘要的计算
- 使用密码加密和解密
- SSL/TLS客户端和服务器测试
- 处理S/MIME签名或加密邮件
- 时间戳请求,生成和验证

## openssl使用

```
openssl command [ COMMAND_OPTS ] [ COMMAND_ARGS ]

openssl [ list-standard-commands
          list-message-digest-commands
          list-cipher-commands
          list-cipher-algorithms
          list-message-digest-algorithms
          list-public-key-algorithms
        ]
```

openssl程序提供了丰富的命令(上面的概要中的命令), 每个命令通常都有丰富的选项和参数(概要中的command_opts和command_args).

命令list-standard-commands, list-message-digest-commands和list-cipher-commands分别输出所有标准命令,
消息摘要命令或密码命令的名称列表(每行一个条目), 在本openssl实用程序中可用.

命令list-cipher-algorithms 和 list-message-digest-algorithms列出所有密码和消息摘要名称, 每行一个条目. 别名列为:
from => to

命令 list-public-key-algorithms 列出了所有支持的公钥算法.

命令 no-XXX 测试指定名称的命令是否可用. 如果不存在名为XXX的命令, 则返回0(成功)并打印no-XXX; 否则返回1并打印XXX. 
在这两种情况下, 输出都转到stdout, 并且没有任何内容打印到stderr. 始终忽略其他命令行参数. 因为对于每个密码, 都有一个相同
名称的命令, 这为shell脚本提供了一种简单的方法来测试openssl程序中密码的可用性. (no-XXX无法检测伪命令, 例如 quit, 
list-...-commands 或 no-XXX本身)


### STANDARD COMMANDS

- ciphers, Cipher Suite Description(密码套件描述列表, 查询)

- cms, CMS(Cryptographic Message Syntax) (加密消息语法)

- clr, CLR(Certificate Revocation List) Management (证书撤销)

- dgst, Message Digest Calculation

- ec, EC(Elliptic Curve) key processing (椭圆曲线)

- enc, Encoding with Ciphers


- gendh, 生成DH秘钥

参数:
```
openssl gendh [args] [numbits]
-out file, key的文件
numbits, 大质数的位数
```

- dsaparam, 生成DSA的参数文件

参数:
```
openssl dsaparam [args] [bits] 

-inform arg, input格式, DER,PEM
-outform arg, output格式, DER,PEM
-in file, input文件
-out file, output文件
-C, 输出C代码
-genkey, 生成一个DSA的key.(如果指定此参数, out当中包含了parameters和private key, 否则out中只有parameters)
bits, 生成private key的长度
```

- gendsa, 生成DSA秘钥

参数:
```
openssl gendsa [args] dsaparam-file

-out file, 秘钥文件,PEM格式

-des, 在cbc模式下使用DES加密生成的密钥(带密码)
-des3, 在ede cbc模式下使用DES加密生成的密钥(带密码)
-seed, 在cbc模式下使用SEED加密秘钥文件(带密码)
-aes128,-aes192,-aes256, 在cbc aes模式下使用AES加密秘钥文件(带密码)

dsaparam-file, 使用dsaparam生成的文件
```

- genrsa, 生成RSA秘钥

参数:
```
openssl genrsa [args] [bits]

-out file, 秘钥文件,PEM格式

-des, 在cbc模式下使用DES加密生成的密钥(带密码)
-des3, 在ede cbc模式下使用DES加密生成的密钥(带密码)
-seed, 在cbc模式下使用SEED加密秘钥文件(带密码)
-aes128,-aes192,-aes256, 在cbc aes模式下使用AES加密秘钥文件(带密码)

bits, 秘钥位数
```

- genpkey, 生成秘钥

参数:
```
openssl genpkey [args]

-out file, 秘钥文件
-outform arg, output格式, DER或PEM

-<cipher> 使用<cipher>算法加密私钥(带密码), 例如des, des3, aes128, aes192, aes256, seed等
-algorithm alg, 公钥的算法, rsa, dsa, dh, ecc等
-paramfile file, 参数文件, dsa就需要参数文件
```

- req  PKCS#10 X.509 Certificate Signing Request (CSR, 证书签名请求) Management.

参数:
```
openssl req [arg]

-outform arg    输出格式(DER, PEM)
-out arg        输出文件

# 输出格式控制
-text          以文本格式输出REQ
-noout         不输出REQ
-x509          输出以x509结构代替的cert. req.

注意事项:
    当只有-text参数, 表示打印REQ
    当只有-noout参数, 表示不输入任何内容
    当同时具有-text和-noout参数, 只是打印REQ的Certificate Request部分. REQ是由(Certificate Request, 证书结构
    体格式; CERTIFICATE REQUEST, 证书请求base64编码的格式)

-pubkey        输出证书的公钥(默认是没有的)
-subject       输出证书请求的subject(默认在是没有的)


# 加密密码控制
-nodes         不需要加密的密码(默认是需要设置加密的密码)

-key fike      使用文件当中的私钥(如果私有有加密密码, 需要输入加密密码; 否则不需要任何密码)
-keyform arg   key文件的格式

-newkey rsa:bits  生成一个加密的RSA私钥文件, 并使用该私钥加密证书请求
-newkey das:file  生成一个加密的DSA私有文件, 并使用该私钥加密证书请求
-newkey ec:file   生成一个加密的DSA私有文件, 并使用该私钥加密证书请求


注意事项:
    -nodes  不设置加密的密码
    -key    通过外部的私有key文件设置加密的密码


-new           new request(必须参数)
-verify        验证REQ上的签名
-days          -x509生成的证书有效的天数.

-config file   证书请求的配置文件.
```

- ca, CA (Certificate Authority) Management.

参数:
```
openssl ca [args]

# 必要的参数
-in file       输入PEM证书请求文件(csr)

-keyfile file  私钥文件(CA自己的)
-keyform arg   私钥格式(PEM, DER)
-key arg       如果私钥文件是加密的, 此值是解密密码

-cert file     CA自己的证书(crt)

-out file      输出PEM证书文件(crt)

# 其他参数
-config file   配置文件, 默认为/usr/lib/ssl/openssl.cnf
-gencrl        生成一个新的CRL
-days arg      证书有效的天数
-md arg        md2, md5, sha, sha1 签名算法

-selfsign      使用与之关联的密钥签署证书
-subj arg      使用arg替代请求的subject
-utf8          输入字符集是UTF8(默认是ASCII)
```

- x509, X.509 Certificate Data Management

参数:
```
-inform arg
-outform arg 
-CAform arg
-CAkeyform arg

-in arg
-out arg 
-CA arg
-CAkey arg

-passin arg         私钥密码
-pubkey             输出公钥
-alias              输出证书的alias
-noout              不输出任何内容
-trustout           输出"trusted"证书

-days arg           证书的有效时间, 默认是30天
-signkey arg        使用arg自签名证书
-x509toreq          输出证书请求对象
-req                输入一个证书请求, 签名, 并输出
```