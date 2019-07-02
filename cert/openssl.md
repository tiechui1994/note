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

- dh, Diffie-Hellman Parameter Manage

- dhparam, Generation and Management of Diffie-Hellman Parameters. 支持genpkey和pkeyparam

- dsa, DSA Data Management

- ec, EC(Elliptic Curve) key processing (椭圆曲线)

- enc, Encoding with Ciphers

- gendh, 

- gendsa

- genrsa

- genpkey, Generation of Private Key or Parameters