# TLS/SSL 证书解读

## 证书标准

X.509, 一种证书的标准, 定义了证书中包含的内容. 下面介绍下 `数字签名`, `数字证书`, `数字证书的颁发形式`, 以及 `系统如
何导入Root CA`

### 数字签名 (Digital Signature)

数字签名, 包含两项主要的工作, 签名(Signing) 和 检验 (Verification). 前者是创建一个数字签名, 后者是验证签名的有效性.

签名过程: 

- 第一步, 发送方采用某种算法对整个消息的内容实施哈希算法, 得到一个哈希值.

- 第二步, 发送方使用自己的 **私钥** 对哈希码进行加密, 加密后得到的密文就是一个数字签名. 该数字签名最终会连同发送方密钥
中公钥(该公钥一般会内嵌于一个数字证书中)附加到原消息上一起发给接收方.


接收方接收之后, 它可以借助这个数字签名验证发送方的真实身份和消息的完整性, 这个过程称为数字签名的验证.

验证过程:

- 第一步, 原消息被提取出来, 通过相同的哈希算法得到一个得到一个哈希值.

- 第二步, 数字签名被提取出来, 采用相同的算法利用 **公钥** 对数字签名进行解密, 得到生成数字签名的那个哈希值. 两个哈希值
进行比较, 如果一致则可以证明数字签名的有效性以及消息本身的完整性.

### 数字证书 (Digital Certificate)

证书, 又称数字证书, 或者公钥证书(Public Key Certificate), 是一种数字签名的声明, 它将公钥的值绑定到持有对应私钥的个
人,设备或服务的标识.

由于大多数普通用途的证书基于 `X.509 V3` 证书标准, 因此有将其称为 `X.509` 证书. `X.509` 证书被广泛地应用于加密和数字
签名, 以提供认证的实现和确保数据的一致性和机密性.

在公钥密码学的角度, `X.509` 证书就是将一个某个密钥对中的公钥与某个主题(Subject)进行绑定的文件. 具体来讲, 和公钥进行绑
定是不仅仅包括相应主题的可辨别名称(DN: Distinguished Name), 可以包含主题相关的其它可选名称, 比如 Email 地址, DNS名
称等.

下面的代码片段体现了一个 `X.509` 证书的大体结构. 

```
Certificate:
   Data:
       Version: V3
       Serial Number: 7829 (0x1e95)
       Signature Algorithm: md5WithRSAEncryption
       Issuer: CN=Root Agency
       Validity   
           Not Before: ‎Thursday, ‎April ‎07, ‎2011 3:37:45 PM
           Not After : ‎Sunday, ‎January ‎01, ‎2040 7:59:59 AM
       Subject: 
           CN = www.artech.com
       Subject Public Key Info:
           Public Key Algorithm: rsaEncryption
           RSA Public Key: (1024 bit)
               Modulus (1024 bit):
                    00:b4:31:98:... 52:7e:41:8f
               Exponent: 65537 (0x10001)
   Signature Algorithm: md5WithRSAEncryption
   93:5f:8f:5f: ... b5:22:68:9f
```

其中包括以下内容:

```
版本号: V3
序列号: 7829
签名算法: md5WithRSAEncryption
颁发者: CN=Root Agency
有效日期: April ‎07, ‎2011 3:37:45 PM到January ‎01, ‎2040 7:59:59 AM
主题信息: CN=www.artech.com
公钥: 00:b4:31:98:… 52:7e:41:8f
公钥算法: rsaEncryption
颁发者的数字签名: 93:5f:8f:5f:… b5:22:68:9f
```

### 数字证书的颁发机制

对于数字证书, 尤其是用于商业用途的数字证书, 也具有相应的官方办法机构, 我们将这样的机构称之为认证权威机构(CA: 
Certification Authority, 简称CA).

从上面给出的数字证书可知, 证书中不仅仅包括 CA 的基本信息, 还包括一个数字签名和签名采用的算法. CA 通过自己的私钥对证书的
数据部分进行签名, 并将此签名连同签名采用的算法置于证书之中. 按照前面介绍的关于数字签名的原理, 如果我们具有 CA 的公钥, 
我们不仅仅可以验证证书的 CA, 也能校验证书的内容是否被篡改. 那么在对证书进行验证的时候, CA 的公钥从何而来呢?

