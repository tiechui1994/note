# InnoDB 锁与事务模型

锁的种类一般分为乐观锁和悲观锁两种:

乐观锁和悲观锁其实都是并发控制, 同时它们在实现原理上有着本质的差别:

- 乐观锁是一种思想, 它并不是一种真正的锁. 它会先尝试对资源进行修改, 在写回时判断其他人是否修改了该资源, 如果没有发生改变
就会写回, 否则会进行重试, 在整个的执行过程中其实都没有对数据库进行加锁. (CAS就是乐观锁)

- 悲观锁是一种真正的锁. 它会在获取资源前对资源进行加锁, 确保同一时刻有有限的线程能够访问该资源, 其它想要尝试获取资源的操
作都会进入等待状态, 直到该线程完成了对资源的操作并且释放了锁后, 其它线程才能重新操作资源. (LOCK)

对数据的操作其实只有两种, 也就是读和写, 而数据库在实现锁时, 也会对这两种操作使用不同的锁; InnoDB 实现了标准的行级锁, 也
就是共享锁(S)和互斥锁(X)

## 共享锁和独占锁

InnoDB实现标准的行级锁定, 其中有两种类型的锁, 即shared(S)锁和exclusive(X)锁.

- 共享(S)锁(读锁): 允许事务对一条数据进行读取.

- 独占(X)锁(写锁): 允许事务对一条数据进行更新或删除.

## Intention Lock (意向锁)

InnoDB 支持多粒度锁, 允许行锁和表锁共存. 例如, `LOCK TABLES ... WRITE` 之类的语句在指定表上采用互斥锁(X). 为了使
多粒度级别的锁变得有用, InnoDB 引入了意向锁(Intention Lock).

**意向锁(Intention Lock)是表级锁**, 表示事务对于表中的行稍后需要哪种类型的锁(S或X). 

InnoDB有两种类型的意向锁使用:

- 意向共享锁(IS): 事务打算在表中的各个行上设置共享锁;
- 意向互斥锁(IX): 事务打算在表中的各个行上设置共享锁;

例如, `SELECT ... LOCK IN SHARE MODE` 设置IS锁定, `SELECT ... FOR UPDATE` 设置IX锁定.

意向锁定协议如下:
- 在一个事务可以获得一个表中一行的共享锁(S)之前, 它必须首先获得这张表的IS锁或这张表的更强的锁.
- 在一个事务可以获得一个表中一行的互斥锁(X)之前, 它必须先获得这张表IX锁.

这些规则可以通过下面的锁类型兼容性矩阵方便地总结.

|  | X | IX | S | IS |
| --- | --- | --- | --- | --- |
| X | ✗ | ✗ | ✗ | ✗ |
| IX | ✗ | ✔ | ✗ | ✔ |
| S | ✗ | ✗ | ✔ | ✔ |
| IS | ✗ | ✔ | ✔ | ✔ |

> X 与其它任何锁都不兼容
> IX 只与意向锁兼容(IX, IS)
> S 只与共享锁兼容(S, IS)
> IS 与意向锁和共享锁兼容


如果请求的事务与现有的锁定兼容, 授予锁定, 但如果它与现有的锁定冲突, 则锁定将被拒绝. 事务一直等到有冲突的锁被释放. 如果加
锁请求与现有的锁发生冲突, 锁无法被授予, 因为它会导致死锁, 且会发生错误.

因此, 意向锁只会阻塞全表请求(例如, LOCK TABLES ... WRITE). 意向锁的主要目的是显示某人正锁定一行, 或将要锁定表中的一
行.

意向锁定的事务数据在 `SHOW ENGINE INNODB STATUS` 的 `TRANSACTIONS` :

```
TABLE LOCK table `test`.`t` trx id 10080 lock mode IX
```

意向锁其实不会阻塞全表扫描之外的任何请求, 它的主要目的是为了表示**是否有人请求锁定表中的某一行数据**.

> 例: 如果没有意向锁, 当已经有请求使用行锁对表中的某一行进行修改时, 如果另外一个请求要对全表进行修改, 那么就需要对所有的
行是否被锁定进行扫描, 这种状况下效率非常的低; 在引入意向锁之后, 当使用行锁对表中的某一行进行修改之前, 会先为表添加意向互
斥锁(IX), 再为行记录添加互斥锁(X), 在这时尝试对全表进行修改时不需要判断表中的每一行数据是否被加锁了, 只需要通过等待意向
互斥锁(IX)被释放就可以了.

## 锁的算法

锁的算法: Record Lock, Gap Lock, Next-Key Lock

> 在 information_schema 库的 `innodb_locks`(查看当前各个事务加锁状况), `innodb_lock_waits`(查看当前各个事务锁
等待状态)

### Record Lock (记录锁)

**记录锁是加到索引记录**上的锁. 例如, `SELECT c1 FROM t WHERE c1 = 10 FOR UPDATE;` 阻止其他任何事务插入, 更新 
或 删除 t.c1的值为10的行.

记录锁始终锁定索引记录, 即使是一个没有索引的表. 对于这种情况, InnoDB创建一个隐藏的 `clustered index` 并使用此索引进
行记录锁定.

记录锁的事务数据在 `SHOW ENGINE INNODB STATUS` 的 `TRANSACTIONS` 或 `LATEST DETECTED DEADLOCK`:
```
RECORD LOCKS space id 58 page no 3 n bits 72 index `PRIMARY` of table `test`.`t` trx id 10078 lock_mode X locks rec but not gap waiting
Record lock, heap no 2 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 8000000a; asc     ;;
 1: len 6; hex 00000000274f; asc     'O;;
 2: len 7; hex b60000019d0110; asc        ;;
```

### Gap Lock (间隙锁)

间隙锁是对 **索引记录之间**, 或 "第一条索引记录之前" 或 "最后一个索引记录之后" 的间隙上的锁.

例如, `SELECT c1 FROM t WHERE c1 BETWEEN 10 AND 20 FOR UPDATE;`, 它会阻止其他事务向表中插入 id=15 的记录. 
无论列中是否已存在任何此类值, 因为 **该范围内所有现有值之间的间隙** 都被锁定.

间隙可能跨越单个索引值, 多个索引值, 或甚至可能为空.

> 间隙锁定是性能和并发之间权衡的一部分, 并且只用于某些事务隔离级别(READ COMMITTED).

