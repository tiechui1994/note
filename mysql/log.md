# MySQL 日志


文档:

[后台清理](https://www.cnblogs.com/geaozhang/p/7225340.html)

[掘金文档](https://juejin.im/entry/5ba0a254e51d450e735e4a1f)

[Segment文档](https://segmentfault.com/a/1190000017888478)

[redo log淘宝文档](http://mysql.taobao.org/monthly/2015/05/01/)

[undo log淘宝文档](http://mysql.taobao.org/monthly/2015/04/01/)


MySQL 中有六种日志文件, 分别是: 重做日志(redo log), 回滚日志(undo log), 二进制日志(binlog),
错误日志(errorlog), 慢查询日志(slow log), 一般查询日志(general log), 中继日志(relay log).

其中 `重做日志` 和 `回滚日志` 与事务操作息息相关, `二进制日志` 也与事务操作有一定的关系.

---

## 重做日志 (redo log)

- 作用 

确保事务的持久性.

防止在发生故障的时间点, 尚有脏页面未写入磁盘, 在重启MySQL服务的时候, 根据redo log进行重做, 从而达到
事务的持久性这一特性.

- 内容

`物理格式的日志`, 记录的是 `物理数据页面的修改信息`, 其 redo log 是顺序写入redo log file的物理文
件中去的.

redo log包含两部分:
一是内存中的日志缓冲(redo log buffer), 该部分日志是易失性的; 
二是磁盘上的重做日志文件(redo log file), 该部分日志是持久的.

在概念上, InnoDB 通过 `force log at commit` 机制实现事务的持久性, 即在事务提交的时候, 必须先将事
务的所有事务日志写入到磁盘上的 redo log file 和 undo log file中进行持久化.

为了确保每次日志都能写入到事务日志文件中, 在每次将 log buffer的日志写入到日志文件的过程中都会调用一次
fsync操作. 因为MySQL工作在用户空间, MySQL的log buffer处于用户空间的内存中. 要写入到磁盘上的log file
(redo: ib_logfileN文件, undo: ibdataN 或 .ibd文件) 当中, 中间还要经过操作系统内核空间os buffer,
调用 fsync 的作用就是将 OS buffer中的日志刷到磁盘的log file中.

![image](resource/innodb_log.png)


- 日志块 (log block)

InnoDB 存储引擎当中, redo log 以块为单位进行存储的, 每个块占 512 字节, 这称为redo log bolck. 所以不
管是`log buffer`中, `os buffer`中 以及 `redo log file on disk`中, 都是以这样512字节的块存储的.

每个 `redo log block` 由3部分组成: **日志块头, 日志块尾, 日志主体**. 其中日志块头占用12字节, 日志块尾
占用4字节, 因此日志主体只有496字节.


由于redo log记录的是数据页的变化, 当一个数据页产生的变化需要使用超过496字节redo log来记录, 那么记忆会使用
多个redo log block来记录数据页的变化.

日志块头:
```
log_block_hdr_no: (4字节), 该日志块在redo log buffer中的位置ID

log_block_hdr_data_len: (2字节), 该log block中已经记录的log大小. 写满该log block时为0x200, 表示
512字节.

log_block_first_rec_group: (2字节) 表示该log block中作为第一个新的mtr开始log record的偏移量. 如果
一个mtr日志横跨多个log block时, 只设置最后一个 log block.

log_block_checkpoint_no: (4字节) 写入检查点信息的位置
```
关于 log_block_first_rec_group, 因为有时候一个数据页产生的日志量超出一个日志块, 那么需要用多个日志块来
记录该页的相关日志. 例如, 某一个数据页产生552字节的日志量, 需要两个日志块, 第一个日志块占用492字节, 第二个
日志块占用60字节. 对于第二个日志块来说, 它的第一个log开始的位置就是73字节 (60+12). 如果该部分值和 
log_block_hdr_data_len 相等, 则说明该log block中没有新开始的日志块, 即表示该日志块延续了前一个日志块.


日志块尾:
```
log_block_checksum, 该log block计算出的校验值
```

- 日志文件结构

每个日志文件组的第一个文件的前2048字节是存放的头文件信息. 

![image](resource/redo_log_file.jpg)

日志文件头共占用4个OS_FILE_LOG_BLOCK_SIZE(512字节)的大小. 

```
LOG_GROUP_ID, (4字节) 该log文件所属的日志组
LOG_FILE_START_LSN, (8字节), 该log文件记录的开始日志的lsn
LOG_FILE_WAS_CREATED_BY_HOT_BACKUP, (32字节), 备份程序所占用的字节数

LOG_CHECKPOINT_1/LOG_CHECKPOINT_2, (512字节) 两个记录InnoDB checkpoint信息的字段, 分别从文件头
的第二个和第四个 log block 开启记录. 只使用日志文件组的第一个日志文件
```

- redo log的格式

因为InnoDB存储引擎存储数据的单元是页, 所以redo log也是基于页的格式记录的. 默认情况下, InnoDB的页大小是
16KB(由innodb_page_size设置) 一个页内可以存储非常多的log block(512字节), 而log block中记录的又是数
据页的变化.

其中 log block 中的 496 字节部分是log body, 该body的格式分为4部分:

```
redo_log_type: (1字节), 表示redo log的日志类型

space: 表示空间ID, 采用压缩的方式后, 占用空间可能小于4字节

page_no: 页的偏移量, 同样进行压缩过的.

redo_log_body: 表示每个redo log的数据部分, 恢复时调用相应的函数进行解析.
```

- 产生时间

事务开始之后就会产生redo log, redo log 落盘并不是随着日志的提交才写入的, 而是在事务的执行过程中, 便
开始写入redo log文件中.

之所以说重做日志是在事务开始之后逐步写入重做日志文件, 而不一定是事务提交才写入重做日志文件, 原因是: 重做
日志有一个缓存区innodb_log_buffer, 其默认的大小是 16M, InnoDB 存储引擎先将重做日志写入innodb_log_buffer
中.


InnoDB redo log 刷盘的规则:

1) 发出commit动作时. commit发出后是否刷日志由变量 `innodb_flush_log_at_trx_commit` 控制

2) 每秒刷一次. 这个刷日志的频率由变量 `innodb_flush_log_at_timeout`值决定, 默认是1秒.

3) 当log buffer中已经使用的内存超过一半时.

4) 当有checkpoint时, checkpoint在一定程度上代表了刷到磁盘时日志所处的LSN位置.



内存中 (buffer pool)未刷到磁盘的数据称为脏数据(dirty data). 由于数据和日志都页的形式存在, 所以脏页
表示脏数据和脏日志.

在InnoDB中, 数据刷盘的规则只有一个, checkpoint. 但是触发checkpoint的情况却有几种. 不管怎样, checkpoint
触发后, 会将buffer中数据页和脏日志都刷到磁盘.

InnoDB中的checkpoint分为两种:

a) sharp checkpoint: 在重用redo log文件(例如切换日志文件)的时候,会将所有已记录到redo log中对应的
脏数据刷到磁盘.

