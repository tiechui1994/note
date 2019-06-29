# GnuPG(GPG)加密信息及数字签名

PGP(Pretty Good Privacy)是一个用于数据加密和数字签名的程序, 由于被广泛应用以至于后来形成了开发的标准OpenPGP.

GnuPG, GnuPG是一个集钥匙管理, 加密解密, 数字签名于一身的工具.

## 加密和数字签名的简单原理

首先, 每个人使用程序生成地球上唯一的一对秘钥, 分别称为公钥和私钥. 公钥用于加密, 私钥用于解密. 使用公钥加密的信息只能由配
对的私钥解开.

加密的过程: 如果A要发送信息给B, 首先B把自己的公钥公布出来, A获得B的公钥后加密信息并发送给B, B收到(加密的)信息后,使用自
己的私钥就可以还原信息了.

数字签名过程: 信息是通过未加密方式发送信息给对方的, 只是在每条信息后面都会附加一串字符(签名), 这个签名是由程序根据发送者
的私钥以及信息内容计算得出, 接收者使用发送者的公钥就可以核对信息有无篡改.

## GnuPG使用

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