虽然间隙锁中也分为共享锁和互斥锁, 不过它们之间并不是互斥的, 也就是不同的事务可以同时持有一段相同范围的共享锁和互斥锁, 它
唯一阻止的就是 **其它事务向这个范围中添加新的记录**. 

在使用唯一索引去搜索唯一行的状况下是不需要间隙锁定. (这不包括搜索条件仅包含 "多列唯一索引" 的某些列的情况; 在这种情况下, 
确实会发生间隙锁定.) 例如, 如果id列具有唯一索引, 则以下语句仅使用具有 id 值 100 的行的记录锁, 其他会话是否在前一个间隙
中插入行无关紧要:

```
SELECT * FROM child WHERE id=100;
```

如果 id 没有索引或具有非唯一索引, 则该语句会锁定间隙.

此处值得注意的是, 不同的事务可以在间隙上持有"冲突的"锁. 例如, 事务A可以在间隙上持有共享间隙锁(gap S-lock), 而事务B在同
一间隙上持有独占间隙锁(gap X-lock). 允许"冲突的"间隙锁的原因是, 如果从索引中清除记录, 则必须合并不同事务在记录上持有的间
隙锁.

InnoDB 中的间隙锁是 "purely inhibitive(纯粹的抑制)", 这意味着它们的唯一目的是防止其他事务插入间隙. 间隙锁可以共存.
一个事务占用的间隙锁定不会阻止另一个事务在同一个间隙上采用的间隙锁. 共享和独占间隙锁之间没有区别. 它们彼此不冲突, 它们执行
相同的功能.

可以显示禁用间隙锁, 如果将事务是 RC 隔离级别 或启用 `innodb_locks_unsafe_for_binlog` 系统变量(现已弃用,5.7), 则
会发生这种情况. 在这些情况下, 对于搜索和索引扫描禁用间隙锁, 并且间隙锁仅用于 "foreign-key 检查" 和 "duplicate-key 检查".

使用 RC 隔离级别或启用 `innodb_locks_unsafe_for_binlog` 还有其他影响. 在 MySQL 评估 WHERE 条件后, 将释放不匹配
行的记录锁. 对于 UPDATE 语句, InnoDB 执行 "semi-consistent(半一致)" 读取, 以便将最新提交的版本返回给MySQL, 以便 
MySQL 可以确定该行是否与 UPDATE 的 WHERE条件匹配.

> Gap Lock 只在 RR 和 S 隔离级别下工作. 
> 
> semi-consistent read: 一种用于 UPDATE 语句的读取操操作, 它是 READ COMMITED 和 consistent read 的组合. 
> 当 UPDATE 语句检查已锁定的行时, InnoDB 将最新提交的版本返回给 MySQL, 以便 MySQL 可以确定该行是否匹配 UPDATE 的
> WHERE 条件. 如果行匹配(必须更新), MySQL 再读取该行, 这一次 InnoDB 要么锁定它, 要么等待锁定它. 只有当事务具有 RC
> 隔离级别或启用`innodb_locks_unsafe_for_binlog`选项时, 才会发生这种类型的读取操作.

### Next-Key Lock (下一键锁定)

下一键锁是 "a record lock on the index record" 和 "a gap lock on the gap before the index record" 的组合.

InnoDB 执行行级锁的方式: 当它搜索或扫描表索引时, 它会在遇到的索引记录上设置共享锁或互斥锁. 因此, 行级锁实际上是索引记录
锁. 索引记录上的下一键锁也会影响 "该索引记录之前的间隙". 也就是说, 下一键锁定是 "索引记录锁" + "索引记录之前的间隙锁". 
如果一个会话在索引中的记录R上具有共享锁或互斥锁, 则另一个会话不能在索引顺序中的R之前的间隙中插入新的索引记录.

假设索引包含值10, 11, 13和20. 此索引的可能的下一个键锁覆盖以下间隔, 其中圆括号表示排除间隔端点, 方括号表示包含端点:

```
(-oo, 10]
(10, 11]
(11, 13]
(13, 20]
(20, +oo)
```

> 注: 每一行都是一个 next-key lock

对于最后一个间隙, 下一个键锁将间隙锁定在索引中最大值之上, 而"supremum"伪记录的值高于索引中实际的任何值. supremum不是
真正的索引记录, 因此, 实际上, 该下一键锁定仅锁定最大索引值之后的间隙.

默认情况下, InnoDB在 RR 事务隔离级别运行. 在这种情况下, InnoDB 使用下一键锁进行搜索和索引扫描. 从而防止幻读.

下一键锁的事务数据在 `SHOW ENGINE INNODB STATUS` 的 `TRANSACTIONS` 或 `LATEST DETECTED DEADLOCK`:
```
RECORD LOCKS space id 58 page no 3 n bits 72 index `PRIMARY` of table `test`.`t` trx id 10080 lock_mode X waiting
Record lock, heap no 1 PHYSICAL RECORD: n_fields 1; compact format; info bits 0
 0: len 8; hex 73757072656d756d; asc supremum;;

Record lock, heap no 2 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 8000000a; asc     ;;
 1: len 6; hex 00000000274f; asc     'O;;
 2: len 7; hex b60000019d0110; asc        ;;
```

### Insert Intention Lock (插入意向锁, 间隙锁的一种)

插入意向锁是在插入行之前由 INSERT 操作设置的一种间隙锁. 该锁表示插入的意向: 如果插入到同一索引间隙中的多个事务没有在间隙
内的同一位置插入, 则它们不需要等待彼此. 

例如, 假设存在值为 4 和 7 的索引记录, 分别尝试插入值 5 和 6 的单独事务, 在获得插入行上的互斥锁之前, 每个使用插入意向锁
锁定 4 和 7 之间的间隙, 但是不会相互阻塞, 因为行是不冲突的.

下面示例演示了在获取插入记录的独占锁之前使用插入意向锁的事务. 该示例涉及两个客户端, A和B.

客户端A创建一个包含两个索引记录(90和102)的表, 然后启动一个事务, 该事务将排它锁设置在ID大于100的索引记录上. 互斥锁包括记
录102之前的间隙锁:
```
mysql> CREATE TABLE child (id int(11) NOT NULL, PRIMARY KEY(id)) ENGINE=InnoDB;
mysql> INSERT INTO child (id) values (90),(102);

mysql> START TRANSACTION;
mysql> SELECT * FROM child WHERE id > 100 FOR UPDATE;
```

