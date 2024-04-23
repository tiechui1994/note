## MySQL 专题 - 如何保证数据不丢?

### binlog 的写入机制

binlog写入逻辑比较简单: 事务执行过程中, 先把日志写入 binlog cache, 事务提交时, 再将 binlog cache 写入到 binlog 文
件中.

**一个事务的 binlog 是不能被拆分的, 因此不论这个事务多大, 也要确保一次性写入.** 

系统给 binlog cache 分配了一片内存, 每个线程一个, 参数 binlog_cache_size 用于控制单个线程内 binlog cache 所占内存
的大小. 如果超过了这个参数规定的大小, 就要暂存到磁盘.

事务提交的时候, 执行器把 binlog cache 里的完整事务写入到 binlog 中, 并清空 binlog cache.

![image](/images/mysql_log_binlog_flush.png)

从图中看到, 每个线程都有自己的 binlog cache, 但是公用一份 binlog 文件.

a) 图中的 write, 指的是把binlog cache写入到文件系统的page cache, 并没有将数据持久化到磁盘, 因此速度比较快.

b) 图中的 fsync, 将数据持久化到磁盘的操作. 一般情况下, fysnc 才占用磁盘的 IOPS.

write 和 fsync 的时机, 是参数 sync_binlog 控制的:

- sync_binlog=0, 表示每次提交事务都只 write, 不 fsync.

- sync_binlog=1, 表示每次提交事务都会执行 write 和 fsync.

- sync_binlog=N(N>1), 表示每次提交事务都 write, 但累积 N 个事务后才 fsync. 

因此, 当出现 IO 瓶颈的场景时, 将 sync_binlog 设置成一个比较大的值, 可以提升性能. 在实际业务场景, 考虑到丢失日志量的可
控性, 一般不建议将这个参数设置为0, 比较常见的是将其设置为 100~1000 中的某个数值.

但是, sync_binlog=N, 风险就是: 如果主机发生异常重启, 会丢失最近 N 个事务的 binlog 日志.

### redo log 写入时机

事务在执行过程中, 生成的 redo log 是要写到 redo log buffer(全局共享的 `innodb_buffer_pool_size` 参数控制)的.

在 redo log 持久化过程中, 会存在三个状态:

a) 写入到 redo log buffer 中, 物理上是在 MySQL 进程内存中.

b) 写入到磁盘(write), 但没有持久化(fsync), 物理上是在文件系统的 page cache 里.

c) 持久化到磁盘, 物理上是在磁盘当中.

redo log 在写入到 redo log buffer 和系统 page cache 是很快的, 但是持久化到磁盘的速度要慢一些.

为了控制 redo log 的写入策略, InnoDB 提供了 `innodb_flush_log_at_trx_commit` 参数, 它有三种取值:

a) 设置为 0, 表示每次事务提交时只把 redo log 写入到 redo log buffer 中.

b) 设置为 1, 表示每次事务提交时将 redo log 持久化到磁盘.

c) 设置为 2, 表示每次事务提交时将 redo log 写入到系统的 page cache.

InnoDB 有一个后台线程, 每隔1秒, 就会把 redo log buffer 中的日志, 调用 write 写入到系统的 page cache, 然后调用fsync
持久化到磁盘. 间隔时间是由 `innodb_flush_log_at_timeout` 控制的.

注: 事务执行中间过程中的 redo log 是直接写入在 redo log buffer 中的, 这些 redo log 也会被后台线程一起持久化到磁盘.
也就说, 一个没有提交的事务的redo log, 也是可能已经持久化到磁盘上的.

除了后台线程的轮询操作外, 还有两种场景会将一个没有提交的事务的 redo log 持久化到磁盘:

a) **一种是, redo log buffer占用的空间即将达到 innodb_log_buffer_size 一半的时候, 后台线程会主动写盘**. 注意, 由
于这个事务还没有提交, 所以这个写盘动作只是 write, 而没有调用 fsync, 也就是只留在了系统的 page cache.

b) **另一种是, 并行的事务提交的时候, 顺带将这个事务的 redo log buffer 持久化到磁盘.** 假设一个事务A执行到一半, 已经写了
一些redo log到redo log buffer, 这个时候有另外一个线程的事务B提交, 如果 `innodb_flush_log_at_trx_commit=1`, 那么
按照这个参数的逻辑, 事务B要把 redo log buffer 里的日志全部持久化到磁盘. 这个时候, 就会带上事务A在 redo log buffer 里
的日志一起持久化到磁盘.

### 两阶段提交