实际上, CA 的公钥也保存在一个数字证书之中, 并存储于一个受信任的证书存储之中. 按照证书代表身份的不同, 可以将其分为两种: 

- 根CA证书(CA Certificate), 代表 CA
- 终端实体证书 (End Entity Certificate), 受 CA 证书信任的实体

> 实际上, CA 证书和终端实体证书并没有本质区别. 除了最顶层的 Root CA, 所有的 CA 证书颁发者是它的上一级 CA, 即上一级的
作为该 CA 证书的 Root CA. CA 的这种层级关系组成了一种信任链(Trust Chain).

为了存储数字证书, 操作系统都有存储相应的 Root CA, 根据目的或者信任范围的不同, 不同的证书被存储于不同的存储区. 在若干证
书存储区中, 有一个被称为 "受信任的根证书颁发机构" (Trusted Root Certificate Authorities) 的存储区, 它里面存储了
所有 CA 证书代表所信任的证书颁发机构. 默认情况下, 对于一个待验证的证书, 如果基于该证书 CA 信任链上的任何一个 CA 在该存
储区中存在一个证书, 那么这个证书就是合法的.


### Linux 系统导入根 Root CA

> 注: 这里 Linux 系统是 Ubuntu 16.04, 其他的 Linux 发行版本需要谨慎.

在进行系统证书导入之前, 先要弄清楚 Linux 系统与系统证书相关的几个文件/目录. 

`/usr/share/ca-certificates`, 这个目录存放了系统内置的证书. 一般在 `mozilla` 目录下, 保存为 `crt`文件.

`/usr/local/share/ca-certificates`, 这个目录是本地的证书.(这个一般是用户的证书, 一般没怎么使用)

`/etc/ca-certificates/update.d`, 这个目录主要存放 hooks 脚本. 在执行 `update-ca-certificates` 命令的使用进
行执行.

`/etc/ca-certificates.conf`, 这个文件是配置系统内置的证书文件名称列表. 所有的文件都是相对于 `/usr/share/ca-certificates`
目录的. 如果以 `!` 开始的行, 表示要取消选择这个证书文件名. 根据这个配置文件最终, 生成 `/etc/ssl/certs/ca-certificates.crt`
文件内容. 使用命令 `dpkg-reconfigure ca-certificates` 可以自动生成此文件, 使用命令 `update-ca-certificates` 
可以根据此文件内容更新 `/etc/ssl/certs/ca-certificates.crt` 文件.

`/etc/ssl/certs`, 这个目录存储的证书 (包括系统内置的证书和用户的生成的证书)

`/etc/ssl/certs/ca-certificates.crt`, 系统内置的证书文件内容的集合 (就是将所有系统内置的证书的文件内容放到一个文件
当中), 在 Go 当中, 就是使用此目录作为系统内置的证书加载文件. 使用 `update-ca-certificates` 可以更新此文件.

`/etc/ssl/private`, 这个目录存储的用户的私钥.

导入系统证书的一般过程:

- 生成一个证书. 可以 Google `如果使用openssl生成证书`.

- 将生成的证书放到 `/usr/share/ca-certificates/mozilla` 目录下, 文件后缀 `.crt`, 文件内容是 `pem` 格式.

- 更新系统证书的配置, 执行 `dpkg-reconfigure ca-certificates` 命令(注意: 要使用 root 权限执行). 这个时候会跳出
来一个弹出框, 第一步选择 `yes`, 第二步将新添加的证书打上星号(新添加的证书是一个空白).

- 更新系统证书文件, 执行 `update-ca-certificates` 命令(注意: 要使用 root 权限执行). 到这里, 就内置了一个自己的系
统证书.

> 注意: 目前 Chrome 浏览器对于自己生成的系统证书, 在进行 ssl 连接的时候还是会发出告警的信息的, 这个需要将自己的系统证
书添加到 Chrome 浏览器的 `chrome://settings/certificates` 当中导入自己生成证书, 以消除告警.

## 编码格式

同样的X.509证书, 可能有不同的编码格式, 目前有以下两种编码格式:

- PEM (Privacy Enhanced Mail), 文本格式, 以"----BEGIN..."开头, "----END..."结尾,
内容是 **BASE64** 编码

> Apache, *NIX 服务器使用

> 信息查看: openssl x509 -inform pem -in certificate.pem

