# MVCC(多版本控制)

问题:

```
1. 聚簇索引与二级索引

2. 组提交(主从复制, 解决 SQL Thread 延时问题), 日志二阶段提交

3. 双1设置

4. MVCC

5. 优化思路:
1) 性能监控
2) schema 与数据类型
3) 执行计划
4) 增加索引优化
5) 查询优化
6) 分区表
7) 服务器参数调优
8) 集群
```


## InnoDB 与 MVCC

MVCC 只在 RC(READ COMMITED) 和 RR(REPEATABLE READ) 两个隔离级别下工作. 其他两个隔离级别与MVCC不兼容. 因为
RN(READ UNCOMMITED) 总是读取最新的数据行, 而不是复合当前事务版本的数据行. 而且 SERIALIZABLE 则会对多有读取的行都加
锁.

redo log, bin log, undo log:

InnoDB 中通过 undo log 实现数据的多版本, 而并发控制通过锁来实现.  undo log 除了实现 MVCC 之外, 还用于事务的回滚.

bin log 是 MySQL 服务层产生的日志, 常用于进行数据恢复, 数据库复制, 常见的 MySQL 主从架构, 就是采用 slave 同步 master
的 bin log 实现的, 另外通过解析 bin log 能够实现 MySQL 到其他数据源的数据复制.

InnoDB 的 redo log 记录了数据操作在物理层面的修改, MySQL中使用了大量缓存, 缓存存在内存中, 修改操作时会直接修改内存,而
不是立即修改磁盘, 当内存和磁盘不一致时, 称内存中的数据为脏页(dirty page). 为了保证数据的安全性, 事务进行中时会不断的产生
redo log, 在事务提交时进行一次 flush 操作, 保证数据写入到磁盘当中. 

在进行数据修改时除了记录redo log 外,还会记录 undo log, undo log用于数据的撤回操作, 它记录了修改的反向操作. 比如, 插
入对于删除, 修改对应修改为原来的数据, 通过undo log 可以实现事务回滚, 并且可以根据 undo log 回溯到某个特定版本的数据,
实现 MVCC.

undo log 与版本:
