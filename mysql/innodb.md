# InnoDB 存储引擎

## InnoDB 与 ACID

- 原子性(A)

"原子性"方面涉及到 InnoDB 事务, 相关的 MySQL 功能: 

1) `autocommit`的设置
2) `COMMIT` 语句
3) `ROLLBACK` 语句

- 一致性(C)

"一致性"方面主要涉及 InnoDB 内部处理, 以防止数据崩溃. 相关 MySQL 功能:

1) InnoDB `doublewrite buffer`
2) InnoDB `crash recovery`

- 隔离性(I)

"隔离性"方面涉及到 InnoDB 事务, 尤其是适合于每个事务的隔离级别. 相关 MySQL 功能:

1) `autocommit` 设置
2) 事务隔离级别设置和 `SET TRANSACTION` 语句.
3) InnoDB 锁

- 持久性(D)

相关的 MySQL 功能:

1) InnoDB `doublewrite buffer`
2) `innodb_flush_log_at_trx_commit` 变量
3) `sync_binlog` 变量
4) `innodb_file_per_table` 变量
5) 存储设备的写缓存区.
6) 用于运行 MySQL 的 OS, 特别是对 `fsync()` 系统调用的支持.
7) 备份策略
8) MySQL 集群, 以及集群之间的网络

## Multi-Version

InnoDB 是一个 multi-version 存储引擎. 保存了修改 row 的旧版本的信息, 以支持事务的并发和回滚功能. 这些信息以 `rollback
segment`的数据结构存储在 system tablespace 或 undo tablespace当中. InnoDB 使用 `rollback segment` 当中的信息
来执行事务的回滚所需撤销的操作, 或为 `consistent read` 构建 row 的早期版本.

InnoDB 会为存储在数据库当中的 row 添加3个字段:

- DB_TRX_ID, 长度是 6byte, 表示插入或更新 row 的最后一个事务标识符. '删除' 在 InnoDB 内部当中被视为更新, row 设置
特殊的标记位表示已删除.

- DB_ROLL_PTR, 长度是 7byte, 表示回滚指针. 回滚指针指向写入 `rollback segment` 的 undo log 记录. 如果 row 被
更新, undo log 记录包含在更新重建该行内容所需的信息.(可以构建更新前的行)

- DB_ROW_ID, 长度是 6byte, 表示 row ID, 随着插入新行而单调增加. 如果 InnoDB 自动生成聚簇索引, 则聚簇索引包含 row ID
的值. 否则, DB_ROW_ID 列不会出现任何索引当中.

`rollback segment` 中的 undo log 分为插入和更新(undo log). 插入(undo log) 仅在事务回滚时需要, 并且可以在事务提
交后立即丢弃. 更新(undo log)用于一致性读取, 但只有在 "没有事务存在" 且 "为其InnoDB分配快照(snapshot)的情况" 下才能
丢弃它们, 在一致性读取中可能需要更新(undo log)中的信息来构建较早版本的数据行.

> 建议定期提交事务, 包括仅发出一致性读取的事务, 否则, InnoDB 无法从更新(undo log)中丢弃数据, 并且 `rollback segment`
可能会变得很大, 填满所在的表空间.

在 InnoDB 多版本中, 当使用 SQL 语句删除某行时,不会立即从数据库中物理删除该行. InnoDB 只有在丢弃为删除而写入的更新(undo log)
时, 才物理删除相应行及其索引记录. 这种删除操作称为清除(purge), 它非常快, 通常与执行删除操作的顺序是一致的.

如果在表中以大致相同的速度小批量插入和删除行, 清除(purge)线程可能会滞后, 并且由于所有"dead"行, 表会变得越来越大, 从而
使所有内容都受磁盘限制并且很慢. 这种情况下, 同规格调整 `innodb_max_purge_lag` 变量来限制新行操作, 并为清除线程分配
更多资源.

### 多版本与二级索引

InnoDB MVCC 处理二级索引和聚簇索引不同. 聚簇索引中的记录就地更新, 它们隐藏的系统列指向undo log条目, 可以从中重建记录的
早期版本数据. 二级索引不包含隐藏的系统列, 也不会就地更新.

当二级索引列被更新时, 旧的二级索引记录会被标记为删除, 新的记录被插入, 最终被标记为删除的记录被清除. 当二级索引记录被标记
为删除或二级索引页被事务更新时, InnoDB会在聚集索引查找该数据库记录. 在聚餐索引中, 会检查记录的 DB_TRX_ID, 如果在读取事
务启动后修改了记录, 则从undo log当中检索记录的正确版本. 

如果二级索引记录被标记为删除或二级索引页被事务所更新, 则不会使用覆盖索引技术. InnoDB 会使用聚簇索引查找记录并返回相应的
值, 而不是直接从二级索引结构当中返回. `回表`

但是, 如果启用咯额索引条件下推(ICP)优化, 并且 WHERE 可以仅使用索引中的字段评估部分条件, 则 MySQL 仍会讲这部分 WHERE 
条件下推到存储引擎, 在那里使用索引评估. 如果没有查找到匹配的记录, 则避免聚集索引查找. 如果找到匹配的记录, 即使是在被标记
为删除的记录中, 也会在 InnoDB 聚餐索引中查找该记录.


## InnoDB 架构

![image](/images/mysql_innodb_architecture.png)

### Buffer Pool

Buffer Pool 是主内存中的一个区域, 用于在InnoDB访问时缓存表和索引数据. Buffer Pool允许直接从内存访问经常使用的数据,
从而加快处理速度. 在专用服务器上, 多达80%的物理内存通常分配给Buffer Pool.

Buffer Pool 被划分为page. 使用链表的方式管理页面. 使用 LRU 算方法从缓存当中淘汰老的数据.