- DER (Distinguished Encoding Rules), 二进制格式, 不可读.

> Java 和 Windows 服务器使用

> 信息查看: openssl x509 -inform der -in certificate.der

## 相关的文件扩展名

- **CRT**, 证书, **只保存证书,不保存私钥**, 常见 `UNIX 系统`, 可能是PEM编码, 也可能是DER编码

- **CER**, 证书, **只保存证书,不保存私钥**, 常见于 `Windows 系统`, 可能是PEM编码, 也可能是DER编码, 大多数是
DER编码

- **PFX/P12**, predecessor of PKCS#12, **同时包含证书和私钥, 一般有密码保护**. 

> 对 *NIX 服务器来说, 一般CRT和KEY是分开存放在不同的文件中, 但是Windows的IIS则将它们存在一个PFX文件中. 
> PFX通常会有一个"提取密码". PFX使用的是DER编码.


从pfx当中提取 **证书**, **私钥**, **公钥**:

```bash
# certificate: pfx -> pem
openssl pkcs12 -in certificate.pfx -nodes -out cert.pem 

# private key
openssl pkcs12 -in certificate.pfx -nocerts -out key.pem

# public key
openssl pkcs12 -in certificate.pfx -clcerts -nokeys -out key.pem
```

- **JKS, Java Key Storage**, **同时包含证书和私钥, 一般有密码保护**, keytool工具可以将 `JKS` 转为 `PFX`, 

keytool 也能直接生成JKS

从jks当中提取  **证书**, **私钥**, **公钥**:

```
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


- **KEY**, 公钥或者私钥, 并非X.509证书, 可能是PEM编码, 也可能是DER编码

> 查看方法: 
> openssl rsa -inform pem -in mykey.key -text
> openssl rsa -inform der -in mykey.key -text  


- **CSR**, 证书签名请求(Certificate Signing Request), 这个并不是证书, 而是向 **CA** 获得签名证书的申请. 
**核心内容是一个公钥** (当然还附带了一些别的信息), 在生成这个申请的时候, 同时也会生成一个私钥, 私钥要自己保管好.

> 查看方法: 
> openssl req -in my.csr -text

生成csr文件:

```bash
# key.pem 是私钥, my.csr是证书签名请求
openssl req -newkey rsa:2048 -new -nodes -keyout key.pem -out my.csr
```

## 生成密钥,证书

- 第一步, 为服务器端和客户端准备公钥, 私钥

```bash
# 生成服务器端私钥
openssl genrsa -out server.key 1024
# 生成服务器端公钥
openssl rsa -in server.key -pubout -out server.pem


# 生成客户端私钥
openssl genrsa -out client.key 1024
# 生成客户端公钥
openssl rsa -in client.key -pubout -out client.pem
```

- 第二步, 生成 CA 证书 (CA机构)

CA (Catificate Authority), 它的作用就是提供证书(即服务器证书, 由域名,公司信息,序列号和签名信息组成), 加
强服务端和客户端之间信息交互的安全性, 以及证书运维相关服务. 任何个体/组织都可以扮演 `CA` 的角色, 只不过难以得
到客户端的信任, 能够受浏览器默认信任的 `CA` 大厂商有很多, 其中 `TOP5` 是 `Symantec, Comodo, Godaddy, 
GolbalSign 和 Digicert`.

```bash
# 生成 CA 私钥
openssl genrsa -out ca.key 4096

# X.509 Certificate Signing Request (CSR) Management. (CA生成证书签名请求)
openssl req -new -key ca.key -out ca.csr

# X.509 Certificate Data Management. (CA自签证书, 10年)
openssl x509 -req -days 3650 -in ca.csr -signkey ca.key -out ca.crt
```

- 第三步, 生成服务器端证书和客户端证书

```bash
# 服务器需要向CA机构申请签名证书, 在签名证书之前依然是创建自己的CSR文件
# 需要输入服务器的相关内容(Country, Provence, City, Organization, Organization Unit, 
# Common Name [服务器名称, server FQDN, 必填], Email, Optional Pwd, Optional company)
openssl req -new -key server.key -out server.csr