客户端B开始事务, 将记录插入间隙中. 该事务在等待获取互斥锁时采用插入意向锁.
```
mysql> START TRANSACTION;
mysql> INSERT INTO child (id) VALUES (101);
```

插入意向锁的事务数据 `SHOW ENGINE INNODB STATUS` 的 TRANSACTIONS 当中包含如下内容:
```
------- TRX HAS BEEN WAITING 4 SEC FOR THIS LOCK TO BE GRANTED:
RECORD LOCKS space id 31 page no 3 n bits 72 index `PRIMARY` of table `test`.`child` trx id 8731 lock_mode X insert intention waiting
Record lock, heap no 3 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 80000066; asc    f;;
 1: len 6; hex 000000002215; asc     " ;;
 2: len 7; hex 9000000172011c; asc     r  ;;...
```

### AUTO-INC Lock

AUTO-INC锁定是由插入到具有 `AUTO_INCREMENT` 列的表中的事务所采用的特殊表级锁. 在最简单的情况下, 如果一个事务正在向表
中插入值, 则任何其他事务必须等待对该表执行自己的插入, 以便第一个事务插入的行接收连续的主键值.

`innodb_autoinc_lock_mode` 选项控制用于自动增量锁定的算法. 它允许您选择如何在可预测的自动增量值序列和插入操作的最大
并发之间进行权衡.

# TRANSACTION MODEL

事务隔离是数据库处理的基础之一. 隔离级别是在多个事务进行更改并同时执行查询时, 对结果的性能和可靠性, 一致性和可重现性进行
微调的设置.

InnoDB提供了SQL: 1992标准描述的所有四个事务隔离级别: `READ UNCOMMITTED`, `READ COMMITTED`, `REPEATABLE 
READ` 和 `SERIALIZABLE`. InnoDB的默认隔离级别是 `REPEATABLE READ`.

用户可以使用 `SET TRANSACTION` 语句更改单个会话或所有后续连接的隔离级别. 要为所有连接设置服务器的默认隔离级别, 请在命
令行或选项文件中使用--transaction-isolation选项.

InnoDB使用不同的锁定策略支持此处描述的每个事务隔离级别. 可以使用默认的 `REPEATABLE READ` 级别强制执行高度一致性, 以便
对ACID合规性很重要的关键数据进行操作. 或者可以放松使用 `READ COMMITTED` 甚至 `READ UNCOMMITTED` 的一致性规则, 例
如批量报告, 其中精确一致性和可重复结果不如最小化锁定开销量重要. `SERIALIZABLE` 强制执行甚至比 `REPEATABLE READ` 更
严格的规则, 主要用于特殊情况, 例如XA事务以及并发和死锁的故障排除问题.

以下列表描述了MySQL如何支持不同的事务级别. 该列表从最常用的级别变为最少使用的级别.

## TRANSACTION LEVEL 

### REPEATABLE READ

这是InnoDB的默认隔离级别. 同一事务中的一致读取读取第一次读取建立的快照. 这意味着如果在同一事务中发出多个普通 (非锁定)
SELECT 语句, 则这些SELECT语句也相互一致.

对于锁定读取(使用`FOR UPDATE` 或 `LOCK IN SHARE MODE`的 SELECT), UPDATE 和 DELETE 语句, 锁定取决于语句是使用
具有唯一搜索条件的唯一索引还是范围类型搜索条件.

- 对于具有唯一搜索条件的唯一索引, InnoDB仅锁定找到的索引记录, 而不是间隙.

- 对于其他搜索条件, InnoDB锁定扫描的索引范围, 使用间隙锁或下一键锁来阻止其他会话插入范围所覆盖的间隙.

### READ COMMITTED

即使在同一事务中, 每个一致的读取也会设置和读取自己的新快照.

对于锁定读取(使用 `FOR UPDATE` 或 `LOCK IN SHARE MODE` 的SELECT), UPDATE 语句和DELETE语句, InnoDB仅锁定索引
记录, 而不锁定它们的间隙, 因此允许在锁定记录旁边自由插入新记录. 间隙锁定仅用于外键约束检查和重复键检查.

由于禁用了间隙锁定, 因此可能会出现幻像问题, 因为其他会话可以在间隙中插入新行.

READ COMMITTED 隔离级别仅支持基于行的二进制日志记录. 如果对binlog_format=MIXED使用READ COMMITTED, 则服务器会自
动使用基于行的日志记录.

使用 READ COMMITTED 其他影响:

- 对于UPDATE或DELETE语句, InnoDB仅为其更新或删除的行保留锁定. MySQL评估WHERE条件后, 将释放不匹配行的记录锁. 这大大
降低了死锁的可能性, 但它们仍然可以发生.

- 对于UPDATE语句, 如果一行已被锁定, InnoDB将执行"semi-consistent(半一致)"读取, 将最新提交的版本返回给MySQL, 以便
MySQL可以确定该行是否与 UPDATE 的 WHERE 条件匹配. 如果行匹配(必须更新), MySQL再次读取该行, 这次InnoDB将其锁定或等
待锁定.

案例:
```
CREATE TABLE t (a INT NOT NULL, b INT) ENGINE=InnoDB;
INSERT INTO t VALUES (1,2), (2,3), (3,2), (4,3), (5,2);
COMMIT;
```

在这种情况下, 表没有索引, 因此搜索和索引扫描使用隐藏的聚簇索引进行记录锁定而不是索引列.

假设一个会话使用以下语句执行UPDATE:
```
# Session A
START TRANSACTION;
UPDATE t SET b=5 WHERE b=3;
```

假设第二个会话通过执行第一个会话的语句后执行UPDATE:
```
# Session B
UPDATE t SET b=4; WHRER b=2;
```

当InnoDB执行每个UPDATE时, 它首先为它读取的每一行获取一个互斥锁, 然后确定是否修改它. 如果InnoDB没有修改该行, 它将释放
锁. 否则, InnoDB会保留锁定, 直到事务结束. 这会影响事务处理, 如下所示.

使用默认的隔离级别 `RR`, 第一个UPDATE在它读取的每一行上获取一个X锁, 并且不释放它们中的任何一个:
```
x-lock(1,2); retain x-lock
x-lock(2,3); update(2,3) to (2,5); retain x-lock
x-lock(3,2); retain x-lock
x-lock(4,3); update(4,3) to (4,5); retain x-lock
x-lock(5,2); retain x-lock
```