- LRU 算法

使用LRU算法的变体, 将 Buffer Pool 作为链表进行管理. 当需要想空间将新页面添加到Buffer Pool是, 最近最少使用的页面将被
移除, 并将新页面添加到链表的中间. 这个中点插入策略将链表视为两个子链表:

1. 头部是最近访问过的新("年轻")子链表
2. 在尾部. 是最近访问较少的旧子链表.

![image](/images/mysql_innodb_buffer_pool_list.png)

该算法将经常使用的页面保存在新子链表中. 旧子链表包含较少使用的页面, 这些页面可能会被移除.

默认情况下,算法操作如下:

1) 3/8的Buffer Pool用于旧的子列表.

2) 链表的中点是新子链表的尾部与旧子链表头部的边界.

3) 当InnoDB 将一个页面读入到Buffer Pool时, 它最初会将页面插入到中点(旧子链表的头部). 可以读取一个页面, 因为它是用户
发起的操作(如SQL查询)所需要的, 或者是InnoDB执行预读操作的一部分.

4) 访问旧子链表的页面会使其"年轻", 将其移动到新子链表的头部. 如果页面是因为用户发起的操作需要它而被读取, 则第一次访问立
即发生, 并且页面会变得年轻. 如果页面是由于预读操作而读取的, 则第一次访问不会立即发生, 并且在该页面被删除之前根本不会进行
一次访问.

5) 随着数据库的运行, Buffer Pool 中未被访问的的页面通过向链表尾部移动来"老化". 新旧子链表中的页面随着其他页面的更新而
老化. 旧子链表中的页面也会随着页面插入中点而老化. 最终, 一个未使用的页面到达使得旧子链表的尾部被移除.

默认情况下, 查询读取的页面会立即移动到新子链表中, 这意味着它们在Buffer Pool中停留的时间更长. 例如, mysqldump 操作或
没有WHERE子句的SELECT语句执行的表扫描, 可能将大量数据加载到Buffer Pool, 并删除等量的旧数据, 即使新数据永远不会再次使
用. 类似地, 由预读后台线程加载并仅访问移除的页面将被移动到新子链表的头部. 这些情况可能会将经常使用的页面推到旧子列表中,在
那里被清除. 

- Bufer Pool配置

1. 配置 InnoDB Bufer Pool大小

2. 配置多个Bufer Pool实例

3. 使用 Bufer Pool Scan Resistant

4. 配置 InnoDB Buffer Pool Prefetching (Read-Ahead). 

5. 配置 Buffer Pool Flushing. 控制后台刷新已经根据工作负载动态调整刷新速率.

6. 保存和恢复Buffer Pool状态. 保留Buffer Pool状态避免服务器重启后的长时间预热.

- 使用 InnoDB 标准监视器监测Buffer Pool

命令: `SHOW ENGINE InnoDB STATUS`. 在 `BUFFER POOL AND MEMORY` 当中输出.

```
...
----------------------
BUFFER POOL AND MEMORY
----------------------
Total large memory allocated 2198863872
Dictionary memory allocated 776332
Buffer pool size   131072
Free buffers       124908
Database pages     5720
Old database pages 2071
Modified db pages  910
Pending reads 0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 4, not young 0
0.10 youngs/s, 0.00 non-youngs/s
Pages read 197, created 5523, written 5060
0.00 reads/s, 190.89 creates/s, 244.94 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not
0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read
ahead 0.00/s
LRU len: 5720, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
...
```

| 名词 | 含义 |
| --- | --- |
| Total memory allocated | 缓存池总内存(字节) |
| Buffer pool size | 分配给缓存池的总页面大小 |
| Free buffers | 缓存池空闲链表的总大小(页) |
| Database pages | 缓存池LRU链表总大小(页) |
| Old database pages | 缓存池old LRU子链表的总大小(页) |
| Modified db pages | 当前在缓存池中修改的页数 |
| Pending reads | 等待读入缓存池的页数量 |
| Pending writes LRU | 要从LRU链表尾部写入旧脏数据页数 |
| Pending writes flush list | 检查点期间要刷新的缓存池页数量 |
| Pending writes single page | 缓存池当中等待写入的独立页面的大小 |
| Pages made young | LRU链表中年轻的页面总数(移动到"new"子链表的头部) |
| Pages made not young | LRU链表中年老的页面总数(保留在"old"子链表) |
| youngs/s | 每秒平均访问LRU链表导致页面变"年轻"的旧页面. 该指标仅适用于old页面. 它基于页面访问次数. |
| non-youngs/s | 每秒平均访问LRU链表导致页面变"年老"的旧页面. 该指标仅适用于old页面. 它基于页面访问次数. |
| Pages read | 从缓存池读取的总页数 |
| Pages created | 在缓存池中创建的页总数 |
| Pages written | 在缓存池写入的总页数 |
| reads/s | 平均每秒从缓存池读取的页数 |
| create/s | 平均每秒创建缓存池页的数 |
| write/s | 平均每秒缓存池写入的页数 |
| Buffer pool hit rate | 从缓存池读取的页面与从磁盘读取页面的命中比率 |
| young-making rate | 页面访问的平均命中率导致页面年轻. 考虑了所有缓存池页面访问, 而不仅仅是old子链表的页面访问. |
| not(young-making) | 页面访问的平均命中率未导致页面年轻 |

> - `youngs/s`, 如果在没有发生大扫描时看到非常低的值, 考虑减少延迟时间或用于增加old子链表的缓存池的百分比. 增加old子
链表百分比, 使得该子链表的页面移动到尾部所需的时间变长, 这增加了再次访问这些页面并使其变得年轻的可能性.
> - `non-young/s`, 在执行大型表扫描时没有看到更高的值. 请增加延迟时间.














