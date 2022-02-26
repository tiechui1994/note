# MySQL Optimization

## Metadata Lock

MySQL 使用 Metadata Lock来管理对数据库对象的并发访问, 并确保数据一致性. Metadata Lock不仅适用于 table, 还适用于
schema, 存储程序(procedure, function, trigger, event), tablespace, 使用 GET_LOCK() 函数获取的用户锁.

`performance_schema.metadata_locks` 表展示了 Metadata Lock 的使用情况(哪些会话持有锁, 哪些会话阻塞等待锁等).

为了防止对同时被另一个事务使用的表进行 DDL 操作. 

Online 操作的增强, 主要集中在减少元数据锁定的数量上. 目标: 当 DDL 操作不改变表结构 (例如 InnoDB 表的 `CREATE INDEX`
和 `DROP INDEX`) 时, 其他事务可以在当前的表上进行查询, 更新.

### Metadata Lock 获取

如果给定锁有多个等待者, 则首先满足最高优先级的锁请求.

语句是一个一个地获取 Metadata Lock, 而不是同时获取, 并在这个过程中进行死锁检测.

- DML 语句按照语句中提及的表的顺序获取锁.

- DDL语句, LOCK TABLES 和 其他类似语句尝试通过按名称顺序获取显示命名表上的锁来减少并发 DDL 语句之间可能出现的死锁数量. 
对于隐式使用的表(例如, 必须锁定的外键值关系中的表), 可能会以不同的顺序获取锁.

例如, RENAME TABLE 是一个按名称顺序获取锁的 DDL 语句:

```
RENAME TABLE tbla TO tbld, tblc TO tbla;
```

该语句按顺序获取 tbla, tblc 和 tbld 上的 Metadata Lock(因为, 按名称顺序, tbld 在 tblc 之后).

```
RENAME TABLE tbla TO tblb, tblc TO tbla;
```

该语句按顺序获取 tbla, tblb 和 tblc 上的 Metadata Lock(因为, 按名称顺序, tblb 在 tblc 之前).

当多个事务同时执行执行时, Metadata Lock获取顺序会影响操作结果.

案例1: 从两个具体相同表结构的表 x, x_new 开始. 三个客户端执行语句:

```
# Client1, (按顺序)请求和获取 x, x_new 表的写锁
LOCK TABLE x WRITE, x_new WRITE;

# Client2, 请求并等待 x 表的写锁
INSERT INTO x VALUES(1);

# Client3, 在 x, x_new, x_old (按顺序)请求 X 锁, 但是, 会阻塞等待 x 上的锁
RENAME TABLE x TO x_old, x_new TO x;

# Client1, 释放 x 和 x_new 上的写锁. Client3 的X锁请求比 Client2 的写锁请求有更高的优先级, 因此 Client3 获取对
# x 的锁, 然后还获取 x_new, x_old 的锁, 执行 RENAME, 并释放其锁. 最后, Client2 获得 x 上的锁, 执行插入, 并释放它
# 的锁. 
UNLOCK TABLES; 
```

上述的执行结果: `x` 表当中有1条数据, `x_old` 表没有数据

案例2: 从两个具体相同表结构的表 x, new_x 开始. 三个客户端执行语句:

```
# Client1, (按顺序)请求和获取 nex_x, x 表的写锁
LOCK TABLE x WRITE, new_x WRITE;

# Client2, 请求并等待 x 表的写锁
INSERT INTO x VALUES(1);

# Client3, 在 new_x, old_x, x (按顺序)请求 X 锁, 但是, 会阻塞等待 new_x 上的锁
RENAME TABLE x TO old_x, new_x TO x;

# Client1, 释放 x 和 new_x 上的写锁. 对于 x, 唯一挂起的请求来自 Client2, 因此 Client2 获取其锁, 执行插入并释放锁.
# 对于 nex_x, 唯一挂起的请求来自 Client3, 它被允许获得该锁(以及 old_x 上的锁), RENAME 操作仍然阻塞在 x 上的锁, 直
# 到 Client2 插入完成释放 x 的锁. 然后 Client3 获取 x 上的锁, 执行 RENAME, 并释放锁. 
UNLOCK TABLES; 
```

上述的执行结果: `old_x` 表当中有1条数据, `x` 表没有数据

- Metadata Lock 释放

### Metadata Lock 释放

为了确保事务可串行化, 服务器不不允许一个会话对另一个会话中未完成的显示或隐式启动的事务中使用的表执行 DDL 语句. 服务器通过
获取事务中使用的表上的 Metadata Lock 并将这些锁的释放延迟到事务结束来实现这一点. 表上的 Metadata Lock 可防止更改表的
数据结构. 这种锁意味着一个会话中正在使用的表在事务结束之前不能由其他会话在 DDL 语句中使用.

上述的原则不仅适用于事务表, 也适用于非事务表. 假设一个会话开始一个使用事务表t和非事务表nt的事务, 如下:

```
STRTA TRANSACTION;
SELCT * FROM t;
SELCT * FROM nt;
```

服务器持有 t 和 nt 的 Metadata Lock, 直到事务结束. 如果另一个会话尝试对任意一表执行 DDL 或 写锁操作, 它会阻塞直到事
务结束时才释放 Metadata Lock. 例如, 如果第二个会话尝试以下任意操作, 将被阻塞:

```
DROP TABLE t;
ALTER TABLE t ...;
DROP TABLE nt;
ALTER TABLE nt ...;
LOCK TABLE t ... WRITE;
```

相同的行为适用于 `LOCK TABLES ... READ`. 也就说, 当执行完 `LOCK TABLES ... READ` 之后, 显示或隐式启动的事务, 并
且更新任何表(事务性或非事务性) 会被阻塞执行.

如果服务器在执行语句上获取到了有效的 Metadata Lock, 但是在执行期间失败了, 它不会提取释放锁. 锁释放仍然延迟到事务结束.
因为失败的语句被写入 binlog, 并且锁保护了日志的一致性.

在自动提交模式下, 每个语句都是一个完整的事务. 因此, 为语句获取的 Metadata Lock 只保留到语句的末尾.

在 PREPARE 语句期间获取的 Metadata Lock 在 PREPARE 完成之后被释放, 即使 PREPARE 工作期间发生在多语句事务中.