第二个UPDATE一旦尝试获取任何锁就会阻塞(因为第一次更新已保留所有行的锁), 并且在第一次UPDATE提交或回滚之前不会继续:
```
x-lock(1,2); block and wait for first UPDATE to commit or roll back
```

如果使用隔离级别是 `RC`, 则第一个UPDATE会在其读取的每一行上获取一个X锁, 并释放那些不会修改的行:
```
x-lock(1,2); unlock(1,2)
x-lock(2,3); update(2,3) to (2,5); retain x-lock
x-lock(3,2); unlock(3,2)
x-lock(4,3); update(4,3) to (4,5); retain x-lock
x-lock(5,2); unlock(5,2)
```

对于第二个UPDATE, InnoDB执行"semi-consistent(半一致)"读取, 返回它读取到MySQL的每一行的最新提交版本,以便MySQL可以
确定该行是否与UPDATE的WHERE条件匹配:
```
x-lock(1,2); update(1,2) to (1,4); retain x-lock
x-lock(2,3); unlock(2,3)
x-lock(3,2); update(3,2) to (3,4); retain x-lock
x-lock(4,3); unlock(4,3)
x-lock(5,2); update(5,2) to (5,4); retain x-lock
```

但是, 如果WHERE条件包含索引列, 并且InnoDB使用索引, 则在获取和保留记录锁时仅考虑索引列. 在下面的示例中, 第一个UPDATE在
每个b=2的行上获取并保留X锁定. 第二个UPDATE在尝试获取相同记录的X锁时阻塞, 因为它还使用在列b上定义的索引.
```
CREATE TABLE t (a INT NOT NULL, b INT, c INT, INDEX (b)) ENGINE = InnoDB;
INSERT INTO t VALUES (1,2,3),(2,2,4);
COMMIT;

# Session A
START TRANSACTION;
UPDATE t SET b = 3 WHERE b = 2 AND c = 3;

# Session B
UPDATE t SET b = 4 WHERE b = 2 AND c = 4;
```

使用 `RC` 隔离级别的效果与启用不推荐使用的innodb_locks_unsafe_for_binlog配置选项相同, 但有以下例外:

- 启用innodb_locks_unsafe_for_binlog是一个全局设置, 会影响所有会话, 而隔离级别可以为所有会话全局设置, 也可以为每个
会话单独设置.

- innodb_locks_unsafe_for_binlog只能在服务器启动时设置, 而隔离级别可以在启动时设置或在运行时更改.

因此, `RC`隔离级别提供比innodb_locks_unsafe_for_binlog更精细和更灵活的控制.

### READ UNCOMMITED

SELECT语句以非锁定方式执行, 但可能使用行的早期版本. 因此, 使用此隔离级别, 此类读取不一致. 这也称为脏读. 否则, 此隔离级
别与 `READ COMMITTED` 类似.

### SERIALIZABLE

此级别与 `REPEATABLE READ` 类似, 如果禁用自动提交, InnoDB将隐式地将所有普通 SELECT 语句转换为 
`SELECT ... LOCK IN SHARE MODE`. 如果启用了自动提交, 则 SELECT 是其自己的事务. 因此, 由于它是只读的, 并且如果作
为一致(非锁定)读取执行则可以序列化, 并且不需要阻止其他事务. (要强制普通SELECT阻止其他事务已修改所选行, 请禁用自动提交)

## View

MySQL 当中, 有两个 "view" 概念:

1. 一个是 view, 它是一个用查询语句定义的虚拟表, 在调用的时候执行查询语句并生成结果. 创建视图的语法是 `CREATE VIEW`,
它的查询方法与表是一样的.

2. 另一个是 InnoDB 在实现 MVVC 时用到的"一致性读视图", 即consistent read view, 用于支持 RC(读提交)和RR(可重复读)
隔离级别的实现. 

## Consistent Nonlocking Read(一致性非锁定读, 也称为 Snapshot Read)

consistent read 取意味着InnoDB使用 MVCC 在某个时间点向查询提供数据库的快照. 查询将查看 "在该时间点之前提交的事务所
做的更改", 并且不会对 "以后" 或 "未提交" 的事务所做的更改进行更改. 注意: 快照是基于库的. 快照, 就是把当时 trx_sys 状
态(包括活跃读写事务事务组)记下来, 之后的所有读操作根据其事务ID(即trx_id)与快照中的trx_sys的状态做比较, 以此判断数据对
事务的可见性.

> 对于聚簇索引, 每次修改记录时, 都会在记录中保存当前的事务ID,同时旧版本记录存储在Undo Log. 对于二级索引, 则在二级索引
页中存储更新当前页的最大事务ID, 如果该事务ID大于快照中的最大值, 那么需要回聚簇索引判断记录可见性, 如果该事务ID小于快照中
的最小值, 该记录总是可见的.

此规则的例外是 "查询同一事务中早期语句所做的更改", 异常导致以的结果: 如果更新表中的某些行, SELECT 将查看更新行的最新版本, 
但它也可能会看到任何行的旧版本. 如果其他会话同时更新同一个表, 则异常意味着可能会看到该表处于从未存在于数据库中的状态.

如果事务隔离级别是RR(默认级别), 则同一事务内的 consistent read view 将在事务开始时创建, 确切地说是该事务中第一个读操
作创建. 你可以通过提交当前事务并在发出新查询之后为查询获取更新的快照.

使用 RC 隔离级别, 事务中的每个语句之前都会创建 consistent read view.

consistent read 是 InnoDB 在 `READ COMMITTED` 和 `REPEATABLE READ` 隔离级别中处理SELECT语句的默认模式. 一致
读取不会对其访问的表设置任何锁定, 因此其他会话可以在对表执行consistent read的同时自由修改这些表.

假设你正在以默认的 RR 隔离级别运行. 当你发出一致读取(即普通SELECT语句)时, InnoDB 会为你的事务提供一个时间点, 你的查询
将根据该时间点查看数据库. 如果另一个事务删除了一行并在分配了你的时间点后提交, 则你不会将该行视为已删除. 插入和更新的处理方
式类似.

