## InnoDB 磁盘结构

InnoDB 架构模型:

![image](/images/mysql_innodb_architecture.png)

### Data Dictionary

InnoDB Data Dictionary 由内部system table组成, 其中包含用于追踪对象(例如表, 索引和列)的元数据. 元数据物理上位于
InnoDB system tablespace当中. 由于历史原因, Data Dictionary元数据在某种程度上与存储在InnoDB表元数据文件(.frm
文件)中的信息重叠.


### Log Buffer

Log Buffer 是保存要写入磁盘上日志文件的数据的内存区域. Log Buffer 大小由 `innodb_log_buffer_size` 变量定义. 默认
大小为 16MB. 

Log Buffer的内容会定期刷写到磁盘. 较大的Log Buffer使大型的事务能够运行, 而无需在事务提交前将 redo log数据写入磁盘.
因此, 如果有更新, 插入或删除许多行的事务, 则增加 Log Buffer 的大小可以节省磁盘IO.

`innodb_flush_log_at_trx_commit` 变量控制 Log Buffer 的内容如何写入和刷新到磁盘. `innodb_flush_log_at_timeout`
变量控制日志刷新频率.

### Redo Log

Redo Log 是一种基于磁盘的数据结构, 用于在崩溃恢复期间纠正由不完整事务写入的数据. 在正常操作期间, Redo Log对由 SQL 语
句或低级API调用产生的更改表数据的请求进行编码. 在意外关闭之前未完成数据文件的修改会在初始化期间和接收连接之前自动重放.

默认情况下, Redo Log在磁盘上由两个名为 ib_logfile0 和 ib_logfile1 的文件存储. MySQL以循环方式写入Redo Log日志文
件. Redo Log中的数据根据受影响的记录进行编码, 这些数据统称 Redo.  数据通过Redo Log的过程由不断增加的LSN值表示.

配置:

修改 InnoDB Redo Log 文件的数量或大小的步骤.

1) 停止 MySQL 服务器并确保它没有在错误的情况下关闭.

2) 更改 my.cnf 配置文件. 要更改日志文件大小, 配置 `innodb_log_file_size`. 要增加日志文件的数量, 配置 `innodB_log_file_in_group`

3) 重启 MySQL 服务器.

如果 InnoDB 检测到 `innodb_log_file_size` 与 Redo Log文件大小不同, 它会写入一个日志文件检查点, 关闭并删除旧的日志
文件, 创建新的日志文件(使用新的文件大小), 并打开新的日志文件.

Redo Log刷新的组提交:

InnoDB 在提交事务之前刷新事务的Redo Log. InnoDB使用组提交功能将多个刷新请求合并在一起, 以避免每次提交都刷新一次. 使用
组提交, InnoDB向日志文件发起单次写入, 以对几乎同时提交的多个用户事务执行提交操作, 从而提高吞吐量.

### Undo Log

Undo Log 是与单个读写事务关联的Undo Log记录的集合. Undo Log记录包含有关如何undo事务对聚集索引记录的最新更改信息. 如
果其他事务需要将原始数据视为一致读取操作的一部分, 则从 Undo Log记录中检索未修改的数据. Undo Log存在于Undo Log Segment
当中, Undo Log Segment包含在 Rollback Segment 中. Rollback Segment 驻留在system tablespace, undo tablespace
和temporary tablespace.

驻留在temporary tablespace当中的Undo Log用于修改用户定义的临时表中的数据的事务. 这些Undo Log不是Redo Log, 因为它
们不是崩溃恢复所必须的. 它们仅用于在服务器运行时进行回滚. 这种类型的Undo Log通过避免Redo Log记录来提高性能.

InnoDB 最多支持 128 个 Rollback Segment, 其中 32 个分配给 temporary tablespace. 剩下的96个Rollback Segment,
可以分配给常规表中的数据的事务. `innodb_rollback_segments` 定义了使用的回滚段数.

Rollback Segment支持的事务数取决于Rollback Segment中的 Undo Slot数量和每个事务所需的Undo Log数数量. Rollback 
Segment 中的 Undo Slot数量根据 InnoDB 的页大小而有所不同.

| Page Size | Undo Slots |
| --------- | ---------- |
| 4096(4KB) | 256 |
| 8192(8KB) | 512 |
| 16384(16KB) | 1024 |
| 32768(32KB) | 2048 |
| 65536(64KB) | 4096 |

一个事务最多被分配4个Undo Log, 操作类型如下:

1. INSERT 对用户定义表的操作

2. UPDATE 或 DELETE 对用户定义表的操作

3. INSERT 对用户定义的临时表的操作

4. UPDATE 或 DELETE 对用户定义临时表的操作

根据需要分配Undo Log. 例如, 对常规表和临时表执行 INSERT, UPDATE 和 DELETE 操作的事务需要分配4个撤销日志. 仅对常规
表执行INSERT操作的事务需要单个Undo Log.

对常规表执行操作的事务分配的Undo Log来自system tablespace或undo tablespace. 对临时表执行操作的事务分配的Undo Log
来自于temporary tablespace.

分配给事务的Undo Log在其持续时间内保持附加到事务. 例如, 为常规表上的 INSERT 操作分配给事务的Undo Log用于该事务执行常
规表上的所有的INSERT操作.

> InnoDB在达到能够支持的并发读写事务数之前, 可能会遇到并发事务限制错误. 当分配给事务的Rollback Segment使用完Undo Slot
时, 就会发生这种情况. 这种状况下, 请尝试重新执行事务.
> 当事务对临时表执行操作时, 能够支持的并发读写事务数受到分配给temporary tablespace的Rollback Segment的限制.

如果每个事务执行一个INSERT, UPDATE或DELETE操作, 最大并发读写事务数: 
(innodb_page_size / 16) * (innodb_rollback_segments - 32)


如果每个事务执行一个INSERT, 和一个UPDATE或DELETE操作, 最大并发读写数:
(innodb_page_size / 16 / 2) * (innodb_rollback_segments - 32)

如果每个事务对一个临时表执行一个INSERT, UPDATE或DELETE操作, 最大并发读写事务数: 
(innodb_page_size / 16 ) *32

如果每个事务对一个临时表执行一个INSERT, 和一个UPDATE或DELETE操作, 最大并发读写数:
(innodb_page_size / 16 / 2) * 32
