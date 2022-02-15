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

### tablespace

#### system tablespace

数据字典(Data Dictionary), 双写缓冲区(Doublewrite Buffer), 修改缓冲区(Change Buffer), undo日志(Undo Logs)
的存储区域. 如果在 system tablespace 中创建table, 而不是在 file-per-table 或 general tablespace 当中创建 table,
则它也可能包含table和索引数据.

system tablespace 可以具有一个或多个数据文件. 默认情况下, 在 data 目录下创建一个名为 `ibdata1` 的单个文件. 文件的
大小和数量由 `innodb_data_file_path` 启动选项定义.

#### file-per-table tablespace

包含单个InnoDB表的数据和索引, 并存储在文件系统中单个数据文件中.

配置:

InnoDB 默认情况下在 file-per-table tablespace 当中创建 table. 此行为由 `innodb_file_per_table` 变量控制.
当 `innodb_file_per_table` 为 OFF 时, InnoDB 会在 system tablespace 当中创建 table.

数据文件:

在 MySQL 数据库目录中的 `.idb` 数据文件中, 创建了 file-per-table tablespace. `.ibd` 文件是以表名称命名的.

> 可以使用 `CREATE TABLE` 语句的 `DATA DIRECTORY` 子句在 data 目录之外创建 file-per-table tablespace的数据
文件.

优点:

1. `TRUNCATE` 或 `DROP` 在 file-per-table tablespace 当中创建的表后, 磁盘空间将返还给OS. `TRUNCATE` 或 `DROP` 
在 share tablespace 当中创建的表后, 该可用空间仅可用于 InnoDB 数据(换句话, share tablespace数据文件的大小不会缩小).

2. 对驻留在 share tablespace 的表进行复制 ALTER TABLE 操作可以增加 tablespace 占用的磁盘空间. 此类操作可能需要与
表中数据加索引一样多的额外空间. 该空间不会像file-per-table tablespace那样释放返还给OS.

3. file-per-table tablespace 的表中执行删除时, `TRUNCATE TABLE` 性能会更好.

4. 可以在单独的存储设备上创建 file-per-table tablespace数据文件, 以进行IO优化, 空间管理或备份.
 

#### undo tablespace

undo tablespace 包括 Undo Log, 它们是有关如何撤销事务对聚集索引记录的更新信息记录.

Undo Log 默认存储在 system tablespace 当中, 但可以存储在一个会多个 undo tablespace 当中. 使用 undo tablespace
可以减少任何一个tablespace中 Undo Log 所需的空间数量. 

InnoDB 使用的 undo tablespace 的数量由 `innodb_undo_tablespaces` 控制. 该选项只能在初始化 MySQL 实例时配置, 之
后无法修改.

undo tablespace 和 tablespace 当中的 segment 不能删除. 但是, 存储在undo tablespace当中的 Undo Log 可以截断.

配置:

当配置了 undo tablespace 时, Undo Log 存储在 undo tablespace 而不是 system tablespace.

undo tablespace 的数量只能在初始化 MySQL 实例时配置, 并且实例的生命周期内是固定的.

1. 使用 `innodb_undo_directory` 指定 undo tablespace 的目录位置. 如果未指定, 则为数据目录.

2. 使用 `innodb_rollback_segments` 变量定义回滚段的数量. 从一个相对较低的值开始, 随着时间的推移, 逐渐增加它以检查
对性能的影响. `innodb_rollback_segments` 默认值是 128, 这也是最大值.

一个 rollback segment 总数分配给 system tablespace, 32 个rollback segment 保留给temporary tablespace.
因此, 要将rollback segment分配给 undo tablespace, 需要将 `innodb_rollback_segments` 设置为大于 33 的值. 例
如, 如果有 2 个undo tablespace中的每一个分配一个rollback segment. `innodb_rollback_segments` 设置为 35. 
rollback segment 以循环方式分布在 undo tablespace中.

当增加 undo tablespace时, system tablespace 当中的 rollback segment 将表现为非活动状态.

3. 使用 `innodb_undo_tablespace` 定义 undo tablespace 的数量. 

截断:

截断 undo tablespace 要求 MySQL 实例至少有两个 active 的 undo tablespace, 确保一个undo tablespace保持active,
从而另一个可以脱机截断. undo tablespace 空间的数量由 `innodb_undo_tablespaces`. 默认值是 0.

要截断 undo tablespace, 请启用 `innodb_undo_log_truncate` 变量. 例如:

```
mysql> set global innodb_undo_log_truncate=ON; 
```

当启用 `innodb_undo_log_truncate` 时, 超过 `innodb_max_undo_log_size` 的大小限制的 undo tablespace 将被截断.
`innodb_max_undo_log_size` 是动态的, 默认值是 1024 MB

当启用 `innodb_undo_log_truncate` 时:

1. 超过 `innodb_max_undo_log_szie` 的 undo tablespace 被标记为截断. 以循环方式选择用于截断的 undo tablespace,
以避免每次截断相同的 undo tablespace.

2. 驻留在选定的 undo tablespace 中的回滚段变为 inactive 状态, 因此它们不会分配给新事务. 当前正在使用回滚段的现有事务
被允许完成.

3. 通过释放 Undo Log 不再使用的空间来清空回滚段.

4. 在 undo tablespace 中所有回滚段都被释放后, 截断操作允许, 并将 undo tablespace截断为其初始大小. undo tablespace
的初始大小取决于 `innodb_page_size` 值. 对于默认的 16KB 页, 初始undo tablespace文件大小为 10MB. 对于4KB, 8KB,
32KB, 64KB, 初始大小分别是7MB, 8MB, 20MB, 40MB.

由于在截断操作完成后立即使用 undo tablespace, 因此, 截断后 undo tablespace的大小可能大于初始大小.

`innodb_undo_directory` 定义了 undo tablespace 的文件位置. 如果未定义, 默认的位置是数据目录.

5. 回滚段被重新变为 active, 以便将它们分配给新的事务.

加快截断:

purge线程负责清空和截断 undo tablespace. 默认情况下, purge 线程每调用 128 次清除就会查找undo tablespace 以截断
一次. purge 线程查找要截断的 undo tablespace 的频率由 `innodb_purge_rseg_truncate_frequency` 控制, 默认值是 
128

#### general tablespace

general tablespace 是使用 `CREATE TABLESPACE` 语法创建的共享 InnoDB tablespace.

功能:

1. 与 system tablespace 类似, general tablespace 是能够为多个表存储数据的共享tablespace.

2. 与 file-per-table tablespace 相比, general tablespace 具有潜在的内存优势. 服务器在tablespace的整个生命周期
内将 tablespace 元数据保存在内存当中. 与单独的 file-per-table tablespace中相同数量的表相比, 较少的 general tablespace
中的多个表消耗的 tablespace 元数据内存更少.

3. general tablespace 数据文件可以防止在相对于或独立于 MySQL 数据目录的目录当中. 与 file-per-table tablespace
一样, 将数据文件放在 MySQL 数据目录之外的能力允许你单独管理关键表的性能.

4. general tablespace 支持 Antelope 和 Barracuda 文件格式, 因此支持所有表行格式相关功能. 有支持这两种文件格式, 
general tablespace 不依赖 innodb_file_format 或 innodb_file_per_table 设置.

5. TABLESPACE 选项可以与 `CREATE TABLE` 一起使用, 以在 general tablespace, file-per-table tablespace 或
system tablespace 中创建表.

6. TABLESPACE 选项可以与 `ALTER TABLE` 一起使用, 以在 general tablespace, file-per-table tablespace 或
system tablespace 之间移动表.

#### temp tablespace