在 InnoDB 的两阶段提交中, 不管是 redo log 还是 binlog, 都需要确切地将数据写入磁盘中(不是系统 page cache)

Prepare 阶段: InnoDB 将回滚段设置为 prepare 状态; 将 redo log 写文件(write)并刷盘(fsync);

Commit 阶段: binlog 写入文件(write)并刷盘(fsync); InnoDB 回滚段设置为 commit 状态;


MySQL 存在两个日志系统: server 层的 binlog 日志和 storage 层的事务日志(例如, InnoDB 的 redolog 日志), 并且支
持多个存储引擎. 这样产生的问题是, 如何保证事务在多个日志中的原子性? 即要么都提交, 要么都中止.

在单个 MySQL 实例中, 使用了`两阶段提交`方式来解决该问题, 其中 server 层作为事务协调器, 而多个存储引擎作为事务参与者.

关于事务协调: 

如果开启了 binlog, 并且有事务引擎, 则事务协调器为 mysql_bin_log 对象, 使用 binlog 物理文件记录事务状态;

如果关闭了 binlog, 并且有事务引擎, 则事务协调器为 tc_log_nmap 对象, 使用内存数据结构来记录事务状态;

两阶段提交保证了事务在多个引擎和 binlog 之间的原子性, 以 binlog 写入成功作为事务提交的标志, 而 InnoDB 的 commit 
标志并不是事务成功与否的标志.

在崩溃恢复中, 是以 binlog 中的 xid 和 redolog 当中的 xid 进行比较, xid 在 binlog 里存在则提交, 不存在则回滚.
恢复的具体情况:

a) 在 prepare 阶段崩溃, 即已经写入了 redolog, 在写入 binlog 之前崩溃, 则回滚.

b) 在 commit 阶段, 当没有成功写入 binlog 时崩溃, 则回滚.

c) 如果已经写入了 binlog, 在写入 InnoDB commit 标志时崩溃, 则重新写入 commit 标志, 完成提交.


### 组提交

为了提高并发性能, 将两阶段提交进行了优化(组提交的本质):

prepare 阶段: InnoDB 将回滚段设置为 prepare 状态, redo log 文件写入(不刷盘)

commit 阶段: 分为3个stage, 分别是 flush, sync, commit. 每个stage设置一个队列, 第一个进入该队列的线程成为leader,
后续进入的线程会阻塞直至完成提交. leader 线程会领导队列中所有线程执行该stage任务, 并带领所有 follower 进入到下一个
stage 去执行. 

```
flush:
1) 收集组提交队列(线程), 首个为leader线程, 其余follower线程进入阻塞
2) leader 进行一次 redo log 的 fsync, 即一次将所有线程的 redo log 刷盘;
3) 将队列当中所有的 binlog 写入的文件当中(只进行write, 不刷盘)

sync:
1) 对 binlog 文件进行一次 fsync 操作(多个线程的binlog合并一次刷盘)

commit:
1) 各个线程按顺序做InnoDB Commit 操作.
```


**通常所说 MySQL 的"双1"配置, 指的是 sync_binlog 和 innodb_flush_log_at_trx_commit 都设置为1. 也就是,一次完整的事
务提交前, 需要等待两次刷盘, 一次是redo log(prepare阶段), 一次是binlog(commit阶段)**.

现在有个疑问, 如果看到MySQL的TPS是2w/s的话, 每秒就会有4w次刷盘. 但是, 使用工具测试出来, 磁盘能力也就在2w左右, 怎么能
实现2w的TPS?

解释这个问题, 与组提交(group commit)机制相关.

先介绍日志逻辑序列号(log sequence number, LSN) 概念, LSN 是单调递增的, 用来对应 redo log 的一个个写入点. 每次的
写入长度为 length 的 redo log, LSN 的值就会加上 length.

LSN 也会写入到 InnoDB 的数据页中, 来确保数据页不会被多次执行重复的 redo log. 

如下图所示, 3 个并发事务(trx1, trx2, trx3)在 prepare 阶段, 都写完了 redo log buffer, 持久化到磁盘的过程, 对应的
LSN 分别是 50, 120, 160.

![image](/images/mysql_log_redolog_groupcommit.png)

从图中可以看到:

a) trx1 是第一个到达, 它会被选为这组的leader,

b) 等 trx1 要开始写盘的时候, 这个组里面已经有了三个事务(trx1, trx2, trx3), 这个时候LSN也变成了160.

c) trx1 去写入磁盘的时候, 带上的是LSN=160, 因此等trx1返回时, 所有 LSN 小于等于160的 redo log, 都已经被持久化到磁盘.

d) 此时 trx2 和 trx3 就可以直接返回了.

