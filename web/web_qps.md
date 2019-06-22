# QPS 相关概念

## 响应时间 (RT)

**`响应时间`** 是指`系统对请求作出响应的时间`. 直观上看, 这个指标与人对软件性能的主观感受是非常一致的, 因为它完整地记录了
整个计算机系统处理请求的时间. 由于一个系统通常会提供许多功能, 而不同功能的处理逻辑也千差万别, 因而不同功能的响应时间也不尽
相同, 甚至同一功能在不同输入数据的情况下响应时间也不相同. **因此**, 在讨论一个系统的响应时间时, 人们通常是指该系统所有功
能的平均时间或者所有功能的最大响应时间. 当然, 往往也需要对每个或每组功能讨论其平均响应时间和最大响应时间.


## 吞吐量 (TPS)

**`吞吐量`** 是指`系统在单位时间内处理请求的数量`. 对于**无并发的系统**, 吞吐量与响应时间成严格的反比关系, 实际上此时
吞吐量就是响应时间的倒数. 前面已经说过, 对于单用户的系统, 响应时间(或者系统响应时间和应用延迟时间)可以很好地度量系统的性
能, 但对于**并发系统**, 通常需要用吞吐量作为性能指标.

> 说明:
> 对于一个多用户的系统, 如果只有一个用户使用时系统的平均响应时间是T, 当有N个用户使用时, 每个用户看到的响应时间通常并不是
> NxT, 而往往比NxT小很多(当然, 在某些特殊情况下也可能比N×T大, 甚至大很多). 这是因为处理每个请求需要用到很多资源, 由于
> 每个请求的处理过程中有许多步骤难以并发执行, 这导致在具体的一个时间点, 所占资源往往并不多, 也就是说在处理单个请求时, 在
> 每个时间点都可能有许多资源被闲置, 当处理多个请求时, 如果资源配置合理, 每个用户看到的平均响应时间并不随用户数的增加而线性
> 增加. 实际上, 不同系统的平均响应时间随用户数增加而增长的速度也不大相同, 这也是采用吞吐量来度量并发系统的性能的主要原因. 


> 一般而言, 吞吐量是一个比较通用的指标, 两个具有不同用户数和用户使用模式的系统, 如果其最大吞吐量基本一致, 则可以判断两个系
> 统的处理能力基本一致.


## 并发用户数

**`并发用户数`** 是指`系统可以同时承载的正常使用系统功能的用户的数量`. 与吞吐量相比, 并发用户数是一个更直观但也更笼统的
性能指标.  实际上, 并发用户数是一个非常不准确的指标, 因为用户不同的使用模式会导致不同用户在单位时间发出不同数量的请求.以
网站系统为例, 假设用户只有注册后才能使用, 但是注册的用户并不是每时每刻都在使用该网站, 因此具体一个时刻只有部分注册用户同时
在线, 在线用户就在浏览网站时会花很多时间阅读网站上的信息, 因而具体一个时刻只有部分在线用户同时向系统发出请求. 这样, 对于
网站系统我们会有三个关于用户数的统计数字: 注册用户数、在线用户数和同时发请求用户数. 由于注册用户可能长时间不登陆网站, 使
用注册用户数作为性能指标会造成很大的误差. 而在线用户数和同时发请求用户数都可以作为性能指标. 相比而言, 以在线用户作为性能指
标更直观些, 而以同时发请求用户数作为性能指标更准确些.

## 每秒查询率 (QPS, Query Per Second)

**`每秒查询率QPS`** 是`对一个特定的查询服务器在规定时间内所处理流量多少的衡量标准`, 在因特网上, 作为域名系统服务器的机器
的性能经常用每秒查询率来衡量. 对应fetches/sec, 即每秒的响应请求数, 也即是最大吞吐能力. (看来是类似于TPS, 只是应用于特
定场景的吞吐量)


---


# 计算公式

## QPS

每秒查询率(QPS), 每秒的响应请求数量, 即最大吞吐能力.

QPS = req / sec = 请求数/秒

QPS统计方式\[一般使用 http_load 进行统计]

QPS = 总请求数 / ( 进程总数 * 请求时间 )

QPS: 单个进程每秒请求服务器的成功次数.

**峰值QPS:**

原理: 每天80%的访问集中在20%的时间里,这20%的时间叫做峰值时间

公式: (总PV数 * 80%) / (每天秒数 * 20%) = 峰值时间每秒请求数(QPS)


## PV

访问量即Page View, 即页面浏览量或点击量, 用户每次刷新即被计算一次.

单台服务器每天PV计算:

公式1: 每天总PV = QPS * 3600 * 6

公式2: 每天总PV = QPS * 3600 * 8

## UV

独立访客即Unique View, 访问网站的一台电脑客户端为一个访客. 00:00-24:00 内相同的客户端只被计算一次.

## 服务器数量

机器: 峰值时间每秒QPS / 单台机器的QPS = 需要的机器

机器: ceil( 每天总PV / 单台服务器每天总PV )