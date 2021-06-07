# Innodb 锁

锁的种类一般分为乐观锁和悲观锁两种, **InnoDB存储引擎中使用是的悲观锁**.

乐观锁和悲观锁其实都是并发控制, 同时它们在实现原理上有着本质的差别:

- 乐观锁是一种思想, 它并不是一种真正的锁. 它会先尝试对资源进行修改, 在写回时判断其他人是否修改了该资源, 如果没有发生改变就会
写回, 否则会进行重试, 在整个的执行过程中其实都没有对数据库进行加锁. (CAS就是乐观锁)

- 悲观锁是一种真正的锁. 它会在获取资源前对资源进行加锁, 确保同一时刻有有限的线程能够访问该资源, 其它想要尝试获取资源的操作都
会进入等待状态, 直到该线程完成了对资源的操作并且释放了锁后, 其它线程才能重新操作资源. (LOCK)

对数据的操作其实只有两种, 也就是读和写, 而数据库在实现锁时, 也会对这两种操作使用不同的锁; InnoDB 实现了标准的行级锁, 也就
是共享锁(S)和互斥锁(X)

## 共享锁和独占锁

InnoDB实现标准的行级锁定, 其中有两种类型的锁, 即shared(S)锁和exclusive(X)锁.

- 共享(S)锁(读锁): 允许事务对一条数据进行读取.

- 独占(X)锁(写锁): 允许事务对一条数据进行更新或删除.


## Intention Lock (意向锁)

无论是共享锁还是互斥锁其实都只是对某一行数据进行加锁, InnoDB支持多个粒度锁定, 也就是行锁和表锁. 为了实现多个粒度级别的锁定, 
InnoDB引入了意向锁(Intention Lock), **意向锁是表级锁**, 表示事务对于该表中的某一行稍后需要哪种类型的锁(S或X). 

InnoDB有两种类型的意向锁使用:

- 意向共享锁(IS): 事务想要在获得表中某些记录的共享锁, 需要在表上先加意向共享锁;
- 意向互斥锁(IX): 事务想要在获得表中某些记录的互斥锁, 需要在表上先加意向互斥锁;

例如, `SELECT ... LOCK IN SHARE MODE` 设置IS锁定, `SELECT ... FOR UPDATE` 设置IX锁定.

意向锁定协议如下:
- 在一个事物可以获得一个表中一行的共享锁之前, 它必须首先获得这张表的IS锁或这张表的更强的锁.
- 在一个事务可以获得一个表中一行的互斥锁之前, 它必须先获得这张表IX锁.

这些规则可以通过下面的锁类型兼容性矩阵方便地总结.

|  | X | IX | S | IS |
| --- | --- | --- | --- | --- |
| X | ✗ | ✗ | ✗ | ✗ |
| IX | ✗ | ✔ | ✗ | ✔ |
| S | ✗ | ✗ | ✔ | ✔ |
| IS | ✗ | ✔ | ✔ | ✔ |

如果请求的事务与现有的锁定兼容, 授予锁定, 但如果它与现有的锁定冲突, 则锁定将被拒绝. 事务一直等到有冲突的锁被释放. 如果加
锁请求与现有的锁发生冲突, 锁无法被授予, 因为它会导致死锁, 且会发生错误.

因此, 意图锁只会阻塞全表请求(例如, LOCK TABLES ... WRITE). 意图锁的主要目的是显示某人正锁定一行, 或将要锁定表中的一
行.

意图锁定的事务数据在 `SHOW ENGINE INNODB STATUS` 和 InnoDB 监视器输出中的以下内容类似:
```
TABLE LOCK table `test`.`t` trx id 10080 lock mode IX
```

## Record Locks (记录锁定)

记录锁定是对索引记录的锁定. 例如, SELECT c1 FROM t WHERE c1 = 10 FOR UPDATE; 阻止其他任何事务插入, 更新 或 删除
t.c1的值为10的行.

记录锁也始终锁定索引记录, 即使是一个没有索引的表. 对于这种情况, InnoDB创建一个隐藏的clustered index并使用此索引进行记
录锁定.