> 数据库状态的快照适用于事务中的SELECT语句, 不一定适用于DML语句. 如果插入或修改某些行然后提交该事务, 则从另一个并发
`REPEATABLE READ` 事务发出的DELETE或UPDATE语句可能会影响那些刚刚提交的行, 即使会话无法查询它们. 如果事务确实更新或
删除了由其他事务提交的行, 则这些更改将对当前事务可见. 例如, 可能会遇到如下情况:

```
SELECT COUNT(c1) FROM t1 WHERE c1 = 'xyz';
-- Returns 0: no rows match.
DELETE FROM t1 WHERE c1 = 'xyz';
-- Deletes several rows recently committed by other transaction.

SELECT COUNT(c2) FROM t1 WHERE c2 = 'abc';
-- Returns 0: no rows match.
UPDATE t1 SET c2 = 'cba' WHERE c2 = 'abc';
-- Affects 10 rows: another txn just committed 10 rows with 'abc' values.
SELECT COUNT(c2) FROM t1 WHERE c2 = 'cba';
-- Returns 10: this txn can now see the rows it just updated.
```


你可以通过提交事务, 然后再执行另一个SELECT 或 `START WITH ACACENT WITH SNAPSHOT` 来提高您的时间点.
这称为多版本并发控制.

在以下示例中, 会话A仅在 "B已提交插入" 且 "A已提交" 时才看到由B插入的行, 以便时间点超过B的提交.

![image](/images/mysql_innodb_trx_consistent_read.png)

如果要查看数据库的"最新"状态, 请使用 `READ COMMITTED` 隔离级别或锁定读取: `SELECT * FROM t FOR SHARE;`

使用 `READ COMMITTED` 隔离级别, 事务中的每个一致读取都会设置并读取其自己的新快照. 使用 `LOCK IN SHARE MODE`时,
会发生锁定读取: SELECT阻塞, 直到包含最新行的事务结束.

一致的读取对某些DDL语句不起作用:

- 一致读取不适用于 `DROP TABLE`, 因为MySQL无法使用已删除的表并且InnoDB会破坏该表.

- 一致性读取不适用于 `ALTER TABLE`, 因为该语句生成原始表的临时副本, 并在构建临时副本时删除原始表. 在事务中重新发出一致
读取时, 新表中的行不可见, 因为在执行事务快照时这些行不存在. 在这种情况下, 事务返回错误: ER_TABLE_DEF_CHANGED, 
"Table definition has changed, please retry transaction".


读取类型因 `INSERT INTO ... SELECT`, `UPDATE ... (SELECT)` 和 `CREATE TABLE ... SELECT` 等子句中的选择而异,
不指定 `FOR UPDATE` 或 `LOCK IN SHARE MODE`:

- 默认情况下, InnoDB使用更强的锁定, SELECT部分​​的作用类似于`READ COMMITTED`, 即使在同一事务中, 每个一致的读取也会设
置和读取自己的新快照.

- 要在这种情况下使用一致读取, 请启用innodb_locks_unsafe_for_binlog选项并将事务的隔离级别设置为 `READ UNCOMMITTED`,
`READ COMMITTED` 或 `REPEATABLE READ` (即SERIALIZABLE以外的任何其他内容). 在这种情况下, 不会对从所选表中读取的行
设置锁定.

## Locking Read (锁定读取, 也称为 Current Read)

如果查询数据然后在同一事务中插入或更新相关数据, 则常规 SELECT 语句不会提供足够的保护. 其他事务可以更新或删除你刚查询的相
同行. InnoDB支持两种类型的锁定读取, 提供额外的安全性:

- SELECT ... LOCK IN SHARE MODE

在读取的任何行上设置共享锁定. 其他会话可以读取行, 但在事务提交之前无法修改它们. 如果这些行中的任何行已被另一个尚未提交的事
务更改, 则查询将等待该事务结束. 然后使用最新值(最新更新的版本).

- SELECT ... FOR UPDATE

对于搜索遇到的索引记录, 锁定'行和关联的索引条目', 就像为这些行发出 UPDATE 语句一样. 当在其他事务当中 '更新这些行', 或
'执行 SELECT ... LOCK IN SHARE MODE 语句', 或 '从某些事务隔离级别读取数据' 时, 都会被阻塞. 一致性读取将忽略在读
取视图中存在的记录上设置的任何锁定. (旧版本的记录无法被锁定; 它们通过在记录的内存中副本上应用 undo log 来重建.)

这些子句在处理树形结构或图形结构数据时非常有用, 无论是在单个表中还是在多个表中拆分. 你将边缘或树枝从一个地方遍历到另一个地
方, 同时保留返回并更改任何这些"指针"值的权限.

当事务COMMIT 或 ROLLBACK 时, 所有由 LOCK IN SHARE MODE 和 FOR UPDATE 查询设置的锁都会被释放.

> 只有在禁用自动提交时(通过使用START TRANSACTION开始事务或将自动提交设置为0), 才能锁定读取.

除非在子查询中指定了锁定读取子句, 否则外部语句中的锁定读取子句不会锁定嵌套子查询中的表行. 例如, 以下语句不会锁定表t2中的
行.
```
SELECT * FROM t1 WHERE c1 = (SELECT c1 FROM t2) FOR UPDATE;
```

要锁定表t2中的行,请在子查询中添加一个锁定读取子句:
```
SELECT * FROM t1 WHERE c1 = (SELECT c1 FROM t2 FOR UPDATE) FOR UPDATE;
```

案例:

假设你要在 child 表中插入一新行, 并确保子行在 parent 表中具有父行. 你的应用程序代码可确保整个操作序列中的引用完整性.

首先, 使用一致性读取来查询 parent 表并验证父行是否存在. 你能安全地将子行插入 child 表吗? 不, 因为其他一些会话可以删除
SELECT和INSERT之间的父行, 而不会知道到它.

要避免此潜在问题, 请使用 `LOCK IN SHARE MODE` 执行SELECT:
```
SELECT * FROM parent WHERE NAME = 'Jones' LOCK IN SHARE MODE;
```

在 `LOCK IN SHARE MODE` 查询返回父"Jones"后, 你可以安全地将子记录添加到 child 表并提交事务. 尝试获取 parent 表中
适用行的独占锁的任何事务都会等到完成后, 即直到所有表中的数据都处于一致状态.