# CA机构签名, 需要CA的证书和私钥参与, 最终颁发一个带有CA签名的证书
# ca.crt ca.key 是CA独有的内容
# server.csr server端的签名证书请求
# server.crt 生成的签名证书
openssl x509 -req -days 365 -CA ca.crt -CAkey ca.key -CAcreateserial -set_serial 01 -in server.csr \
-out server.crt
```

## 证书使用

签名操作是 `发送方`(CA机构) 用私钥进行签名, `接受方`(客户端) 用发送方证书(客户端内置的证书)来验证签名;

加密操作是 `发送方`(客户端) 用接受方的证书进行加密, `接受方`(服务器) 用自己的私钥进行解密.

因此, 如果说数字证书是电子商务应用者的网上数字身份证话, 那么证书相应的私钥则可以说是用户的私章或公章.

## TLS/SSL 协议

TLS/SSL 协议分层:

![image](/images/cert_tls_layers.png)

TLS/SSL 协议层主要包含两层: Handshake Layer 和 Record Layer.

Handshake Layer 包含以下的子协议:

- Handshake Protocol, 它允许对等彼此进行身份验证, 并协商密码套件(ciphers)和连接的其他参数. SSL握手协议涉及在客户端
和服务器之间的四组消息. 每组消息通常在单独的TCP段中传输.

- Change Cipher Spec Protocol, 它使先前协商的参数有效, 因此通信变得加密.

- Alert Protocol, 用于传送 Exceptions 并指示可能危害安全性的潜在问题.

- Application Data Protocol, 它获取任意数据(通常是应用程序层数据), 并通过安全通道进行发送.


Record Layer:

底层是堆叠在TCP之上的, 因为它是面向连接的可靠传输层协议. 该层基本上由 TLS Record Protocol组成. 简而言之, Record Protocol
首先将高层协议数据分为214字节或更小的块; 然后有选择地压缩数据, 添加消息身份验证码(MAC), 最后根据cipher spec(经过协商)
对数据加密, 并添加SSL Record头. 

> 注意: 每个块都打包成一个不保留客户端消息边界的结构, 这意味着可以将多个相同类型的消息合并为一个结构.

```
-----------+
  data   --+--------------> 1. Fragment data
-----------+
                            +------------------------+
                            |                        |
                            +------------------------+

                            2. Compress data (generally no compression applied)

                            +------------------------+----+
                            |                        |MAC | Add Message Authentication Code
                            +------------------------+----+

                            3. Encrypt data

                            +-----------------------------+
                            |ciphertext                   |
                            +-----------------------------+

                            4. Add header

                       +----+-----------------------------+
     TLS Record header |    |ciphertext                   | Add a TLS Record header
                       +----+-----------------------------+
```


#### Record Protocol 格式

`TLS Record header` 包含3个域, 共 5 bytes:

- `byte 0`: TLS record type

- `byte 1-2`: TLS version(major/minor)

- `byte 3-4`: Length of data in the record(不包含header本身). 最大支持16K

> TLS record type 的值

```
CHANGE_CIPHER_SPEC 20
ALERT              21
HANDSHAKE          22
APPLICATION_DATA   23
```

#### Handshake Protocol 格式

这部分内容是紧跟在 `TLS Record header` 之后的. 包含3个域.

- `byte 0`: handshake type
- `byte 1-2`: handshake message length
- `byte 3-`: message(不同的 `handshake type` 具有不同的消息格式)

> handshake type 的值

```
HELLO_REQUEST      0
CLIENT_HELLO       1
SERVER_HELLO       2

CERTIFICATE         11
SERVER_KEY_EXCHANGE 12
CERTIFICATE_REQUEST 13
SERVER_DONE         14
CERTIFICATE_VERIFY  15
CLIENT_KEY_EXCHANGE 16

FINISHED            20
```

#### ChangeCipherSpec Protocol 格式

这部分内容是紧跟在 `TLS Record header` 之后的. 包含1个域, 长度是 1 byte.

- `byte 0`: ChangeCipherSpec Layer

#### Alert Protocol 格式

这部分内容是紧跟在 `TLS Record header` 之后的. 包含2个域, 长度是 2 byte.

- `byte 0`: alert severity

- `byte 1`: alert descriptions

> alert severity 的值

```
WARNING 1
FATAL   2
```

> alert descriptions 的值

```
CLOSE_NOTIFY 0

UNEXPECTED_MESSAGE 10

BAD_RECORD_MAC    20
DECRYPTION_FAILED 21
RECORD_OVERFLOW   22

DECOMPRESSION_FAILURE 30

