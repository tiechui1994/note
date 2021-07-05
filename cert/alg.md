# 加密算法与加密工具

## 对称加密

- DES

数据加密标准(Data Encryption Standard, DES), 采用数据加密算法(Data Encryption Algorthm, DEA), 这是一种对称加
密算法.

DES的输入分组64位,输出密文64位,秘钥的有效位数是56位, 加上校验位共64位.

- AES

高级加密标准(Advanced Encryption Standard, AES), 又称Rijndael加密法. 美国联邦政府采用的一种区域加密标准.

分组长度和秘钥长度可以被指定为128,192或者256 bit.

AES的加密算法的数据处理单位是字节, 128位的比特信息被分成16个字节, 按顺序复制到一个4x4的矩阵中, 称为状态(state)


- TEA

TEA算法是由剑桥大学计算机实验室的David Wheeler 和 Roger Needhan于1994年发明的.

它是一种分组密码算法,其明文密文块是64比特, 秘钥长度为128比特.

TEA算法利用不断增加的Delta(黄金分割率)值作为变化,使得每轮的加密都不同, 该算法的迭代次数可以改变,建议的迭代次数为32轮.

## 非对称加密

- RSA 

RSA, 由 Rivest, Shamir和 Adleman设计的算法. 可以实现非常对称加密.

- DSA/DSS

DSA(用于数字签名算法)的签名生成速度很快, 验证速度很慢, 加密时更慢, 但解密时速度很快, 安全性与RSA密钥相等, 而密钥长度相
等.

- DH

DH秘钥交换. 离散对数基础: F(a)=g^a mod N, N是大质数(一般是1024位以上), g是比较小的质数. 已知g,a,N可以很容易得到
F(a), 但是从F(a),g,N推到a是一件很困难的事情.

基于离散对数的D-H秘钥交换流程:
1)客户端生成质数N和g
2)客户端生成随机因子a
3)客户端计算A=F(a)
4)客户端发生g,N,A到服务器
5)服务器生成随机因子b
6)服务器计算B=F(b)
7)服务发送B给客户端
8)服务器计算key=A^b mod N
9)客户端计算key=B^a mod N
10)双方通过交换(g,N,A)和B达到了交换key的效果, 随机因子a和b在D-H交换之后被客户端与服务器丢弃.

- ECC

椭圆曲线加密.

## 签名

- MD5

MD5, 即Message-Digest Algorithm 5的简称, 当前计算机领域用于确保信息传输完整一致而广泛使用的散列算法之一.

- SHA

SHA, 即Secure Hash Algorithm, 是一种能计算出一个数字信息所对应到的, 长度固定的字符串的算法. SHA家族的5个算法, 分别
是SHA-1, SHA-224, SHA-256, SHA-384, SHA-512.

## GPG 

PGP(Pretty Good Privacy)是一个用于数据加密和数字签名的程序, 由于被广泛应用以至于后来形成了开发的标准OpenPGP.

GnuPG, GnuPG是一个集钥匙管理, 加密解密, 数字签名于一身的工具.

### 加密和数字签名的简单原理

首先, 每个人使用程序生成地球上唯一的一对秘钥, 分别称为公钥和私钥. 公钥用于加密, 私钥用于解密. 使用公钥加密的信息只能由配
对的私钥解开.

加密的过程: 如果A要发送信息给B, 首先B把自己的公钥公布出来, A获得B的公钥后加密信息并发送给B, B收到(加密的)信息后,使用自
己的私钥就可以还原信息了.

数字签名过程: 信息是通过未加密方式发送信息给对方的, 只是在每条信息后面都会附加一串字符(签名), 这个签名是由程序根据发送者
的私钥以及信息内容计算得出, 接收者使用发送者的公钥就可以核对信息有无篡改.

### GnuPG使用

GnuPG支持的算法:
Pubkey: RSA, ELG, DSA, ECDH, ECDSA, EDDSA
Cipher: IDEA, 3DES, CAST5, BLOWFISH, AES, AES192, AES256, TWOFISH,
        CAMELLIA128, CAMELLIA192, CAMELLIA256
Hash: SHA1, RIPEMD160, SHA256, SHA384, SHA512, SHA224
Compression: Uncompressed, ZIP, ZLIB, BZIP2


Pubkey, 非对称加密
Cipher, 对称加密
Hash, 数字签名
Compression, 压缩

## OpenSSL

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

### openssl使用

```
openssl command [ COMMAND_OPTS ] [ COMMAND_ARGS ]
```

openssl程序提供了丰富的命令(上面的概要中的命令), 每个命令通常都有丰富的选项和参数(概要中的command_opts和command_args).


**command**

- `ciphers`, Cipher Suite Description(密码套件描述列表, 查询)

- `cms`, CMS(Cryptographic Message Syntax) (加密消息语法)

- `clr`, CLR(Certificate Revocation List) Management (证书撤销)

- `dgst`, Message Digest Calculation

- `ec`, EC(Elliptic Curve) key processing (椭圆曲线)

- `enc`, Encoding with Ciphers


- `gendh`, 生成 DH key
```
openssl gendh [args] [numbits]
-out file, key的文件
numbits, 大质数的位数
```

- `dsaparam`, 生成DSA的参数文件
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

- `gendsa`, 生成DSA秘钥
```
openssl gendsa [args] dsaparam-file

-out file, 秘钥文件,PEM格式

-des, 在cbc模式下使用DES加密生成的密钥(带密码)
-des3, 在ede cbc模式下使用DES加密生成的密钥(带密码)
-seed, 在cbc模式下使用SEED加密秘钥文件(带密码)
-aes128,-aes192,-aes256, 在cbc aes模式下使用AES加密秘钥文件(带密码)

dsaparam-file, 使用dsaparam生成的文件
```

- `genrsa`, 生成RSA秘钥
```
openssl genrsa [args] [bits]

-out file, 秘钥文件,PEM格式

-des, 在cbc模式下使用DES加密生成的密钥(带密码)
-des3, 在ede cbc模式下使用DES加密生成的密钥(带密码)
-seed, 在cbc模式下使用SEED加密秘钥文件(带密码)
-aes128,-aes192,-aes256, 在cbc aes模式下使用AES加密秘钥文件(带密码)

bits, 秘钥位数
```

- `genpkey`, 生成秘钥
```
openssl genpkey [args]

-out file, 秘钥文件
-outform arg, output格式, DER或PEM

-<cipher> 使用<cipher>算法加密私钥(带密码), 例如des, des3, aes128, aes192, aes256, seed等
-algorithm alg, 公钥的算法, rsa, dsa, dh, ecc等
-paramfile file, 参数文件, dsa就需要参数文件
```

- `req`  PKCS#10 X.509 Certificate Signing Request (CSR, 证书签名请求) Management.
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

- `ca`, CA (Certificate Authority) Management. 一般是进行签名或自签名
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

- `x509`, X.509 Certificate Data Management. x509 证书数据转换 
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