再例如, 考虑 child_codes 表中的整数计数器字段, 用于为添加到 child 表的每个子项分配唯一标识符. 不要使用一致读取或共享
锁来读取来读取计数器的当前值, 因为数据库的两个用户可能看到计数器的相同值, 并且如果两个事务尝试向 child 表添加相同标识行, 
则会发生 duplicate-key 错误.

这里, `LOCK IN SHARE MODE` 不是一个好的解决方案, 因为如果两个用户同时读取计数器, 则当它们尝试更新计数器时, 其中至少有
一个会陷入死锁.

要实现读取和递增计数器, 首先使用 `FOR UPDATE` 执行计数器的锁定读取, 然后递增计数器. 例如:
```
SELECT counter_field FROM child_codes FOR UPDATE;
UPDATE child_codes SET counter_field = counter_field + 1;
```

`SELECT ... FOR UPDATE` 读取最新的可用数据, 在其读取的每一行上设置排他锁. 因此, 它设置了与搜索的SQL UPDATE将在行上
设置的相同锁.

前面的描述仅仅是 `SELECT ... FOR UPDATE` 如何工作的一个例子. 在MySQL中, 生成唯一标识符的具体任务实际上只需对表进行
一次访问即可完成:
```
UPDATE child_codes SET counter_field = LAST_INSERT_ID(counter_field + 1);
SELECT LAST_INSERT_ID();
```

SELECT语句仅检索标识符信息(特定于当前连接). 它不访问任何表.

# 在 InnoDB 中通过不同的 SQL 语句设置的锁

锁定读取, UPDATE或DELETE通常会在SQL语句过程中扫描的每个索引记录上设置record lock. 语句中是否存在将排除该行的WHERE条
件并不重要. InnoDB不记得确切的WHERE条件, 但只知道扫描了哪些索引范围. 锁通常是next-key lock, 它也会阻止插入到记录之
前的"间隙"中. 但是, 可以显式禁用 gap lock, 这会导致不使用 next-key lock.

如果在搜索中使用了二级索引, 并且要设置的索引记录锁是独占的(X), InnoDB还会检索相应的聚簇索引记录并对它们设置锁定.

如果没有使用到适合语句的索引, 并且 MySQL 必须扫描整个表来处理该语句, 则表的每一行都会被锁定, 这反过来会阻止其他用户对表
的所有插入. 因此, 创建好的索引非常重要, 这样查询就不会不必要地扫描很多行.

InnoDB设置特定类型的锁, 如下所示:

- `SELECT ... FROM` 是一致性读, 读取数据库的快照并不设置锁, 除非事务隔离级别设置为 `SERIALIZABLE`. 对于 
`SERIALIZABLE` 级别, 搜索会在遇到的索引记录上设置共享的next-key lock. 但是, 对于使用唯一索引锁定行以搜索唯一行的语
句, 只需要设置record lock.

- 对于 `SELECT ... FOR UPDATE` 或 `SELECT ... LOCK IN SHARE MODE`, 为扫描的行获取锁定, 并且对于不符合包含在结
果集中的行, 预期会释放锁定(例如, 如果它们不符合 WHERE子句中给出的标准). 但是, 在某些情况下, 可能不会立即为行解锁, 因为
在查询执行期间结果行与其原始源之间的关系会丢失. 例如, 在UNION中, 表中的扫描(并锁定)行可能会在评估之前插入临时表中, 以确
定它们是否符合结果集的条件. 在这种情况下, 临时表中的行与原始表中的行的关系将丢失, 并且在查询执行结束之前不会解锁后面的行.

- `SELECT ... LOCK IN SHARE MODE` 在搜索遇到的所有索引记录上设置共享的next-key lock. 但是, 于使用唯一索引锁定行
以搜索唯一行的语句, 只需要设置 record lock.

- `SELECT ... FOR UPDATE` 在搜索遇到的每条记录上设置一个独占的next-key lock. 但是, 对于使用唯一索引锁定行以搜索唯
一行的语句, 只需要设置 record lock.

对于搜索遇到的索引记录, `SELECT ... FOR UPDATE` 阻止其他会话执行 `SELECT ... LOCK IN SHARE MODE` 语句 或 某些
事务隔离级别中的读取. 一致性读取将忽略在读取视图中在记录上设置的任何锁定.

- `UPDATE ... WHERE ...` 在搜索遇到的每条记录上设置一个独占的next-key lock. 但是, 对于使用唯一索引锁定行以搜索唯
一行的语句, 只需要设置 record lock.

- 当UPDATE修改聚簇索引记录时, 将对受影响的二级索引记录上采用隐式锁定. 在 "插入新的二级索引记录之前执行重复检查扫描" 以
及 "插入新的二级索引记录" 时, UPDATE操作会对受影响的二级索引记录上执行共享锁定.

- `DELETE FROM ... WHERE ...` 在搜索遇到的每条记录上设置一个独占的next-key lock. 但是, 对于使用唯一索引锁定行以
搜索唯一行的语句, 只需要设置 record lock.

- INSERT 在插入的行上设置独占锁. 此锁是record lock, 而不是next-key record(即没有间隙锁), 并且不会阻止其他会话在插
入行之前插入到间隙中.

在插入行之前, 设置一种称为"插入意图间隙锁定"的间隙锁定. 该锁定表示以这样的方式插入的意图: 如果插入到相同索引间隙中的多个
事务不插入间隙内的相同位置, 则不需要等待彼此.  假设存在值为4和7的索引记录. 尝试插入值5和6的单独事务在获取插入行上的排它
锁之前使用插入意向锁定锁定4和7之间的间隙, 但不因为行是非冲突的, 所以互相阻塞.

如果发生重复键错误, 则设置重复索引记录上的共享锁. 如果有多个会话尝试插入同一行, 如果另一个会话已经具有独占锁, 则使用共享
锁可能导致死锁. 如果另一个会话删除该行, 则会发生这种情况. 假设InnoDB表t1具有以下结构:
```
CREATE TABLE t1 (i INT, PRIMARY KEY (i)) ENGINE = InnoDB;
```

现在假设三个会话按顺序执行以下操作:
Session 1:
```
START TRANSACTION;
INSERT INTO t1 VALUES(1);
```

Session 2:
```
START TRANSACTION;
INSERT INTO t1 VALUES(1);
```

Session 3:
```
START TRANSACTION;
INSERT INTO t1 VALUES(1);
```

Session 1:
```
ROLLBACK;
```