HANDSHAKE_FAILURE     40
NO_CERTIFICATE        41
BAD_CERTIFICATE       42
UNSUPPORT_CERTIFICATE 43
CERTIFICATE_REVOKE    44
CERTIFICATE_EXPIRED   45
CERTIFICATE_UNKNOWN   46
ILLEGAL_PARAMETER     47
UNKNOWN_CA            48
ACCESS_DENIED         49

DECODE_ERROR  50
DECRYPT_ERROR 51

EXPORT_RESTRICTION 60

PROTOCOL_VERSION      70
INSUFFICIENT_SECURITY 71

INTERNAL_ERROR  80

USER_CANCELLED  90

NO_RENEGOTIATION 100
```

## TLS/SSL 过程

关键词:

> - session key: TLS/SSL 最后协商的结果, 用来进行对称加密
>
> - client random: 一个 32B 的序列值, 每次连接来时, 都会动态生成. 即, 每次连接生产的值都会不一样. 因为它包含了 4B
> 的时间戳和 28B的随机数.
>
> - server random: 和 client random一样, 只是由 server 端生成.
>
> - premaster secret: 这是 48B 的 blob 数据. 它能和 client & server random 通过 pseudorandom(PRF) 一起生
> 成 session key.
>
> - cipher suite: 用来定义 TLS 连接用到的算法. 通常有 4 部分:
>
>> 1)秘钥交换算法, (非对称加密算法, ECDHE或RSA)
>>
>> 2)证书签名算法, (RSA)
>>
>> 3)数据加密算法(对称加密算法, AES128-CBC等)
>>
>> 4)数据校验签名(产生hash的函数)
>
> 例如: ECDH-ECDSA-AES256-GCM-SHA384 代表, ECDH 表示使用 ECDH 算法进行秘钥交换, ECDSA 表示证书签名算法, 
> AES256-GCM 对称加密算法, SHA384 数据签名校验.

例子:

> 加密套件

![image](/images/cert_tls_cipher_1.png)

> 证书签名算法

![image](/images/cert_tls_cipher_2.png)

> 秘钥交换算法 (Server)

![image](/images/cert_tls_cipher_3.png)

> 秘钥交换算法 (Client)

![image](/images/cert_tls_cipher_4.png)

---

![image](/images/cert_tls_process.png)

1.客户端发送 ClientHello 信息, 包含了客户端支持的最高 TLS协议版本, random num, cipher suite. 如果客户端使用的
resumed handshake, 那么这里发送的就是 Session ID. 如果客户端还支持 ALPN, 那么它还需要发送它所支持的其他协议, 比
如HTTP/2. 以及其他的扩展数据 Extension (server_name, renegotination_info, supported_versions, key_share
等...)

2.在 server 端进行 ServerHello 阶段, 这里 server 根据 cilent 发送过来的相关信息, 采取不同的策略, 同样还会发送和
client 端匹配的TLS最高版本信息, cipher suite 和 自己产生的 random num. 并且, 这里会产生该次连接独一无二的 
Session ID. 以及其他的扩展数据 Extension ( supported_versions, key_share等...)

3.通过 Certificate 阶段, 会在信息流中加入 public key certification(包含两个证书, 一个是CA的, 一个是服务器的). 
ServerKeyExchange 该阶段, 主要是针对 ECDH 加密方式, 里面包含了 ECDH 的参数.

4.ServerHelloDone 标识 server 阶段处理结束, 该阶段产生的信息发送给 client.

5.clientKeyExchange 阶段时, client 会随机生产一串 pre-master secret 序列, 并且会经由 public key 加密, 然后
发送给 server. 在 ChangeCipherSpec 阶段, 主要是 client 自己, 通过pre-master secret `+` server random-num
`+` client random-num 生成 SessionKey. 这个标志着在 client 端, TLS/SSL 过程已经接近尾声.

6.后面在 server 端进行的 ChangeCipherSpec 和 client 进行的差不多, 通过使用 private key 解密 client 传过来的
pre-master secret, 然后生成 SessionKey. 后面再通过一次验证, 使用 SessionKey 加密 server finished, 发送给 
client, 观察能否成功解密, 来表示最终的 TLS/SSL 完成.

---

> RSA 具体流程

![image](/images/cert_tls_rsa_tls_process.png)


> DH 具体流程

![image](/images/cert_tls_dh_tls_process.png)

---

> DH 算法科普:

原理公式:

![image](/images/cert_tls_dh_formula.png)

为了防止在 DH 参数交换时, 数据过大, DH 使用的是取模数的方式, 这样就能限制传输的值永远在 `[1, p-1]`. 这里, 先说明一
下 DH 算法的基本条件:

- 公有条件: p 和 g 都是已知, 并且公开. 即, 第三方也可以随便获取到.

- 私有条件: a 和 b 是两端自己生成的, 第三方获取不到.

DH 基本流程:

> a, g, p 公共参数

1. 客户端生成随机数a, 计算 A = g^a mod p, 然后把g, p, A 发送给服务器.
 
2. 服务器生成随机数b, 计算 B = g^b mod p, K = A^b mod p, (这里的K就是最终的密钥) 然后把 B 发送给客户端

3. 客户端计算 K = B^a mod p, 到此, 客户端和服务器就产生了相同的密钥 K

> 解析: K = A^b mod p = (g^a mode p)^b mod p = g^ab mod p = (g^b mod p)^a mode p = B^a mod p

而最后的 K 就是我们想要的 pre-master secret. 之后, 就和 RSA 加密算法一致, 加上两边的 random-num 生成 sessionKey.

> 实际的 Server Key Exchange 阶段传递的值也是 p, g, pubkey(上面计算的A)
> 实际的 Client Key Exchange 阶段传递的值也是 pubkey (上面计算的B)

ECDH (Elliptic Curve Diffie-Hellman) 流程:

> 椭圆曲线密码学属于非对称密码学的. 其公私钥计算公式如下:
>
>> - 私钥是一个随机数d, 取值范围在 1,...,n-1, 其中 n 是子群的阶
>> - 公钥是点 H = dG, G是子群的基点
>
> 如果知道私钥 d 和椭圆曲线参数 G, 计算公钥 H 是很容易的, 但是只知道公钥 H 和椭圆曲线参数 G, 计算私钥 d 是非常困难的.

1. 首先客户端和服务器需要使用同一条椭圆曲线, 参数 (p, a, b, G, n, h) 相同. 这里其实就是 tls 当中的 curve  参数

2. 客户端和服务器各自生成公私钥. 客户端生成私钥 dA, 公钥 HA = dAG, 服务器生成私钥 dB, 公钥 HB = dBG

3. 客户端和服务器各自交换公钥 HA 和 HB

4. 客户端计算 S = dAHB, 服务器计算 S = dBHA, 可以推导它们计算的值相同. 推到过程如下:
S = dAHB = dAdBG = dB(dAG) = dBHA

> 实际的 Server Key Exchange 阶段传递的值也是 pubkey, curve
> 实际的 Client Key Exchange 阶段传递的值也是 pubkey


> 小结:
> RSA 和 DH 两者之间的具体区别就在于: RSA会将 premaster secret 显示的传输, 这样有可能会造成私钥泄密引起的安全问题.
> 而 DH 不会将 premaster secret 显示的传输.

## TLS/SSL 中的基本概念

### Forward Secrey

FS(Forward Secrey) 主要是针对 private key 进行描述的. 如果你的 private key 能够用来破解以前通信的 session 内
容, 比如, 通过 private key 破解你的 premaster secret, 得到了 sessionkey, 就可以解密传输内容了. 这种情况就是 
non-forward-secrey. 那如何做到 FS 呢? 使用 DH 加密方式即可. 因为, 最后生成的 sessionKey 和 private key 并没
有直接关系, premaster secret 是通过 `g(ab) mode P` 得到的.

### ALPN

ALPN(Application Layer Protocol Negotiation, 应用层协议协商机制). 在应用层中, HTTP 协议应该是重点. 不过由于
HTTP 版本的问题, 以及现在 HTTP/2 的流行, 为了让 client-server 使用相同的协议二出现了 ALPN. 

- 在 clientHello 阶段, client 会在 message 中, 添加一个 ProtocolNameList 字段. 用来代表它所支持的协议列表.

- server 端在 serverHello 阶段, 处理 client 提供的 ProtocolNameList. 并且选择最高版本的协议, 执行. 将选择信息
添加到 serverHello 内.

### SNI

SNI(Server Name Indication), 该机制的提出意义是, 当有一个 server 同时处理了很多个 host 时. 就相当于, 一个 IP 
映射多个域名, 但是证书只能对一个 3 级域名有效, 所以, 针对于多个 host 来说, server 为了能同时兼顾这些郁闷, 一种简单的
方法就是重定向到指定域名; 如果都想支持的话, 可以多买几个证书. 如果现在一个 IP 服务器下, 搭载了支持多个域名的 server,
并且每个域名都有合法的 CA 证书. 那么 server 怎么判断, 哪一个域名用哪一个证书呢? 这时候, 需要用到 SNI. 相当于在 TLS 
阶段, 将 host 一并发送过去, 然后 server 就知道在 serverHello 阶段该返回啥证书了.

为什么一定要用 SNI ?

我们这里只是建立了 TCP + TLS 连接, 客户端的一些内容, 比如 hostname, 并不能在 TCP 中获得. 而想获得, 就需要在 HTTP
阶段, 获得 client 传过来的 `host` 或 `origin` 字段. 所以, 为了解决这个尴尬的点, 就提出了 SNI.


### Session Resumption

为了提升性能, 减少请求次数, 提出了 Session ID 和 Session Tickets, 将成功进行连接的 session 内容缓存起来.

#### Session ID

Session ID 是 server 讲上一次成功连接的 session 内容存在自己的硬盘里面. 这里, 就不涉及对 session data 的二次加
密. 基本过程是:

1. client 端在 clientHello 阶段, 将 random num, TLS protocol 和 通过 hostname 匹配得到是最新一次的 Session
ID 发送给 server 端 (侧面说明, client 同样需要存储一份 session data).

2. server 接收到 Session ID 之后, 在缓存中查找, 如果找到, 则直接进行 ChangeCipher 阶段, 开始生成 sessionKey.
然后, 返回相同的 Session ID.

那么, 相对于完全的 TLS/SSL 连接来说, 这里只用到了一次 RTT.

![image](/images/cert_tls_sessionid.png)


#### Session Tickets

Session Tickets 和 Session ID 做的是同样的事情. server 将最新一次的 session data 通过 二次加密, 在上一次握手
结束时传递过去, 然后 client 将传递过来的信息保存. 这样, 利不利用缓存的 session data, 这时取决于 client. 如果该次
的 session data 没有过期, 那么 client 就会在 clientHello 阶段将该数据发送过去, server 收到后, 便开始进行解密,
然后, 双方生成 sessionKey, 握手结束.

> Session ID 和 Session Tickets 到底使用哪个? Session ID 节省性能, 而损耗部分空间. Session Tickets 注重的是
> 节省空间, 而损耗部分性能. 两者都能节省一次 RTT 时间.

## TLS/SSL 优化

TLS/SSL主要的性能调优简单包括: 启用 False Start, 选择合适 cipher suite,resumption 等. 另外, 如果你追求 
`fashion`, 那么 HTTP/2 也是个不错的选择.

### 设置 session 缓存

session 缓存设置可以让两次的 RTT, 变为一次, 这相当于快了一倍(不包括密钥计算等). 不同的 server 设置 session 办法
有很多, 这里以 nginx 为例. 在 nginx 中, 支持的 Session ID 的形式, 即在 server 中缓存以前 session 的加密内容.
涉及的字段有两个, `ssl_session_cache` 和 `ssl_session_timeout`.

- ssl_session_cache: 设置 session cache 上限值, 以及是否在多个 worker 之间共享.

- ssl_session_timeout: 设置 session cache 存储的时间.

例子:

```
ssl_session_cache shared:SSL:10m;
ssl_session_timeout 20m;
```

> 表示的含义: session cache 会在不同的 worker 之间分享, 假设 1 MB 只能存储 8000 次握手的信息. 那么 10 MB 一共
> 可以吃存储 80000 次握手信息. 如果超出, 则不会存储. 缓存信息存在是时长为 20 分钟.
> 另外, 你也可以开启 `session ticket`, ST(session ticket) 需要一个 sign 参数, 使用 openssl 创建即可.

```
# 创建 ticket.key
openssl rand 48 > ticket.key