记录锁的事务数据在 `SHOW ENGINE INNODB STATUS` 和 InnoDB监视器输出中显示类似于以下内容:
```
RECORD LOCKS space id 58 page no 3 n bits 72 index `PRIMARY` of table `test`.`t` 
trx id 10078 lock_mode X locks rec but not gap
Record lock, heap no 2 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 8000000a; asc     ;;
 1: len 6; hex 00000000274f; asc     'O;;
 2: len 7; hex b60000019d0110; asc        ;;
```

## Gap Locks (间隙锁定)

间隙锁定是锁定索引记录之间的间隙, 或锁定在第一个或最后一个索引记录之前的间隙. 
例如, `SELECT c1 FROM t WHERE c1 BETWEEN 10和20 FOR UPDATE;` 会阻止其他事务将值15插入到列t.c1中, 无论列中是否
已存在任何此类值, 因为该范围内所有现有值之间的间隔都被锁定.

间隙可能跨越单个索引值或多个索引值, 甚至可能为空.

> 间隙锁定是性能和并发之间权衡的一部分, 用于某些事务隔离级别而不是其他级别.

使用唯一索引锁定行以搜索唯一行的语句不需要间隙锁定. (这不包括搜索条件仅包含多列唯一索引的某些列的情况; 在这种情况下, 确实
会发生间隙锁定.) 例如, 如果id列具有唯一索引, 则以下语句仅使用具有id值100的行的索引记录锁定, 其他会话是否在前一个间隙中插
入行无关紧要:
```
SELECT * FROM child WHERE id=100;
```

如果id未编入索引或具有非唯一索引, 则该语句会锁定前一个间隙.
此处值得注意的是, 冲突锁可以通过不同的事务保持在间隙上. 例如, 事务A可以在间隙上保持共享间隙锁定(间隙S锁定), 而事务B在同
一间隙上保持独占间隙锁定(间隙X锁定). 允许冲突间隙锁定的原因是, 如果从索引中清除记录, 则必须合并由不同事务保留在记录上的间
隙锁定.

InnoDB 中的间隙锁定是"purely inhibitive(纯粹的抑制)", 这意味着它们的唯一目的是防止其他事务插入间隙. 差距锁可以共存.
一个事务占用的间隙锁定不会阻止另一个事务在同一个间隙上进行间隙锁定. 共享和独占间隙锁之间没有区别. 它们彼此不冲突, 它们执行
相同的功能.

可以明确禁用间隙锁定, 如果将事务隔离级别更改为 `READ COMMITTED` 或启用innodb_locks_unsafe_for_binlog系统变量(现
已弃用,5.7), 则会发生这种情况. 在这些情况下, 对于搜索和索引扫描禁用间隙锁定, 并且间隙锁定仅用于外键约束检查和重复键检查.

使用 `READ COMMITTED` 隔离级别或启用innodb_locks_unsafe_for_binlog还有其他影响. 在MySQL评估WHERE条件后,将释放
不匹配行的记录锁. 对于UPDATE语句, InnoDB执行"semi-consistent(半一致)"读取, 以便将最新提交的版本返回给MySQL, 以便
MySQL可以确定该行是否与 UPDATE 的 WHERE条件匹配.

## Next-Key Locks (下一键锁定)

下一键锁定是索引记录上的记录锁定和索引记录之前的间隙上的间隙锁定的组合.

InnoDB以这样一种方式执行行级锁定: 当它搜索或扫描表索引时, 它会在遇到的索引记录上设置共享锁或互斥锁. 因此, 行级锁实际上是
索引记录锁. 索引记录上的下一键锁定也会影响该索引记录之前的"间隙". 也就是说, 下一键锁定是索引记录锁定加上索引记录之前的间隙
上的间隙锁定. 如果一个会话在索引中的记录R上具有共享或互斥锁, 则另一个会话不能在索引顺序中的R之前的间隙中插入新的索引记录.

假设索引包含值10, 11, 13和20. 此索引的可能的下一个键锁定覆盖以下间隔, 其中圆括号表示排除间隔端点, 方括号表示包含端点:

```
(-oo, 10]
(10, 11]
(11, 13]
(13, 20]
(20, +oo)
```

对于最后一个间隔, 下一个键锁定将间隙锁定在索引中最大值之上, 而"supremum"伪记录的值高于索引中实际的任何值. supremum不是
真正的索引记录, 因此, 实际上, 此下一键锁定仅锁定最大索引值之后的间隙.

默认情况下, InnoDB在 `REPEATABLE READ` 事务隔离级别运行. 在这种情况下, InnoDB使用下一键锁进行搜索和索引扫描. 从而
防止幻读行.

下一键锁的事务数据类似于 `SHOW ENGINE INNODB STATUS` 和 `InnoDB` 监视器输出中的以下内容:
```
RECORD LOCKS space id 58 page no 3 n bits 72 index `PRIMARY` of table `test`.`t` 
trx id 10080 lock_mode X
Record lock, heap no 1 PHYSICAL RECORD: n_fields 1; compact format; info bits 0
 0: len 8; hex 73757072656d756d; asc supremum;;

Record lock, heap no 2 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 8000000a; asc     ;;
 1: len 6; hex 00000000274f; asc     'O;;
 2: len 7; hex b60000019d0110; asc        ;;
```

## Insert Intention Locks (插入意图锁定)

插入意图锁定是在行插入之前由INSERT操作设置的一种间隙锁定. 该锁定表示以这样的方式插入的意图: 如果插入到相同索引间隙中的多
个事务不插入间隙内的相同位置, 则不需要等待彼此. 假设存在值为4和7的索引记录. 分别尝试插入值5和6的单独事务, 在获取插入行上
的互斥锁之前, 每个锁定4和7之间的间隙和插入意图锁, 但是不要互相阻塞因为行是非冲突的.

以下示例演示了在获取插入记录的独占锁之前采用插入意图锁定的事务. 该示例涉及两个客户端, A和B.

客户端A创建一个包含两个索引记录(90和102)的表, 然后启动一个事务, 该事务对ID大于100的索引记录放置独占锁. 独占锁包括记录
102之前的间隙锁:
```
mysql> CREATE TABLE child (id int(11) NOT NULL, PRIMARY KEY(id)) ENGINE=InnoDB;
mysql> INSERT INTO child (id) values (90),(102);

mysql> START TRANSACTION;
mysql> SELECT * FROM child WHERE id > 100 FOR UPDATE;
```

客户端B开始事务以将记录插入间隙. 该事务在等待获取独占锁时采用插入意图锁.
```
mysql> START TRANSACTION;
mysql> INSERT INTO child (id) VALUES (101);
```

插入意图锁的事务数据 `SHOW ENGINE INNODB STATUS` 和InnoDB监视器输出中的以下内容类似:
```
RECORD LOCKS space id 31 page no 3 n bits 72 index `PRIMARY` of table `test`.`child`
trx id 8731 lock_mode X locks gap before rec insert intention waiting
Record lock, heap no 3 PHYSICAL RECORD: n_fields 3; compact format; info bits 0
 0: len 4; hex 80000066; asc    f;;
 1: len 6; hex 000000002215; asc     " ;;
 2: len 7; hex 9000000172011c; asc     r  ;;...
```

## AUTO-INC Locks

AUTO-INC锁定是由插入到具有 `AUTO_INCREMENT` 列的表中的事务所采用的特殊表级锁. 在最简单的情况下, 如果一个事务正在向表
中插入值, 则任何其他事务必须等待对该表执行自己的插入, 以便第一个事务插入的行接收连续的主键值.

innodb_autoinc_lock_mode配置选项控制用于自动增量锁定的算法. 它允许您选择如何在可预测的自动增量值序列和插入操作的最大
并发之间进行权衡.

---


# Transaction (事物)

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

## REPEATABLE READ

这是InnoDB的默认隔离级别. 同一事务中的一致读取读取第一次读取建立的快照. 这意味着如果在同一事务中发出多个普通(非锁定)
SELECT语句, 则这些SELECT语句也相互一致.

