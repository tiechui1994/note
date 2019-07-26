# Innodb 锁

## 共享和独占锁定

InnoDB实现标准行级锁定, 其中有两种类型的锁, 即shared(S)锁和exclusive(X)锁.

- 一个共享(S)锁允许持有锁读取行的事务.

- 一个独占(X)锁允许持有锁, 更新或删除行的事务.

如果事务在行上T1持有共享(S)锁r, 那么来自某个不同事务的T2对锁定行的请求r将按如下方式处理:
  a) 由A请求T2用于S锁可以立即被授予. 其结果是, 无论是T1与T2持有S的锁r.
  b) 通过请求T2一个X锁不能立即授予.

如果一个事务T1持有一个exclusive(X)锁定行r, 那么不能立即授予来自某个不同事务T2的任何一个类型的锁的请求r. 相反,事务T2必
须等待事务T1才能释放行上的锁r.


## Intention Locks (意图锁)

InnoDB支持多个粒度锁定, 允许在整个表上共存行级锁和锁. 为了实现多个粒度级别的锁定, 使用额外类型的锁, 称为意向锁. 意向锁
是表级锁, 表示事务对于该表中的某一行稍后需要哪种类型的锁(共享或排他). InnoDB有两种类型的意图锁使用(假设事务T请求在表上
指定类型的锁t):

- 意图shared(IS): 事务T打算S在表中的单个行上设置锁t.
- 意向exclusive(IX): 事务T打算X在这些行上设置锁.

例如, SELECT ... LOCK IN SHARE MODE设置IS锁定, SELECT ... FOR UPDATE设置IX锁定.

意向锁定协议如下:
- 在一个事物可以获得一个表中一行的共享锁之前, 它必须首先获得这张表的IS锁或这张表的更强的锁.
- 在一个事务可以获得一个表中一行的排他锁之前, 它必须先获得这张表IX锁.

这些规则可以通过下面的锁类型兼容性矩阵方便地总结.

|  | X | IX | S | IS |
| --- | --- | --- | --- | --- |
| X | 冲突 | 冲突 | 冲突 | 冲突 |
| IX | 冲突 | 兼容 | 冲突 | 兼容 |
| S | 冲突 | 冲突 | 兼容 | 兼容 |
| IS | 冲突 | 兼容 | 兼容 | 兼容 |

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

可以明确禁用间隙锁定, 如果将事务隔离级别更改为 `READ COMMITTED` 或 启用 `innodb_locks_unsafe_for_binlog`系统变
量(现已弃用,5.7), 则会发生这种情况. 在这些情况下, 对于搜索和索引扫描禁用间隙锁定, 并且间隙锁定仅用于外键约束检查和重复键
检查.

使用 `READ COMMITTED` 隔离级别或启用 `innodb_locks_unsafe_for_binlog` 还有其他影响. 在MySQL评估WHERE条件后,
将释放不匹配行的记录锁. 对于UPDATE语句, InnoDB执行"semi-consistent(半一致)"读取, 以便将最新提交的版本返回给MySQL,
以便MySQL可以确定该行是否与 UPDATE 的 WHERE条件匹配.


## Next-Key Locks (下一键锁定)

下一键锁定是索引记录上的记录锁定和索引记录之前的间隙上的间隙锁定的组合.

InnoDB以这样一种方式执行行级锁定: 当它搜索或扫描表索引时, 它会在遇到的索引记录上设置共享锁或排它锁. 因此, 行级锁实际上是
索引记录锁. 索引记录上的下一键锁定也会影响该索引记录之前的"间隙". 也就是说, 下一键锁定是索引记录锁定加上索引记录之前的间隙
上的间隙锁定. 如果一个会话在索引中的记录R上具有共享或排他锁, 则另一个会话不能在索引顺序中的R之前的间隙中插入新的索引记录.

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
的排它锁之前, 每个锁定4和7之间的间隙和插入意图锁, 但是不要互相阻塞因为行是非冲突的.

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

插入意图锁的事务数据 `SHOW ENGINE INNODB STATUS` 和 `InnoDB` 监视器输出中的以下内容类似:
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
