b) fuzzy checkpoint: 一次只刷一小部分的日志到磁盘, 而非将所有脏日志刷盘. 有以下几种情况会触发该检查
点:

master thread checkpoint: 由master线程控制, 每秒或每10秒刷入一定比例的脏页到磁盘.

flush_lru_list checkpoint: 从MySQL 5.6开始, 可以通过 innodb_page_cleaners 变量指定专门负责
脏页刷盘的page cleaner线程的个数, 该线程的目的是为了保证lru列表有可用的空闲页.

aysnc/sync flush checkpoint: 同步刷盘还是异步刷盘. 如果有非常多的脏页没刷到磁盘(有比例控制),这个
时候会选择同步刷到磁盘, 但是很少出现; 如果脏页不是很多, 可用选择异步刷到磁盘, 如果脏页很少, 可用暂时不
刷脏页到磁盘.

dirty page too much checkpoint: 脏页太多时强制触发检查点. 目的是为了保证缓存有足够的空闲空间. too
much的比例由变量 innodb_max_dirty_pages_pct 控制, MySQL 5.6 以后默认值是 75, 即当脏页站缓冲池的
百分之75后, 强制刷一部分脏页到磁盘.


- 对应的物理文件

默认情况下, 对应的物理文件位于数据库 data 目录下的 `ib_logfile1` 和 `ib_logfile2`.

innodb_log_group_home_dir 指定日志文件组所在的路径, 默认是 ./ , 表示在数据库的数据目录下.

innodb_log_files_in_group 指定重做日志文件组中的文件数量, 默认是 2

innodb_log_file_size 重做日志文件的大小, 默认值是 512MB

innodb_log_buffer_size 重做日志文件缓存区 `innodb_log_buffer` 的大小, 默认是 16M

innodb_flush_log_at_trx_commit=1, 指定了 `InnoDB` 在事务提交后的日志写入频率. 
````
值设置为 `0`, 每隔1秒log buffer刷到文件系统(os buffer)去, 并且调用文件系统的"flush"操作将缓存刷新到磁
盘上去. 也就是说一秒前的日志都保存到log buffer, 也就是内存上, 也就是 log buffer 的刷新操作和事务提交操作
没有关联. 在这种情况下, MySQL性能最好. 如果mysqld进程崩溃, 通常导致最后1s的日志丢失.