对于锁定读取(使用`FOR UPDATE` 或 `LOCK IN SHARE MODE`的 SELECT), UPDATE 和 DELETE语句, 锁定取决于语句是使用具
有唯一搜索条件的唯一索引还是范围类型搜索条件.

- 对于具有唯一搜索条件的唯一索引, InnoDB仅锁定找到的索引记录, 而不是之前的间隙.

- 对于其他搜索条件, InnoDB锁定扫描的索引范围, 使用间隙锁或下一键锁来阻止其他会话插入范围所覆盖的间隙.

## READ COMMITTED

即使在同一事务中, 每个一致的读取也会设置和读取自己的新快照.

对于锁定读取(使用 `FOR UPDATE` 或 `LOCK IN SHARE MODE` 的SELECT), UPDATE 语句和DELETE语句, InnoDB仅锁定索引记录, 而不锁
定它们之前的间隙, 因此允许在锁定记录旁边自由插入新记录. 间隙锁定仅用于外键约束检查和重复键检查.

由于禁用了间隙锁定, 因此可能会出现幻像问题, 因为其他会话可以在间隙中插入新行.

READ COMMITTED 隔离级别仅支持基于行的二进制日志记录. 如果对binlog_format=MIXED使用READ COMMITTED, 则服务器会自
动使用基于行的日志记录.

使用READ COMMITTED还有其他影响:
- 对于UPDATE或DELETE语句, InnoDB仅为其更新或删除的行保留锁定. MySQL评估WHERE条件后, 将释放不匹配行的记录锁. 这大大
降低了死锁的可能性, 但它们仍然可以发生.

- 对于UPDATE语句, 如果一行已被锁定, InnoDB将执行"semi-consistent(半一致)"读取, 将最新提交的版本返回给MySQL, 以便
MySQL可以确定该行是否与 UPDATE 的 WHERE 条件匹配. 如果行匹配(必须更新), MySQL再次读取该行, 这次InnoDB将其锁定或等
待锁定.

案例:
```
CREATE TABLE t (a INT NOT NULL, b INT) ENGINE=InnoDB;
INSERT INTO t VALUES (1,20, (2,3), (3,2), (4,3), (5,2);
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
锁. 否则, InnoDB会保留锁定, 直到事物结束. 这会影响事务处理, 如下所示.

使用默认的 `REPEATABLE READ` 隔离级别时, 第一个UPDATE在它读取的每一行上获取一个X锁, 并且不释放它们中的任何一个:
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

如果使用 `READ COMMITTED`, 则第一个UPDATE会在其读取的每一行上获取一个X锁, 并释放那些不会修改的行:
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

使用 `READ COMMITTED` 隔离级别的效果与启用不推荐使用的innodb_locks_unsafe_for_binlog配置选项相同, 但有以下例外:

- 启用innodb_locks_unsafe_for_binlog是一个全局设置, 会影响所有会话, 而隔离级别可以为所有会话全局设置, 也可以为每个
会话单独设置.

- innodb_locks_unsafe_for_binlog只能在服务器启动时设置, 而隔离级别可以在启动时设置或在运行时更改.

因此, `READ COMMITTED` 提供比innodb_locks_unsafe_for_binlog更精细和更灵活的控制.

## READ UNCOMMITED

SELECT语句以非锁定方式执行, 但可能使用行的早期版本. 因此, 使用此隔离级别, 此类读取不一致. 这也称为脏读. 否则, 此隔离级
别与 `READ COMMITTED` 类似.

## SERIALIZABLE

此级别与 `REPEATABLE READ` 类似, 如果禁用自动提交, InnoDB将隐式地将所有普通 SELECT 语句转换为 
`SELECT ... LOCK IN SHARE MODE`. 如果启用了自动提交, 则 SELECT 是其自己的事务. 因此, 由于它是只读的, 并且如果作
为一致(非锁定)读取执行则可以序列化, 并且不需要阻止其他事务. (要强制普通SELECT阻止其他事务已修改所选行, 请禁用自动提交)

---

# 读取

## Consistent Nonlocking Reads (一致性非锁定读取)

一致的读取意味着InnoDB使用多版本控制在某个时间点向查询提供数据库的快照. 查询将查看在该时间点之前提交的事务所做的更改, 并
且不会对以后或未提交的事务所做的更改进行更改. 

此规则的例外是查询查看同一事务中早期语句所做的更改. 此异常导致以下异常: 如果更新表中的某些行, SELECT 将查看更新行的最新
版本, 但它也可能会看到任何行的旧版本. 如果其他会话同时更新同一个表, 则异常意味着可能会看到该表处于从未存在于数据库中的状态.

如果事务隔离级别是 `REPEATABLE READ`(默认级别), 则同一事务内的所有一致性读取将读取该事务中第一次读取所创建的快照. 你
可以通过提交当前事务并在发出新查询之后为查询获取更新的快照.

使用 `READ COMMITTED` 隔离级别, 事务中的每个一致读取都会设置并读取其自己的新快照.

一致性读取是 InnoDB 在 `READ COMMITTED`和 `REPEATABLE READ` 隔离级别中处理SELECT语句的默认模式. 一致读取不会对
其访问的表设置任何锁定, 因此其他会话可以在对表执行一致读取的同时自由修改这些表.

假设你正在以默认的 `REPEATABLE READ` 隔离级别运行. 当你发出一致读取(即普通SELECT语句)时, InnoDB 会为你的事务提供一
个时间点, 你的查询将根据该时间点查看数据库. 如果另一个事务删除了一行并在分配了你的时间点后提交, 则你不会将该行视为已删除.
插入和更新的处理方式类似.

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
```
             Session A              Session B

           SET autocommit=0;      SET autocommit=0;
