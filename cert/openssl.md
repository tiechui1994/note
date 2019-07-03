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

- ca, CA (Certificate Authority) Management.

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