值设置为 `1`, 每次事务提交, log buffer 会被写入到文件系统中(os buffer)去, 并且调用文件系统的"flush"操
作将缓存刷新到磁盘上去. 这个是默认值. 效率最慢. 

值设置为 `2`, 每次事务提交, log buffer 会被写入到文件系统中(os buffer)去, 但是每隔1秒调用文件系统(os buffer)
的"flush"操作将缓存刷新到磁盘上去. 这时如果mysqld进程崩溃, 由于日志已经写入到系统缓存, 所以并不会丢失数据; 
在操作系统崩溃的情况下, 通常会导致最后1s的日志丢失. 这里的 "1秒" 是可以使用 `innodb_flush_log_at_timeout`
来控制时间间隔的
````

![image](resource/innodb_flush_log_at_trx_commit.png)

innodb_flush_log_at_timeout=1, 指定了 `InnoDB` 日志由系统缓存刷写到磁盘的时间间隔. 默认值是1s


---


## 回滚日志 (undo log)

- 作用

保存了事务发生之前的数据的一个版本, 可以用于事务回滚, 同时可以提供多版本并非控制下的读(MVCC), 即非锁
定读.


- 内容

`逻辑格式的日志`, 在执行undo的时候, 仅仅是将数据从逻辑上恢复至事务之前的状态, 而不是从物理层面上操作
实现的, 这一点不同于 redo log


- 产生的时间

当事务提交之后, undo log 并不能立马被删除, 而是放入待清理的链表, 由 `purge` 线程判断是否有其它
的事务在使用 undo 段中表的上一个事务之前的版本信息, 决定是否可以清理undo log的日志空间.


- 对应的物理文件

MySQL 5.6 之前, undo 表空间位于共享表空间的回滚段中, 共享表空间的默认名称是 ibdata, 位于数据文
件目录中.

MySQL 5.6 以后, undo 表空间可以配置成独立的文件, 但是提前需要在配置文件中配置, 完成数据库初始化
之后生效且不能改变undo log文件的个数.

MySQL 5.7 之后undo表空间配置参数如下:

innodb_file_per_table=ON, 表示为数据库的每张表使用独立的表空间, 数据库的每个表使用一个单独的 '.ibd'
文件存储数据和索引. 默认值是ON. 如果是 OFF, 数据库的所有数据和索引都存储在 `ibdata` 文件当中 

> 修改这个系统变量并不能带来性能提升. 

innodb_undo_directory  undo独立表空间的存放目录, 默认是 ./

innodb_undo_logs   回滚段为大小(KB), 默认是128KB

innodb_undo_tablespaces 指定undo log文件个数, 默认是0

innodb_max_undo_log_size 指定undo log文件最大的大小, 默认是1G


如果undo使用共享表空间, 这个共享表空间中不仅仅是存储了undo的信息. 默认的目录是 ./

innodb_data_file_path  文件路径,大小配置, "ibdata1:1G:autoextend"


- 其他

undo 是事务开始之前的保存的被修改的数据的一个版本, 产生undo日志的时候, 同样会伴随类似于保护事务持久化
机制的redo log的产生.

默认情况下, undo文件是保持在共享表空间的, 即ibdata文件当中, 当数据库中发生一些大的事务性操作的时候, 
要产生大量的undo信息, 全部保存在共享表空间中.

因此, 共享表空间可能会变得很大, 默认情况下, 也就是undo日志使用共享表空间的时候, 被 "撑大" 的共享表空
间是不会自动收缩的.

---


## 二进制日志 (binlog)

- 作用

用于复制, 在主从复制中, 从库利用主库上的binlog进行重播, 实现主从同步.

用于数据库基于时间点的还原.


- 内容

`逻辑格式的日志`, 可以简单的认为就是执行过过的事务中的sql语句. 但又不完全是sql语句这么简单, 而且包含了
执行的sql语句(增删改)反向的信息.

也就意味着 `delete` 对应着 `delete` 本身和其反向的 `insert`; `update` 对应着 `update` 执行前后
的版本信息; `insert` 对应着 `insert` 本身和其反向的 `delete`.

在使用 mysqlbinlog 解析 binlog 会展示相关情况.


- 产生时间

事务提交的时候, 一次性将事务中的 `sql` 语句(一个事务可能对应多个sql语句)按照一定的格式记录到binlog当中.

这里与 redo log 明显的差异是 redo log 是在事务开始之后就开始逐步写入磁盘. 

在开启了bin log 的情况下, 对于较大事务的提交, 可能会变得比较慢一些.


