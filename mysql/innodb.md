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
更新, undo log 记录当中包含在更新重建该 row 之前

- DB_ROW_ID, 长度是 7byte, 表示 row ID, 它是单调增加的. 如果 InnoDB 自动生成聚簇索引, 则聚簇索引包含 row ID的值.
否则, DB_ROW_ID 列不会出现任何索引当中.