所以, 一次组提交里面, 组成员越多, 节约磁盘的IOPS的效果就越好. 对于单线程压测, 只能是一个事物对应一次持久化操作了.

并发场景下, 第一个事务写完 redo log buffer 之后, 接下这个 fsync 越晚调用, 组员可能越多, 节约IOPS的效果就越好.

为了让一次 fsync 带的组员更多, MySQL进行了一次优化: 拖时间. 在进行两阶段提交时, 其过程:
 
`写redolog(处于prepare阶段)` =>  `写binlog, 提交事务(处于commit阶段)`

MySQL的优化就是将 `写binlog` 拆分为2步骤:

a) 先将 binlog 从 binlog cache 写入到系统的 page cache.

b) 调用 fsync 持久化 binlog.

MySQL 为了让组提交效果更好, 把 redo log 做 fsync 的时间拖延到了 `binlog 写入系统 page cache` 之后, MySQL 的两阶段
提交就变成了这样的:

![image](/images/mysql_log_redolog_2pc.png)

这样, binlog 也可以组提交了. 在执行 `把 binlog fsync到磁盘` 时, 如果有多个事务的 binlog 已经写完(write), 也是一起
持久化的, 这样可以减少 IOPS 的消耗.

不过, 通常情况下, `fsync prepare redo log` 执行得很快, 所以 binlog 的 write 和 fsync 间的间隔短, 导致能集合到一
起持久化的 binlog 比较少, 因此 binlog 的组提交的效果没有 redo log 的效果好.

如果, 想要提升 binlog 组提交效果, 可以设置 binlog_group_commit_sync_delay 和 binlog_group_commit_sync_no_delay_count
来实现.

1.binlog_group_commit_sync_delay, 表示延迟多少us后才提交fsync.

2.binlog_group_commit_sync_no_delay_count, 表示累积多少次以后才调用fsync.

两个条件是或的关系, 只要有一个满足条件就可以调用 fsync 了.

WAL 机制主要得益于两个方面:

1.redo log 和 binlog都是顺序写, 磁盘顺序写比随机写速度要快.

2.组提交机制, 可以大幅度降低磁盘IOPS消耗.

现在, 再来回答这个问题: 如果MySQL出现了性能瓶颈, 而且瓶颈在IO上, 可以优化的手段有哪些?

- 设置 binlog_group_commit_sync 和 binlog_group_commit_no_sync_count 参数, 减少binlog的写盘此书. 这个方法是
基于"额外的故意等待"来实现的, 因此可能增加语句的响应时间, 但没有丢失数据的风险.

- 将 sync_binlog 设置为大于1的值(常见100~1000). 这个的风险, 主机掉电时会丢失binlog日志.

- 将 innodb_flush_log_at_trx_commit 设置为2. 这样做的风险, 主机掉电的时候会丢数据(redo log丢失).

不建议将 innodb_flush_log_at_trx_commit 设置为0. 因为这个参数为 0, 表示 redo log 只保存到 redo log buffer 当中, 在
MySQL本身异常重启也会丢数据, 风险太大. 而设置为 2, 与设置成 0 性能差不太多, 但是 MySQL 异常重启不会丢数据.

问题: sync_binlog=N(N>1), binlog_group_commit_sync_no_delay_count=M, 这种情况下, fsync 发生的时机是怎样的?

数据库的代码逻辑: 达到了 sync_binlog 设置的 N 次以后, 就可以刷盘了, 然后再进入(sync_delay 和 no_delay_count) 的
判断逻辑. 也就说这两者之间没有关联.

### xid, trx_id

Xid 是 MySQL server 层维护的, MySQL 内部维护了一个全局变量 global_query_id, 每次执行语句的时候将它赋值给 Query_id,
然后这个变量加1. 如果当前语句是这个事务执行的第一条语句, 那么 MySQL 还会同时把 Query_id 赋值给这个事务的 Xid.

global_query_id 是一个纯粹的内存变量, 重启之后就清零了. 因此, 在同一个数据库实例中, 不同事务的 Xid 也是有可能相同的.

但是 MySQL 重启之后会重新生成新的 binlog 文件, 这就保证了同一个 binlog 文件里, Xid 一定是唯一的.

虽然 MySQL 重启不会导致同一个 binlog 里面出现两个相同的 Xid, 但是如果 global_query_id 达到上限后, 就会继续从 0 开
始计数. 从理论上讲, 还是会出现在一个 binlog 里面出现相同的 Xid 的场景.

由于 global_query_id 定义的长度是 8 字节, 自增值的上限是 2^64-1. 要出现这种情况, 必须是这样的过程:

1.执行一个事务, 此时Xid=A

2.接下来再执行 2^64 次查询语句, 让 global_query_id 回到 A

3.再启动一个事务, 这个事务的 Xid 也是A

> 2^64 值太大了, 大到这个可能性只会存在理论上.

trx_id 是在 InnoDB 当中维护的. 在 InnoDB 内部使用 Xid, 是为了能够在 InnoDB 事务和 Server 之间关联.

InnoDB 内部维护了一个 max_trx_id 全局变量, 每次需要申请一个新的 trx_id 时, 就会获得 max_trx_id 的当前值, 然后并将
max_trx_id 加 1.

InnoDB 数据可见性的核心思想是: 每一行数据都记录了更新它的 trx_id, 当一个事务读到一行数据的时候, 会判断这个数据是否可见
的方法, 就是通过事务的一致性视图与这行数据的 trx_id 做对比.

对于正在执行的事务, 可以从 information_schema.innodb_trx 当中查找到事务的 trx_id.

![image](/images/mysql_trx_id.drawio.png)

在上图当中, session B 里, 两次查询 innodb_trx 表, 但是 trx_id 却不一样(T2时刻 trx_id 是一个很大的数字, T4时刻 
trx_id 是 90161), 这是为什么呢?

实际上, 在T1时刻, session A 还没有涉及到更新, 是一个只读事务. 而对于只读事务, InnoDB 并不会分配 trx_id, 也就是说:

1.在T1时刻, trx_id 的值其实就是0. 而这个很大的数字, 只是显示用的.

2.直到在T3时刻执行 INSERT 语句时, InnoDB 才真正的分配了 trx_id. 所以, T4 时刻, session B 查到的这个 trx_id 的值
就是 90161.

注意, 除了常见的修改语句外, 如果 select 语句后面加上 for update, 这个事务也不是只读事务.

**T2时刻查到的 trx_id 是个很大数字是怎么来的?**

这个数字是每次查询的时候由系统临时计算出来的. 它的算法是: 把当前事务的 trx 变量的指针转换成整数, 然后加上 2^48. 使用这
样的算法, 就可以保证两点:

1.吟哦同一个只读事务在执行期间, 它的指针是不会变的, 所以不论是在 innodb_trx 还是 innodb_locks 表中, 同一个只读事务
查询出来的 trx_id 是一致的.

2.如果有并行的多个只读事务, 每个事务的 trx 变量的指针肯定不同. 这样, 不同的并发只读事务, 查出来的 trx_id 就不相同了.

至于加上 2^48, 目的是保证只读事务 trx_id 区别于读写事务 trx_id. trx_id 和 row_id 的逻辑类似, 长度都是 6 字节, 因
此, 在理论上可能出现一个读写事务与一个只读事务显示的 trx_id 相同的情况, 只是概率很低. 加上 2^48 就可以保证两者的值肯定
不一样.

只读事务不分配 trx_id 的目的:

1.减少事务视图里面活跃事务组的大小. 因为当前正在运行的只读事务, 是不影响数据的可见性判断的. 所以, 在创建事务的一致性视图
时, InnoDB 就只需要拷贝读写事务的 trx_id.

2.减少trx_id申请次数. InnoDB 当中, 即使只是执行一个普通的 select 语句, 执行过程中, 也是要对应一个只读事务的. 所以只
读事务优化后, 普通的查询语句就不需要申请 trx_id, 这样可以大大减少并发事务申请 trx_id 的锁冲突.

max_trx_id 会持久化存储, 重启也不会重置为0, 那么从理论上讲, 只要一个 MySQL 服务跑得足够就, 就可能出现 max_trx_id 达
到 2^48-1 的上限, 然后从0开始的情况.

当达到这个状态之后, MySQL 就会持续出现一个脏读的 bug. (在一个事务执行期间, max_trx_id 跨越了 2^48 变成了0, 这时,在
这个事务当中会出现脏读的情况)

> 一般情况下, update, delete, insert 会导致 max_trx_id 加1. select ... for update 也会导致 max_trx_id 增加. 
>
> 除了上述情况下, 下面的情况, trx_id 也会增加:
> 1. update, delete 语句除了事务本身, 还涉及到标记删除旧数据, 也就是要把数据放到 purge 队列里等到后续物理删除, 这个
操作也会把 max_trx_id + 1, 因此在一个事务中至少加2.
> 2. InnoDB 的后台操作, 比如表的索引信息统计这类操作, 也是会启动内部事务的, 因此可能看到, trx_id 值并不是按照加1递增
的.

