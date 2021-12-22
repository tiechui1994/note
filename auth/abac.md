# ABAC (基于属性的访问控制)

ABAC (Attribute-Based Access Control), 基于属性的访问控制, 也称为基于策略的访问控制(PBAC), 定义了访问控制范例, 
通过组合属性的策略向用户授予访问权限. 策略可以使用任何类型的属性(用户属性, 资源属性, 对象, 环境属性等). 此模型支持布尔逻
辑, 其中的规则可以包含有"IF,THEN"语句. 例如: 如果请求者是管理员, 则允许对敏感数据进行读/写访问.

与基于角色的访问控制(RBAC)不同, 后者使用预定义的角色, 这些角色带有与之关联的权限(Privilege)集合以及分配的主体(Subject),
与ABAC的关键区别在于策略的概念, 它表示可以计算许多 `不同属性的复杂布尔规则集`. 属性值可以是设定值或原子值. 设定值属性包含
多个原子值. 例如role和project. 原子值属性仅包含一个原子值. 例如清除率和敏感度. 可以将属性的静态值互相比较, 从而实现基于
关系的访问控制.

## 维度

- 外部授权管理 (EAM)
- 动态授权管理 (DAM)
- 基于策略的访问控制 (PBAC)
- 细粒度授权 (Fine-Grained Authorization, FGA)

## 组件

### 架构

ABAC推荐的架构如下:

PEP(Policy Enforcement Point 策略执行点): 它负责保护要使用ABAC的 `application` 和 `data`.  PEP检查请求并从中
发出一个授权请求, 并将其发送给PDP.

PDP(Policy Decision Point 策略决策点) 是架构的核心. 根据已配置的策略计算传入请求. PDP返回**许可/拒绝** 决策. PDP
还可以使用PIP来检索丢失的元数据.

PIP(Policy Information Point 策略信息点) 将PDP连接到外部属性源, 例如: LDAP(轻量目录访问协议)或数据库.

### 属性

属性可以是anything和anyone. 它们往往分为4个不同的类别或功能(如语法功能):

- Subject属性: 描述尝试访问的用户的属性. 例如: 年龄,清关,部门,角色, 职称等
- Action属性: 描述正在尝试的动作的属性, 例如: 阅读,删除,查看,批准等
- Object属性: 描述被访问的对象(或资源)的属性, 例如: 对象类型(病历, 银行账户等),部门, 分类, 位置等
- Contxt(环境)属性: 处理访问控制方案的时间,位置或动态方面的属性

### 策略

策略是将属性汇集在一起以表达允许和不允许的内容的语句. ABAC中的策略可以是授予或拒绝. 策略也可以是
本地策略或全局策略, 并且策略之间可以进行覆盖. 例如:

```
如果文档与用户位于同一部门, 则用户可以查看文档. 
如果用户是文档的owner, 并且文档处于草稿模式, 则用户可以编辑文档.
拒绝在上午9点之前访问.
```

使用ABAC, 你可以拥有任意数量的策略以满足许多不同的场景和技术.

## 应用

ABAC的概念可以应用于 `技术栈和企业基础架构` 的任何级别. 例如, ABAC可用于防火墙, 服务器, 应用程序, 数据库和数据层,
属性的使用带来了额外的上下文来计算任何访问请求的合法性, 并决定 `授予或拒绝` 访问.

评估ABAC解决方案时, 一个重要的考虑因素是了解其在性能方面的潜在开销及其对用户体验的影响. 预计控件越精细, 开销越高.

### API和微服务安全

ABAC可用于将基于属性的细粒度授权应用于API方法或函数. 例如, 银行API可以公开approveTransaction(transId)方法. 
ABAC可用于安全调用. 使用ABAC, 策略author需要编写以下内容:

```
Policy: 经理可以批准交易达到其批准限额
Attribute: 角色, 操作ID, 对象类型, 金额, 批准限制.
```

流程如下:

```
1. 用户Alice调用API方法approveTransaction(123)
2. API接收请求并对用户进行身份验证.
3. API中的拦截器调用授权引擎(通常称为策略决策点, PDP)并求解问题: Alice可以批准事务123吗?
3. PDP检索ABAC策略和必要的属性.
4. PDP做出一个决定, 例如允许或拒绝并将其结果返回给API拦截器.
5. 如果决定是Permit, 则调用底层API业务逻辑. 否则, API会返回错误或拒绝访问.
```

### 应用安全

ABAC的主要优点之一是授权策略和属性可以 `以技术中立的方式` 进行定义. 这意味着在应用程序层面可以对于API和数据库定义
的策略是进行复用. 常见应用程序是:

```
内容管理系统
ERP
自行开发的应用程序
网络应用
```

与API部分中描述的过程和流程相同的过程和流程也适用于此.

### 数据库安全

使用ABAC, 可以定义适用于多个数据库的策略. 这称为动态数据匹配.

案例:

```
Policy: 经理可以查看其所在地区的交易
Reworked: 
    用户 -> role==manager
    操作 -> action==SELECT 
    对象 -> table==TRANSACTIONS
    条件 -> if user.region == transaction.region
```

## 案例

产品部的Dinao可以以作家的身份在2017-12-01到2017-12-31时间段内创建和更新来自台湾地区的草稿模式下的
技术和软件类别的文章.

```
Subject:
    Name: Dino
    Department: Product
    Role: Writer
Action:
    - create
    - update
Resource:
    Type: Article
    Tag:
        - technology
        - software
    Mode:
        - draft
Contextual:
    Location: Taiwan
    StartTime: 2017-12-01
    EndTime: 2017-12-31
```