- 删除时间

binlog 的默认保存时间由参数 expire_logs_days 配置, 也就是说对于非活动的日志文件, 在生成时间超过 `expire_log_days`
配置的天数之后, 会被自动删除.  默认值是0, 表示永不过期


- 对应的物理文件

配置文件的路径 `log_bin_basename`, binlog文件按照指定的大小, 当日志文件达到指定的最大的大小之后, 进行
滚动更新, 生成新的日志文件.

log_bin={OFF|/tmp/binlog}, 开启bin log, 并且设置binlog的路径, 文件格式 binlog.xx

binlog_format={ROW|STATEMENT|MIXED}, bin log的格式. 

```
ROW: 仅保存记录被修改的细节, 不记录sql语句上下文相关信息. 优点, 清晰的记录下每一行数据的修改细节, 不需要
记录上下文相关信息, 因此不会发生某些特定情况下的produce, function,trigger的调用无法被正确复制的问题, 
任何情况下都可以被复制, 且 `能加快从库重放的效率`, 保证从库数据的一致性. 缺点, 由于所有执行的语句在日志中
都将以每行记录的修改的修改细节来记录, 因此, 可能产生大量的日志内容. `alter table`, `update`等

STATEMENT: 每一条被修改的数据SQL都会记录在binlog中. 优点, 只需要**记录执行语句的细节和上下文环境**, 避
免了记录每一行的变化, 在一些修改记录较多的情况下相比ROW能减少binlog的日志量, 节约IO. 可用于实时的还原. 主
从版本可以不一样. 缺点, 为了保证SQL语句能在slave上正确执行, 必须记录上下文信息, 以保证所有语句能在slave得
到和master端执行时候相同的结果. 主从复制, 存在部分函数(如sleep)以及存储过程在slave上会出现与master不一致
的情况.

MIXED:以上两种格式的混合使用.
```

log_bin_index=/tmp/binlog.index  指定binlog索引文件(保存了当前所有的binlog文件名)的名称               

binlog_cache_size=3M, 指定binlog的缓存大小

max_binlog_size=12M, 指定单个binlog文件的最大size

max_binlog_cache_size=16M, 指定binlog的最大缓存大小                     

sync_binlog={0|N}, MySQL的二进制日志(bin log)同步到磁盘的频率.
```
值为 `0`, 表示当事务提交之后, MySQL不做fsync之类的磁盘同步操作, 而让fs自行决定什么时候做同步; 

值为 `N`, 表示每进行N次事务提交之后, MySQL将进行一次fsync之类的磁盘同步指令将binlog_cache当中的数据
强制写入到磁盘. 

在MySQL中默认的设置是 `sync_binlog=0`, 不强制磁盘刷新, 性能最好, 风险是最大的. 而 `sync_binlog=1`
是最安全但是性能损耗最大的设置.

注: 如果autocommit开启, 每个语句都写一次bin log, 否则每次事务写一次.
```

- 其他

binlog 的作用之一是还原数据库的, 这与redo log 类似, 但是这两者有本质的不同:

a) 作用不同: redo log是保证事务的持久性的, 是事务层面的; bin log 作为还原功能, 是数据库层面的(当然可以
精确到事务层面的).

b) 内容不同: redo log是物理日志,是数据页面的修改之后的物理记录; binlog是逻辑日志, 可以简单的认为记录的
就是sql语句

c) 恢复数据时候的效率, 基于物理日志的redo log恢复的效率要高于语句逻辑日志的binlog

关于事务提交时, redo log和binlog的写入顺序, 为了保证主从复制时候的主从一致(的\包括使用binlog进行基于时
间点还原的情况), 是严格一致的.

MySQL通过两阶段提交过程完成事务的一致性的, 即 redo log 和 binlog 的一致性, 理论上先写入 redo log, 再
写入binlog, 两个日志都写入成功(写入磁盘), 事务才算真正的完成.


---


## 错误日志 (err log)

错误日志记录着mysqld启动和停止, 以及服务器运行过程中发生的错误和严重的警告的相关信息. 在默认情况下, 系统记录
错误日志的功能是关闭的, 错误信息被输出标准错误输出.


指定错误日志路径的方法:

log_error=/path/to/error, 配置文件my.cnf


---


## 一般查询日志 (general log)

记录了服务器接收到每一个 `命令`, 无论这些命令是否正确甚至是否包含语法错误, general log都会将其记录下来, 记录
的格式为: `{Time, Id, Command, Argument}`

也正是因为mysql服务器需要不断的记录日志, 开启general log会产生不小的系统开销. 因此, 默认是把 general log
关闭的.