会话1的第一个操作获取该行的互斥锁. 会话2和3的操作都会导致重复键错误, 并且它们都请求该行的共享锁. 当会话1回滚时, 它会释放
对该行的独占锁定, 并且会话2和3的排队共享锁请求被授予. 此时, 会话2和3死锁: 由于另一个持有共享锁, 因此都不能为该行获取排它
锁.


如果表已包含键值为1的行并且三个会话按顺序执行以下操作, 则会出现类似情况:
Session 1:
```
START TRANSACTION;
DELETE FROM t1 WHERE i = 1;
```

Session 2:
```
START TRANSACTION;
INSERT INTO t1 VALUES(1);
```

Session 3:
```
START TRANSACTION;
INSERT INTO t1 VALUES(1);
```

Session 1:
```
COMMIT;
```

会话1的第一个操作获取该行的排他锁. 会话2和3的操作都会导致重复键错误, 并且它们都请求该行的共享锁. 当会话1提交时, 它会释放
对该行的独占锁定, 并且会话2和3的排队共享锁定请求被授予. 此时, 会话2和3死锁: 由于另一个持有共享锁, 因此都不能为该行获取排
它锁.

- `INSERT ... ON DUPLICATE KEY UPDATE` 与简单的INSERT的不同之处在于, 当发生 duplicate-key 错误时, 在要更新的
行上设置独占锁而不是共享锁. 对重复的主键值采用独占 record lock. 对于重复的唯一键值, 采用独占 next-key lock.

- 如果唯一键上没有冲突, REPLACE 就像 INSERT 一样完成. 否则, 将在要替换的行上设置独占 next-key lock.

- `INSERT INTO T SELECT ... FROM S WHERE ...` 在插入T的每一行上设置一个独占 record lock(没有 gap lock). 如
果事务隔离级别为 RC, 或启用了 innodb_locks_unsafe_for_binlog 且事务隔离级别不是SERIALIZABLE, InnoDB将 S 上
的搜索作为一致读取(无锁). 否则, InnoDB 在来自 S 的行上设置共享 next-key lock. 在后一种情况下, InnoDB 必须设置锁: 
在使用基于语句的二进制日志的前滚恢复期间, 每个 SQL 语句必须以与它完全相同的方式执行.

`CREATE TABLE ... SELECT ...` 执行带有共享 next-key lock 的 SELECT 或作为一致读取, 与 `INSERT ... SELECT` 
一样.

当在构造中使用 `SELECT REPLACE INTO t SELECT ... FROM s WHERE ...` 或 `UPDATE t ... WHERE col IN (SELECT 
... FROM s ...)`时, InnoDB 为表中行设置共享 next-key lock.

- 在初始化表上的先前指定的 AUTO_INCREMENT 列时, InnoDB 在与 AUTO_INCREMENT 列关联的索引的末尾设置独占锁. 

当 `innodb_autoinc_lock_mode` 为0时, InnoDB 使用一种特殊的 AUTO-INC 表锁模式, 在访问自增量计数器时, 获取锁并保持
到当前SQL语句的末尾(而不是整个事务的末尾). 当 AUTO-INC 表锁被持有时, 其他客户端不能插入到表中. 

当 `innodb_autoinc_lock_mode` 为1时, "批量插入" 也会发生上述的相同行为.

表级 AUTO-INC 锁不与 `innodb_autoinc_lock_mode` 为2一起使用.

InnoDB 在不设置任何锁定的情况下获取先前初始化的AUTO_INCREMENT列的值.

- 如果在表上定义了 FOREIGN KEY 约束, 则任何需要检查约束条件的插入, 更新或删除都会在其查看的记录上设置 "共享record lock" 
以检查约束. 在约束检查失败的情况下, InnoDB 还是会设置这些锁.

- `LOCK TABLES` 设置表锁, 但设置这些锁是在 MySQL 层设置. 如果 innodb_table_locks=1(默认值) 和 autocommit=0,
则 InnoDB 知道表锁, 并且 MySQL 层知道行级锁.

否则, InnoDB 的自动死锁检测无法检测涉及此类表锁的死锁. 此外, 在这种情况下, MySQL 层不知道行级锁, 所以有可能在另外一个
会话当前具有行级锁的表上获得表锁, 但这不破坏事务的完整性.

- 如果 innodb_table_locks=1, `LOCK TABLES` 在每个表上获取两个锁. 除了 MySQL 层的表锁之外, 它还获取了 InnoDB 表
锁. 要避免获取 InnoDB 表锁, 设置 innodb_table_locks=0. 如果没有获取到 InnoDB 表锁, `LOCK TABLES` 也会完成.

在 MySQL 5.7 中, innodb_table_locks=0 对使用 `LOCK TABLES ... WRITE` 显示锁定的表没有影响. 它对通过 `LOCK
TABLES ... WRITE` 隐式(eg: triggers) 或 `LOCK TABLES ... READ` 锁定以进行读或写的表有影响

- 当事务提交或终止时, 事务持有的所有 InnoDB 锁都会被释放. 因此, 在 autocommit=1 模式下对 InnoDB 表调用 `LOCK TABLES`
没有多大意义, 因为获取的 InnoDB 表锁将立即释放.

- 不能在事务中间锁定其他表, 因为 `LOCK TABLES` 执行隐式 COMMIT 和 `UNLOCK TABLES`.

# 幻读行

在一个事务中, 当同一个查询在不同的时间产生不同的结果集时, 事务就产生了所谓的幻读现象. 例如, 一个SELECT 执行了两次, 但第
二次返回了第一次没有返回的行, 则该行是"幻"行.

假设 child 表的 id 列加上索引, 并且想要读取并锁定表中 id 大于 100 的所有行, 以便稍后更改选中行的某些列:                   

![image](/images/mysql_innodb_trx_phantom_read.png)

此时在 Session A 当中查询的结果会出现 id 为 101 的行("幻读"). 

为了防止幻读, InnoDB 使用了 next-key lock 算法. 该算法将 gap lock 和 record lock 相结合.

InnoDB 执行行级锁的方式: 当它搜索或扫描表索引时, 它会在遇到的索引记录上设置共享锁或互斥锁. 因此, 行级锁实际上是索引记录
锁. 索引记录上的 next-key lock 也会影响该索引记录之前的"间隙". 也就是说, next-key lock是 "索引记录锁" + "索引记录
之前的间隙上的间隙锁". 如果一个会话在索引中的记录R上具有共享或互斥锁, 则另一个会话不能在索引顺序中的R之前的间隙中插入新的
索引记录.

