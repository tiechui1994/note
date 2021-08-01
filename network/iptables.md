# iptables 

## 介绍

**netfilter/iptables包过滤系统** 是由 netfilter 和 iptables 两个组件组成. netfilter工作在内核空间, 由包
过滤表组成, 这些表包含内核用来控制包过滤处理的规则集; iptables工作在用户空间, 是主要配置工具, iptables 让插入,
修改和删除包过滤表中的规则变得容易.

## 工作机制

规则链名包括(也被称为五个钩子函数(hook functions)):

- INPUT链: 处理输入数据包.
- OUTPUT链: 处理输出数据包.
- FORWARD链: 处理转发数据包.
- PREROUTING链: 用于目标地址转换(DNAT).
- POSTROUTING链: 用于源地址转换(SNAT).

## 防火墙的策略

防火墙策略一般分为两种, 一种是通策略, 一种是堵策略. 通策略, 默认门是关着的, 必须定义谁能进. 堵策略, 大门是打
开的, 但是必须有身份认证, 否则不能进入. 

当我们定义策略的时候, 要分别定义多条功能, 其中: 定义数据包运行或者不允许的策略, filter过滤的功能, 而定义地址
转换的功能则是NAT选项. 为了让这些功能交替工作, 制定出了"表"的定义, 来定义, 区分各种不同工作功能和处理方式.

常用的功能:

- filter, 定义允许或者不允许, 作用的链: INPUT, FORWARD, OUTPUT
- nat, 定义地址转换的, 作用的链: PREROUTION, OUTPUT, POSTROUTING
- mangle, 修改报文原始数据, 作用的链: PREROUNTING, INPUT, FORWARD, OUTPUT, POSTROUTING

表名:

- raw: 高级功能, 如: 网址过滤
- mangle: 数据包修改(QOS), 用于实现服务质量
- nat: 地址转换, 用于网关路由器
- filter: 包过滤, 用于防火墙规则

动作包括:

- ACCPET: 接收数据包
- DROP: 丢弃数据包
- REDIRECT: 重定向, 映射, 透明代理
- SNAT: 源地址转换
- DNAT: 目标地址转换
- MASQUERADE: IP伪装(NAT), 用于ADSL
- LOG: 日志记录


**iptables 的网络图**

![image](/images/iptables_table_exe.png)
