# Algorithm

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