InnoDB 在扫描索引时, 还可以锁定索引中最后一条记录之后的间隙. 在前面的例子中就是这样: 为了防止任何插入 id 大于 100 的记
录到表中, InnoDB 设置的锁包括 id 值 102 之后的间隙上的锁.

可以使用 next-key lock 在应用程序中实现唯一性检查: 如果你在共享锁下读取数据, 并且没有插入重复项, 那么你可以安全地插入
行, 因为 next-key lock 可以防止任何人同时插入重复的项. 因此, next-key lock 能够锁定表中不存在的东西. (MySQL实现"
分布式锁"的原理.)  

# Lock 规则

加锁的原则, 包含两个"原则", 两个"优化", 一个"bug".

- 原则1: **加锁的基本单位是 next-key lock.** 

- 原则2: **查找过程中访问到的对象才会加锁.**

- 优化1: **索引上的等值查询, 给唯一索引加锁时, next-key lock 退化为 record lock.**

- 优化2: **索引上的等值查询, 向右遍历时且最后一个值不满足条件时, next-key lock 退化为 gap lock.**

- 一个bug: **唯一索引上的 '范围查找' 会访问到 '不满足条件的第一个值' 为止.**

> 针对 "一个bug" 的前提是 "范围查找", 如果没有这个前提, 则不会有下文.

下面的案例的数据: 

```
CREATE TABLE `t` (
  `id` int(11) NOT NULL,
  `c` int(11) DEFAULT NULL,
  `d` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `c` (`c`)
) ENGINE=InnoDB;

insert into t values(0,0,0),(5,5,5),(10,10,10),(15,15,15),(20,20,20),(25,25,25);
```

### 案例1: 等值查询

![image](/images/mysql_lock_equal_value.png)

1)表t当中没有 id=7 的记录. 根据原则1, 单位是next-key lock, session A 锁定范围是 (5, 10]. 

2)根据优化2, 这是一个等值查询(id=7), 而 id=10 不满足条件, next-key lock退化为gap lock. 锁定范围是 (5, 10)

### 案例2: 非唯一索引等值

![image](/images/mysql_lock_not_unique_equal_value.png)

1)根据原则1, 加锁单位是next-key lock, session A 锁定范围是 (0, 5]. 

2)由于 c 是普通索引, 因此仅访问 c=5 这一条记录不能马上停下来, 需要向右边遍历, 查找到10. 根据原则2, 访问到的对象都要加
锁, 因此 (5,10] 加锁.

3)根据优化2, 等值判断, 向右遍历, 最后一个值不满足 c=5 的条件, 退化味为 gap lock, 锁定范围(5,10)

4)根据原则2, 只有访问到的对象才加锁, 这个查询使用索引覆盖, 并不需要访问主键索引, 因此主键索引不加锁.


### 案例3: 主键索引范围

![image](/images/mysql_lock_unique_range_value.png)

1)开始执行, 查找到第一个id=10的行, 锁定 (5, 10], 根据优化1, 主键索引等值查询, 退化为行锁, 只是锁定 id=10 这一行.

2)id 上的范围查询, 找到第一个不满足要求才停止(id=15), 加锁 (10, 15].

> 需要注意, 在第2步, 是根据 id<11 的条件停止下来的, 没有等值查询, 因此, 不能使用优化2.

### 案例4: 非唯一索引范围

![image](/images/mysql_lock_not_unique_range_value.png)

1)开始执行, 查找到第一个c=10的记录, 所以锁定范围是 (5, 10]. 注意, c是普通索引不能使用优化1.

2)根据原则2, 继续查询到 c=15, 满足 c<11 的条件, 锁定范围 (10, 15]. 注意, 这里需要扫描到 c=15 才停止扫描, 是合理的.

### 案例5: 唯一索引范围

![image](/images/mysql_lock_unique_range_value.png)

1)开始查询, 首先查找到第一个 id=15 的记录(由于id=10不满足 id>10 的条件, 因此这个值被忽略), 根据原则1, 加锁范围(10,15]

2)id=15是满足 id>=15 的范围查询的, 根据bug, 需要扫描到第一个不满足条件的值(id=20), 加锁范围为 (15,20]

### 案例6: 非唯一索引存在"等值"

在这里, 先需要向 t 当中插入一条数据: `insert into t values(30,10,30)`.

虽然有两个 c=10, 但是它们的主键id是不同的(分别是10和30), 因此这两个c=10的记录之间, 是有间隙的.

![image](/images/mysql_lock_not_unique_exist_equal_value.png)

1)开始查询, 首先查找到第一个 c=10 的索引记录(10,10), 加锁索引范围是 ((5,5), (10,10)]

2)继续向右查找, 直到碰到(15,15) 索引记录, 循环结束. 根据优化2, 等值查询, 向右查询不满足条件, 退化成了 gap lock, 锁定
范围 ((10,10), (15,15))

### 案例7: limit 语句

在这里, 先需要向 t 当中插入一条数据: `insert into t values(30,10,30)`

![image](/images/mysql_lock_limit.png)

1)开始查询, 首先查找到第一个 c=10 的索引记录(10,10), 由于 `limit 2`, 只需要再查找到一个 c=10 的记录(如果存在的话),
就停止查找了, 这里是查找到了 (10,30), 因此加锁范围是 ((5,5), (10,30))].

`limit` 会限制查找的范围, 从而缩小查找的范围. 如果查找过程中不能满足 limit 条件, 这时候 limit 就失去了缩小范围的作用
了.

### 案例8: 死锁

![image](/images/mysql_lock_deadlock.png)

1)session A, 在索引 c 上加锁范围: (5, 10] 和 (10, 15)

2)session B的 update 语句要在 c 上锁定范围 (5, 10], 进入锁等待.

3)session A再次插入(8,8,8)这一行, 被session B的间隙锁锁住. 由于出现死锁, InnoDB 让 session B 回滚.

注意, session B的 next-key lock (5,10] 是分为两步的, 先加(5,10) 间隙锁, 成功; 然后加 c=10 行锁, 这时候阻塞.

### 案例9: 不等号条件里的等值查询

![image](/images/mysql_lock_not_equal_value.png)