time
|          SELECT * FROM t;
|          empty set
|                                 INSERT INTO t VALUES (1, 2);
|
v          SELECT * FROM t;
           empty set
                                  COMMIT;

           SELECT * FROM t;
           empty set

           COMMIT;

           SELECT * FROM t;
           ---------------------
           |    1    |    2    |
           ---------------------
```

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


## Locking Reads (锁定读取)

如果查询数据然后在同一事务中插入或更新相关数据, 则常规SELECT语句不会提供足够的保护. 其他事务可以更新或删除你刚查询的相同
行. InnoDB支持两种类型的锁定读取, 提供额外的安全性:

- SELECT ... LOCK IN SHARE MODE

在读取的任何行上设置共享模式锁定. 其他会话可以读取行, 但在事务提交之前无法修改它们. 如果这些行中的任何行已被另一个尚未提交
的事务更改, 则查询将等待该事务结束. 然后使用最新值.

- SELECT ... FOR UPDATE

对于搜索遇到的索引记录, 锁定行和任何关联的索引条目, 就像为这些行发出UPDATE语句一样. 阻止其他事务更新这些行, 从进行
`SELECT ... LOCK IN SHARE MODE`, 或从某些事务隔离级别读取数据. 一致性读取将忽略在读取视图中存在的记录上设置的任何锁
定. (旧版本的记录无法锁定; 它们通过在记录的内存中副本上应用撤消日志来重建.)


这些子句在处理树形结构或图形结构数据时非常有用, 无论是在单个表中还是在多个表中分割. 你将边缘或树枝从一个地方遍历到另一个地
方, 同时保留返回并更改任何这些"指针"值的权限.

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

假设你要在表子项中插入新行, 并确保子行在表父项中具有父行. 你的应用程序代码可确保整个操作序列中的引用完整性.

首先, 使用一致性读取来查询表PARENT并验证父行是否存在. 你能安全地将子行插入表CHILD吗? 不, 因为其他一些会话可以删除
SELECT和INSERT之间的父行, 而不会意识到它.

要避免此潜在问题, 请使用LOCK IN SHARE MODE执行SELECT:
```
SELECT * FROM parent WHERE NAME = 'Jones' LOCK IN SHARE MODE;
```

在 `LOCK IN SHARE MODE` 查询返回父"Jones"后, 你可以安全地将子记录添加到CHILD表并提交事务. 尝试获取PARENT表中适用
行的独占锁的任何事务都会等到完成后, 即直到所有表中的数据都处于一致状态.


再例如, 考虑表CHILD_CODES中的整数计数器字段, 用于为添加到表CHILD的每个子项分配唯一标识符. 不要使用一致读取或共享模式读
取来读取计数器的当前值, 因为数据库的两个用户可能看到计数器的相同值, 并且如果两个事务尝试添加行, 则会发生重复键错误与CHILD
表相同的标识符.

这里, `LOCK IN SHARE MODE` 不是一个好的解决方案, 因为如果两个用户同时读取计数器, 则当它们尝试更新计数器时, 其中至少有
一个会陷入死锁.

要实现读取和递增计数器, 首先使用 `FOR UPDATE` 执行计数器的锁定读取, 然后递增计数器. 例如:
```
SELECT counter_field FROM child_codes FOR UPDATE;
UPDATE child_codes SET counter_field = counter_field + 1;
```

`SELECT ... FOR UPDATE` 读取最新的可用数据, 在其读取的每一行上设置独占锁. 因此, 它设置搜索的SQL UPDATE将在行上设置
的相同锁.

前面的描述仅仅是 `SELECT ... FOR UPDATE` 如何工作的一个例子. 在MySQL中, 生成唯一标识符的具体任务实际上只需对表进行
一次访问即可完成:
```
UPDATE child_codes SET counter_field = LAST_INSERT_ID(counter_field + 1);
SELECT LAST_INSERT_ID();
```

SELECT语句仅检索标识符信息(特定于当前连接). 它不访问任何表.

# 在InnoDB中通过不同的SQL语句设置的锁

锁定读取, UPDATE或DELETE通常会在处理SQL语句时扫描的每个索引记录上设置记录锁定. 在语句中是否存在排除该行的WHERE条件并
不重要. InnoDB不记得确切的WHERE条件, 但只知道扫描了哪些索引范围. 锁通常是下一键锁, 它也会阻止插入到记录之前的"间隙"中.
但是, 可以显式禁用间隙锁定, 这会导致不使用下一键锁定.

如果在搜索中使用了二级索引, 并且要设置的索引记录锁是独占的, InnoDB还会检索相应的聚簇索引记录并对它们设置锁定.

如果没有适合语句的索引, 并且MySQL必须扫描整个表来处理该语句, 则表的每一行都会被锁定, 这反过来会阻止其他用户对表的所有插入.
创建好的索引非常重要, 这样查询就不会不必要地扫描很多行.

InnoDB设置特定类型的锁, 如下所示:

- `SELECT ... FROM` 是一致的读取, 读取数据库的快照并设置无锁, 除非事务隔离级别设置为 `SERIALIZABLE`. 对于 
`SERIALIZABLE` 级别, 搜索会在遇到的索引记录上设置共享的下一键锁定. 但是, 对于使用唯一索引锁定行以搜索唯一行的语句, 只
需要索引记录锁定.

- 对于 `SELECT ... FOR UPDATE` 或 `SELECT ... LOCK IN SHARE MODE`, 为扫描的行获取锁定, 并且对于不符合包含在结
果集中的行, 预期会释放锁定(例如, 如果它们不符合 WHERE子句中给出的标准.) 但是, 在某些情况下, 行可能不会立即解锁, 因为在
查询执行期间结果行与其原始源之间的关系会丢失. 例如, 在UNION中, 表中的扫描(和锁定)行可能会在评估之前插入临时表中, 以确定
它们是否符合结果集的条件. 在这种情况下, 临时表中的行与原始表中的行的关系将丢失, 并且在查询执行结束之前不会解锁后面的行.

- `SELECT ... LOCK IN SHARE MODE` 在搜索遇到的所有索引记录上设置共享的下一键锁定. 但是, 于使用唯一索引锁定行以搜索
唯一行的语句, 只需要索引记录锁定.

- `SELECT ... FOR UPDATE` 在搜索遇到的每条记录上设置一个独占的下一键锁定. 但是, 对于使用唯一索引锁定行以搜索唯一行的
语句, 只需要索引记录锁定.

对于搜索遇到的索引记录, `SELECT ... FOR UPDATE` 阻止其他会话执行 `SELECT ... LOCK IN SHARE MODE` 或某些事务隔
离级别中的读取. 一致性读取将忽略在读取视图中存在的记录上设置的任何锁定.

- `UPDATE ... WHERE ...` 在搜索遇到的每条记录上设置一个独占的下一键锁定. 但是, 对于使用唯一索引锁定行以搜索唯一行的
语句, 只需要索引记录锁定.

- 当UPDATE修改聚簇索引记录时, 将对受影响的辅助索引记录采用隐式锁定. 在插入新的辅助索引记录之前以及插入新的辅助索引记录时,
UPDATE操作还会在受影响的辅助索引记录上执行共享锁定.

- `DELETE FROM ... WHERE ...` 在搜索遇到的每条记录上设置一个独占的下一键锁定. 但是, 对于使用唯一索引锁定行以搜索唯
一行的语句, 只需要索引记录锁定.

- INSERT在插入的行上设置独占锁. 此锁是索引记录锁, 而不是下一键锁(即没有间隙锁), 并且不会阻止其他会话在插入行之前插入间隙.

在插入行之前, 设置一种称为"插入意图间隙锁定"的间隙锁定. 该锁定表示以这样的方式插入的意图: 如果插入到相同索引间隙中的多个
事务不插入间隙内的相同位置, 则不需要等待彼此.  假设存在值为4和7的索引记录. 尝试插入值5和6的单独事务在获取插入行上的排它
锁之前使用插入意图锁定锁定4和7之间的间隙, 但不因为行是非冲突的, 所以互相阻塞.

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

会话1的第一个操作获取该行的互斥锁. 会话2和3的操作都会导致重复键错误, 并且它们都请求该行的共享锁. 当会话1提交时, 它会释放
对该行的独占锁定, 并且会话2和3的排队共享锁定请求被授予. 此时, 会话2和3死锁: 由于另一个持有共享锁, 因此都不能为该行获取排
它锁.

- `INSERT ... ON DUPLICATE KEY UPDATE` 与简单的INSERT的不同之处在于, 当发生重复键错误时, 在要更新的行上放置独占
锁而不是共享锁. 对重复的主键值采用独占索引记录锁定. 对于重复的唯一键值, 采用独占的下一键锁定.

- 如果唯一键上没有冲突, REPLACE就像INSERT一样完成. 否则, 将在要替换的行上设置独占的下一键锁.

- `INSERT INTO T SELECT ... FROM S WHERE ...` 在插入T的每一行上设置一个独占索引记录锁(没有间隙锁). 如果事务隔离
级别为`READ COMMITTED`, 或者启用了innodb_locks_unsafe_for_binlog且事务隔离级别不是SERIALIZABLE, InnoDB将S上
的搜索作为一致读取(无锁). 否则, InnoDB在来自S的行上设置共享的下一键锁. 在后一种情况下, InnoDB必须设置锁: 在使用基于语
句的二进制日志的前滚恢复期间, 每个SQL语句必须以与它完全相同的方式执行.

`CREATE TABLE ... SELECT ...` 执行带有共享下一键锁定的SELECT或作为一致读取, 与 `INSERT ... SELECT` 一样.

当在构造中使用 `SELECT REPLACE INTO t SELECT ... FROM s WHERE ...` 或 `UPDATE t ... WHERE col IN (SELECT 
... FROM s ...)`时, InnoDB设置共享的下一键锁表中的行.

- 在初始化表上的先前指定的AUTO_INCREMENT列时, InnoDB在与AUTO_INCREMENT列关联的索引的末尾设置独占锁. 在访问自动增量
计数器时, InnoDB使用特定的AUTO-INC表锁定模式, 其中锁定仅持续到当前SQL语句的末尾, 而不是整个事务的结束. 在保持AUTO-INC
表锁时, 其他会话无法插入表中;

InnoDB在不设置任何锁定的情况下获取先前初始化的AUTO_INCREMENT列的值.

- 如果在表上定义了FOREIGN KEY约束, 任何需要检查约束条件的插入,更新或删除都会在其查看的记录上设置 "共享记录级锁" 定以检
查约束. 在约束检查失败的情况下, InnoDB还是会设置这些锁.