> general log 记录的是服务器执行的所有的命令 

general log相关的参数:

general_log=ON, 开启general log

general_log_file=/tmp/general.log, 设置general log文件位置

log_output={FILE|TABLE}, 设置general log的格式, FILE表示记录到文件当中, TABLE表示记录到general_log
表(mysql.general_log)当中, 表的默认引擎的CSV. 


---


## 慢查询日志(slow log)

MySQL 的慢查询日志是 MySQL 提供的一种日志记录,它用来记录在 MySQL 中 `响应时间` 超过阀值的语句, 具体指运行时间
超过 `long_query_time`值的SQL, 则会被记录到慢查询日志. 默认值是10s. 默认情况下, 不开启慢查询日志.

> 慢查询日志记录是响应时间超过阈值的所有的SQL语句(包括select, insert, update, delete)

slow_query_log=ON, 开启慢查询

long_query_time=2.00, 慢查询的时间

slow_query_log_file=/tmp/slow_query.log, 慢查询日志文件路径

log_queries_not_using_indexes=ON, `未使用索引的查询` 也被记录到慢查询日志中(可选项)

log_output={FILE|TABLE}, 设置query log的格式, FILE表示记录到文件当中, TABLE表示记录到slow_log
表(mysql.general_log)当中, 表的默认引擎的CSV. 


日志文件的格式:

```
# Time: 2020-05-05T12:17:33.123438Z  (时间信息)
# User@Host: root[root] @ localhost [127.0.0.1]  Id:    15  (连接信息)
# Query_time: 0.000184  Lock_time: 0.000090 Rows_sent: 4  Rows_examined: 4  (查询响应信息)
SET timestamp=1588681053; (时间点)
select * from t2; (语句)
```


---


## 中继日志 (relay log)

与 bin log一样, relay log 由一组编号的 files 和 一个索引文件组成, 这些files包含描述数据库更改的 events,
索引文件包含所有使用的relay log files的名称.

relay log 具有和bin log相同的格式. 可以使用 mysqlbinlog 进行读取.

从服务器在以下的条件下创建新的relay log文件:

1) 每个 time线程开始

2) 刷新日志(例如, 使用 flush logs 或 mysqladmin flush-logs)

3) 当前relay log文件的大小变得"太大"时, 确定如下:

a) 如果 max_relaylog_size 的值大于0, 那么这是最大的 relay log文件大小

b) 如果 max_relaylog_size 的值是0, 那么 max_binlog_size 确定最大 relay log文件大小

SQL 线程在执行文件中的所有 events 并且不再需要它之后自动删除每个 relay log文件. 没有明确的删除 relay log
文件的机制, 因为 SQL 线程负责这样做. 但是, FLUSH LOGS 会轮换(rorate) relay log, 这会影响 SQL 线程同时
删除它们.


相关的参数:

relay_log=/tmp/relaylog, 开启relay log, 并设置文件的路径

relay_log_index=/tmp/relaylog.index, 设置relay log的索引文件.

relay_log_info_file=/tmp/relaylog.info, 设置relay log info文件(记录master的bin_log的恢复位置和
relay_log的位置)的位置和名称, 也可以配置记录到mysql.slave_relay_log_info表中.

relay_log_info_repository={TABLE|FILE}, 设置relay log info的格式, FILE表示记录到文件当中, TABLE
表示记录到表(mysql.slave_relay_log_info)当中, 表的默认引擎的CSV. 


max_relaylog_size=1G, relay log单个文件的最大值. 如果该值是0, 则默认值是max_binlog_size


relay_log_purge=ON, 是否自动清空不再需要的 relay log, 默认值是ON

relay_log_recovery=OFF, 当slave宕机之后, 假如relay log出现损坏, 导致一部分中继日志没有处理, 则自动放
弃所有未执行的 relay log, 并且重新从 master 上获取日志, 这样就保证了relay log的完整性. 默认情况下, 该功
能是关闭的.

> 注意, 开启 `relay_log_recovery` 功能的时候, 记得开启 `relay_log_purge`

sync_relay_log=1000, 此参数和 sync_binlog 是一样的, 当设置为1时, slave的I/O线程每次接收到master发送过来
的bin log都要写入系统缓存区, 然后耍人relay log文件当中, 这样是最安全的, 因为在崩溃的时候, 最多丢失一个事务, 但
会造成磁盘大量I/O. 当设置为0时, 并不是马上刷入到relay log文件当中, 而是由操作系统决定何时写入, 虽然安全性降低,
但减少了大量的磁盘I/O操作. 默认值是1000

sync_relay_log_info=1000, 和sync_relay_log参数一样. 