# 在 nginx 中开启
ssl_session_ticket on;
ssl_session_ticket_key ticket.key;
```

### 选择合适的 cipher suite

先说明一下, 证书的内容和加密套件实际没有任何关系. 这主要还是取决于服务器的支持程度以及客户端的支持度. 另外, 如果想要启
用 `False Start`, 这和套件的选择有很大的关系. nginx 中, 主要用到两个指令:

```
ssl_prefer_server_ciphers on;
ssl_ciphers xxx;
```

- ssl_prefer_server_ciphers: 用来告诉客户端, 要按照我提供的加密套件选择.

- ssl_cipher: 具体设置的加密套件内容, 使用 `:` 分隔.


支持性最高的就是使用:

```
# 让浏览器决定使用哪个套件
ssl_ciphers HIGH:!aNULL:!MD5;
```

一般情况, 还是应该自己来决定使用哪个套件, 这样安全不安全由自己说了算.  这里简单放一个, 比较安全的, 下面所有的套件都必
须支持 Forward Secrey.

```
ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DH+3DES:!ADH:!AECDH:!MD5;
```

不过, 以下的加密套件, 最好不要使用, 因为基本上都不安全:

- aNULL: 是一种非标准的 DH 密钥交换套件. 容易被 `中间人` 攻击.

- eNULL: 没有加密方式, 明文交换

- EXPORT: 一种弱加密方式.

- RC4: 使用已经废弃的 ARCFOUR 算法

- DES: 使用已经废弃的 Data Encryption 标准

- SSLv2: 老版本 SSL2.0 的加密套件

- MD5: 直接使用 MD5 加密方式.


### False Start

另外, 怎么在 nginx 中开启 False Start 呢? 这其实和服务器并没有多大的关系, 关键还是你选择的套件和 NPN/ALPN 协议的
作用.

- 首先, 加密套件必须具有 Forward Secrey, 否则开不了.

- 浏览器需要使用 NPN 或者 ALPN 告诉服务器, 该所需的协议版本, 然后再决定开不开启.

那么, nginx中, 我们只要选择好合适的加密套件即可. 这里一份现成的:

```
ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256::DES-CBC3-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!MD5;
```

**使用 DH 密钥交换**

DH 的加密过程, 上面已经说过了. DH自带两个公共的参数, 所以, 这必须手动进行创建.

```
# 创建 DH 参数
openssl dhparam 2048 -out dhparam.pem
```

然后, 调用该文件

```
# nginx
ssl_dhparam dhparam.pem;
```

这样, 就正式的开启的 DH 加密模式. 抓包观察结果 (DH在ServerHello):

![image](/images/cert_tls_dh_server_key_exchange.png)

由于历史原因, DH param 已经使用的长度是 1024, 比如: 采用 `0akley group 2` 版本. 现在, 比较流行的 DH 加密方式
是 `ECDH`, 它和以前的加密方式 (`DHE`) 比起来, 在密钥生成这块会快很多. 同样, 由于历史原因, 它的基本条件比较高.

### 使用 SNI

SNI 就是针对一个 IP 手握很多个证书时, 用到的协议机制. 这里主要是用来区分, 不同的 host, 使用不同的证书. 主要使用格式
就是不同的 server_name 搭配不同的 certificate.

```
server {
    server_name www.abc.com;
    ssl_certificate abc.crt;
    ssl_certificate_key abc.crt.key;
}

server {
    server_name www.xyz.com;
    ssl_certificate xyz.crt;
    ssl_certificate_key xyz.crt.key;
}
```

如何开启呢? 换个高版本的 nginx. 使用 `nginx -V` 检查 nginx 是否带有

```
TLS SNI support enabled
```

完整的示例:

```
server {
    listen 443 ssl http2; # 默认打开 http2
    listen [::]:443 ssl http2;
    
    # certificate
    ssl_certificate /ssl/cert/example.com.crt; // 证书
    ssl_certificate_key /ssl/cert/example.com.key; // 私钥
    
    # 客户端证书验证
    ssl_client_certificate /ssl/ca/client.crt; // 颁发客户端证书CA的证书, 一般都是自建的CA证书
    ssl_verify_client on;
    
    # session 缓存
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 20m;
    
    # ssl ciphers
    ssl_prefer_server_ciphers on; // 优先采取服务器算法
    ssl_ciphers ECDH+AESGCM:ECDH+AES256:ECDH+AES128:DH+3DES:!ADH:!AECDH:!MD5;
    
    # DH 算法
    ssl_dhparam /etc/nginx/cert/dhparam.pem;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
}
```

