## InnoDB 内存

InnoDB 架构模型:

![image](/images/mysql_innodb_architecture.png)

### Buffer Pool

Buffer Pool 是在 MySQL 启动时, 向操作系统申请的一片连续的内存空间, 默认配置下 Buffer Pool 只有128MB(可以通过调
整 `innodb_buffer_pool_size` 来设置 Buffer Pool 的大小), 用于在 InnoDB 访问时缓存表和索引数据. Buffer Pool
允许直接从内存访问经常使用的数据,从而加快处理速度. 

Buffer Pool 被划分为page, 以 page 作为磁盘和内存交互的基本单位, 一个 page 的默认大小是16KB(可以使用`innodb_page_size`
来调整 page 的大小). 使用链表的方式管理页面. 使用 LRU 算方法从缓存当中淘汰老的数据.

Buffer Pool 除了缓存 `索引页`, `数据页`, 还包括 `undo页`, `change buffer`, `锁信息`, `自适应哈希索引` 等.

Buffer Pool 页管理:

为了管理 Buffer Pool 中的缓存页, InnoDB 为每一个缓存页创建了一个`控制块`, 控制块信息包括缓存页的表空间, 页号, 缓存
页地址, 链表节点等等. 控制块也需要占用内存空间, 它是放在 Buffer Pool 的最前面, 接下来才是缓存页.

![image](https://cdn.xiaolincoding.com/gh/xiaolincoder/ImageHost4@main/mysql/innodb/缓存页.drawio.png)

Buffer Pool 页面的管理是通过三类链表管理的, 分别是 Free 链表, Flush 链表, LRU 链表.

Free 链表用于管理空闲页, 链表的节点就是一个个控制块, 每个控制块包含对应缓存页的地址, 所以相当于 Free 链表节点都对应
一个空闲的缓存页.

Flush 链表, 与 Free 链表类似, 区别在于 Flush 链表的每个节点对应的是一个脏页, 后续会进行刷盘操作.

LRU 链表, 这个主要为了提高缓存命中率设计的. 由于 Buffer Pool 的大小是有限的, 对于频繁访问的数据希望一直留在 Buffer
Pool 当中, 而很少访问的数据希望被淘汰掉, 为了达到这个目的, 使用了 LRU 算法.

Buffer Pool 当中有三种页:

Free Page(空闲页), 表示此页未被使用, 位于 Free 链表;

Clean Page(干净页), 表示此页已被使用, 但是页面未发生修改, 位于 LRU 链表.

Dirty Page(脏页), 表示此页已被使用且已被修改, 其数据和磁盘上的数据已经不一致. 当脏页上的数据写入磁盘后, 内存数据和
磁盘数据一致, 那么该页就变成了 Clean Page. 脏页同时存在于 LRU 链表和 Flush 链表.


- LRU 算法

使用LRU算法的变体, 将 Buffer Pool 作为链表进行管理. 当需要想空间将新页面添加到Buffer Pool时, 最近最少使用的页面将被
淘汰, 并将新页面添加到链表的中间. 这个中点插入策略将链表视为两个子链表:

1. 头部是最近访问过的 young 区域子链表(热点数据)
2. 尾部是最近访问较少的 old 区域子链表

![image](/images/mysql_innodb_buffer_pool_list.png)

该算法将经常使用的页面保存在新子链表中. 旧子链表包含较少使用的页面, 这些页面可能会被淘汰.

默认情况下,算法操作如下:

1) 3/8 Buffer Pool用于 old 区域子链表(old区域子链表占比数量的配置是 innodb_old_blocks_pct, 默认是 37).

2) 链表的 "中点" 是 young区域子链表的尾部与 old区域子链表头部的边界.

3) 当InnoDB 将一个页面读入到Buffer Pool时, 最初会将页面插入到 "中点" (old区域子链表的头部). 读取一个页面, 因为它
是用户发起的操作(如SQL查询)所需要的, 或者是InnoDB执行预读操作的一部分.

4) 访问 old区域子链表的页面会使其变得 "young", 将其移动到 young区域子链表的头部. 如果页面是因为用户发起的操作需要它
而被读取, 则第一次访问立即发生, 并且页面会变得"young". 如果页面是由于预读操作而读取的, 则第一次访问不会立即发生, 并
且在该页面被删除之前根本不会进行一次访问.

> 对于某个处于 old 区域的缓存页进行第一次访问时, 会在其对应的控制块中记录访问时间, 如果在后续的访问时间与第一次访问
> 时间间隔小于 "innodb_old_blocks_time", 那么`该缓存页不会从 old 区域子链表移动到 young 区域子链表的头部`. 否
> 则, `该缓存页从 old 区域子链表移动到 young 区域子链表的头部`.
> innodb_old_blocks_time 默认是 1000ms. 上述的限制条件是为了解决 Buffer Pool 污染的问题, 防止因为全表
> 扫描查询导致整个 Buffer Pool 的热点数据被淘汰.

5) 随着数据库的运行, Buffer Pool 中未被访问的的页面通过向链表尾部移动来 "old". young区域子链表中的页面随着其他页面的更新而
老化. old区域子链表中的页面也会随着页面插入中点而老化. 最终, 一个未使用的页面到达使得 old区域子链表的尾部被淘汰.

- Bufer Pool配置

1. 配置 InnoDB Bufer Pool 大小, `innodb_buffer_pool_size`, 默认是128MB

2. 配置多个Bufer Pool实例, 参数 `innodb_buffer_pool_instances`, 默认值是1. 在 InnoDB 当中当 Buffer Pool
的大小小于 1GB 时, 此参数无效.

- 使用 InnoDB 标准监视器监测Buffer Pool

命令: `SHOW ENGINE InnoDB STATUS`. 在 `BUFFER POOL AND MEMORY` 当中输出.

```
...
----------------------
BUFFER POOL AND MEMORY
----------------------
Total large memory allocated 2198863872
Dictionary memory allocated 776332
Buffer pool size   131072
Free buffers       124908
Database pages     5720
Old database pages 2071
Modified db pages  910
Pending reads 0
Pending writes: LRU 0, flush list 0, single page 0
Pages made young 4, not young 0
0.10 youngs/s, 0.00 non-youngs/s
Pages read 197, created 5523, written 5060
0.00 reads/s, 190.89 creates/s, 244.94 writes/s
Buffer pool hit rate 1000 / 1000, young-making rate 0 / 1000 not
0 / 1000
Pages read ahead 0.00/s, evicted without access 0.00/s, Random read
ahead 0.00/s
LRU len: 5720, unzip_LRU len: 0
I/O sum[0]:cur[0], unzip sum[0]:cur[0]
...
```

| 名词 | 含义 |
| --- | --- |
| Total memory allocated | 缓存池总内存(字节) |
| Buffer pool size | 分配给缓存池的总页面大小 |
| Free buffers | 缓存池空闲链表的总大小(页) |
| Database pages | 缓存池LRU链表总大小(页) |
| Old database pages | 缓存池old LRU子链表的总大小(页) |
| Modified db pages | 当前在缓存池中修改的页数 |
| Pending reads | 等待读入缓存池的页数量 |
| Pending writes LRU | 要从LRU链表尾部写入旧脏数据页数 |
| Pending writes flush list | 检查点期间要刷新的缓存池页数量 |
| Pending writes single page | 缓存池当中等待写入的独立页面的大小 |
| Pages made young | LRU链表中年轻的页面总数(移动到"new"子链表的头部) |
| Pages made not young | LRU链表中年老的页面总数(保留在"old"子链表) |
| youngs/s | 每秒平均访问LRU链表导致页面变"年轻"的旧页面. 该指标仅适用于old页面. 它基于页面访问次数. |
| non-youngs/s | 每秒平均访问LRU链表导致页面变"年老"的旧页面. 该指标仅适用于old页面. 它基于页面访问次数. |
| Pages read | 从缓存池读取的总页数 |
| Pages created | 在缓存池中创建的页总数 |
| Pages written | 在缓存池写入的总页数 |
| reads/s | 平均每秒从缓存池读取的页数 |
| create/s | 平均每秒创建缓存池页的数 |
| write/s | 平均每秒缓存池写入的页数 |
| Buffer pool hit rate | 从缓存池读取的页面与从磁盘读取页面的命中比率 |
| young-making rate | 页面访问的平均命中率导致页面年轻. 考虑了所有缓存池页面访问, 而不仅仅是old子链表的页面访问. |
| not(young-making) | 页面访问的平均命中率未导致页面年轻 |

> - `youngs/s`, 如果在没有发生大扫描时看到非常低的值, 考虑减少延迟时间或用于增加old子链表的缓存池的百分比. 增加old子
链表百分比, 使得该子链表的页面移动到尾部所需的时间变长, 这增加了再次访问这些页面并使其变得年轻的可能性.
> - `non-young/s`, 在执行大型表扫描时没有看到更高的值. 请增加延迟时间.

### Change Buffer 

Change Buffer(写缓冲) 一种特殊的数据结构, 它是一种应用在非唯一普通索引页(non-unique secondary index page)不在缓冲
池中时, 对页进行了写操作, 并不会立刻将磁盘页加载到缓冲池, 而仅仅记录缓冲变更(Buffer Changes), 在未来数据被读取时, 再将
数据合并(Merge)恢复到缓冲池中的技术. Change Buffer(写缓冲)的目的是降低写操作的磁盘IO, 提升数据库性能.

写缓冲更改, 可能是由INSERT, UPDATE 或 DELETE 操作(DML)引起的, 稍后在页面通过其他读取操作加载到 Buffer Pool 时被合并.

![image](/images/mysql_innodb_change_buffer.png)

与聚集索引不同, none-unique secondary index 是非唯一的, 并且插入二级索引以随机的顺序发生. 类似的, 删除和更新也可
能会影响索引树中不相邻的二级索引页面. 

在内存中, Change Buffer 占用了Buffer Pool的一部分. 在磁盘上, Change Buffer是system tablespace(ibdata文件)的一部分, 
当数据库服务关闭时, 索引更改将存储在其中.

Change Buffer中的数据类型由 `innodb_change_buffering` 变量控制. 

如果 "索引包含降序索引列" 或 "主键包含降序索引列", 则二级索引不支持 Buffer Pool.


Change Buffer 工作原理:

考虑一个场景: 假设要修改的页40不在缓冲池当中.

![image](/images/mysql_innodb_mem_changebuffer_pagenotin.png)

通常的处理过程是:

- 先需要为 40 的索引页从磁盘加载到缓冲池, 一次磁盘随机读取操作;
- 修改缓冲池中的页, 一次内存操作;
- 写入 redo log, 一次磁盘顺序写操作;

这种场景, 至少产生一次磁盘IO, 对于写多读少的业务场景, 是否还有优化的空间?

InnoDB 当中使用写缓冲优化后, 操作流程为:

![image](/images/mysql_innodb_mem_changebuffer_pagenotin_op.png)

- 在写缓冲中记录这个操作, 一次内存操作;
- 写入 redo log, 一次磁盘顺序写操作;

> 其性能与这个索引页在缓冲池中, 相近

上述的优化是否会出现一致性问题? 不会. 1)数据库异常崩溃, 能够从 redo log 当中恢复数据; 2)写缓冲不只是一个内存结构, 
它也会被定期刷写到系统表空间; 3)数据读取是, 有其他的流程, 将数据合并到缓冲池;

假设在稍后的时间, 有请求查询索引页40的数据:

- 载入索引页, 缓冲池未命中, 这次磁盘IO不可避免;
- 从写缓冲读取相关信息;
- 恢复索引页, 放到缓冲池 LRU 里, 此时40这一页才被真正的读取到缓冲池当中.

其他问题:

- 为什么写缓冲优化, 仅适用于非唯一普通索引页?

InnoDB 当中, 聚餐索引(Clustered index)与普通索引(Secondary index) 存在差异. 如果索引设置了唯一(Unique) 属性, 
在进行修改操作时, InnoDB 必须进行唯一性检查. 也就是说, 索引页即使不在缓冲池, 磁盘上的页读取无法避免(否则怎么校验是否
唯一), 此时就应该直接把相应的页放入缓冲池再进行修改.

- 触发 Change Buffer 当中数据被刷写的场景?

1) 数据页被访问, 数据被合并到缓冲池当中

2) 后台线程, 定时刷写到系统表空间

3) 数据库缓冲池不够用时, 写到系统表空间

4) 数据库正常关闭, 写到系统表空间

5) redo log 写满(几乎不会出现redo log写满, 此时整个数据库处于无法写入的不可用状态)


详细设置:

当对表执行INSERT, UPDATE 和 DELETE 操作时, 索引列的值(尤其是二级索引列的值)通常是未排序的, 这时需要大量IO才能使二级
索引保持最新. 当相关页面不在Buffer Pool时, Change Buffer缓存对二级索引条目的修改, 从而通过不立即从磁盘读取页面来避免
昂贵的IO操作. 当页面加载到Buffer Pool时, Change Buffer会被合并, 并且更新的页面稍后会被刷新到磁盘. InnoDB 主线程在
服务器几乎空闲或在关闭期间, 会合并Change Buffer.

因为它可以减少磁盘读取和写入, 所以Change Buffer对IO密集型的工作很有用. 例: 具有大量DML操作(例如批量插入)的程序得益于
Change Buffer.

Change Buffer 占用 Buffer Pool 的一部分, 从而减少了可用于缓存数据页的内存. 如果工作数据集几乎适合 Buffer Pool, 
或者数据库的表具有相对较少的 none-unique secondary index, 则禁用 Change Buffer 比较有用. 
如果工作数据集完全适合Buffer Pool, 则 Change Buffer 不会带来额外的开销, 因为它仅适用于不在 Buffer Pool 中的页面.

`innodb_change_buffering` 变量控制 InnoDB 执行 Change Buffer 的操作. 可以在插入, 删除操作(索引记录最初标记为
删除)和清除操作(索引记录被物理删除)启用或禁用缓存. 更新操作是插入和删除的组合. `innodb_change_buffering` 默认值是 
all.

a) all: 缓存插入, 标记删除, 清除操作.

b) none: 不缓存任何操作.

c) inserts: 缓存插入操作.

d) deletes: 缓存标记删除操作.

e) changes: 缓存插入和标记删除操作.

f) purge: 缓存在后台发生的物理删除操作.

`innodb_change_buffer_max_size` 变量设置最大允许将Buffer Pool作为Change Buffer百分比. 默认值是25. 最大设置为
50

考虑在具有大量插入, 更新和删除操作的MySQL服务器上增加 `innodb_change_buffer_max_size`, 其中Change Buffer合并无
法跟上新的Change Buffer条目, 会导致Change Buffer达到其最大大小限制.

考虑在静态数据的MySQL服务器上减少 `innodb_change_buffer_max_size`, 或者如果Change Buffer消耗了过多的Buffer Pool, 
导致页面比预期更早地从Buffer Pool中老化.

使用具有代表性的工作负载测试不同的设置值以确定最佳配置. `innodb_change_buffer_max_size` 变量可以动态调整.

### Doublewrite Buffer

关于 IO 的最小单位:
- 数据库 IO 的最小单位页是 16K(MySQL 默认)
- Linux 文件系统 IO 的最小单位页是 4K(通过 `getconf PAGESIZE` 获取)
- 磁盘 IO 的最小单位页是 512 字节.

**MySQL 将 Buffer Pool 中一页数据刷入磁盘, 需要 4 个文件系统的页(也可以说成一个 MySQL 数据页映射 4 个系统页)**

![image](/images/mysql_innodb_mem_doublebuffer_eg.png)

如图所示, MySQL 里 Page1 的页, 物理对应磁盘的 Page1, Page2, Page3, Page4 四个页. 刷写操作并非原子, 如果执行到
一半断电, 就会出现所谓的 "页数据损坏". 这种 "页数据损坏" 会导致数据完整性被破坏.(redo log 无法修复这类"页数据损坏"
的异常, 修复的前提是"页数据正确" 并且 redo 日志正常)

针对上述出现的情况, MySQL 使用 Doublewriter Buffer(用于存储数据页的"副本") 来解决该问题.

Doublewrite Buffer 工作:

![image](/images/mysql_innodb_mem_doublebuffer_work.png)

当有数据页要刷盘时:
1. 页数据西安 memcopy 到 Doublewrite Buffer 的内存里; (速度很快)
2. Doublewrite Buffer 内存里的数据页, 先刷写到 Doublewrite Buffer 的磁盘上(系统表空间, 顺序写入)
3. Doublewrite Buffer 内存里的数据页, 再刷写到数据磁盘存储 .ibd 文件上. (随机写, 必须要做), 完成后, 会将第一步的
Doublewrite Buffer标记为可覆盖.

注: Doublewrite Buffer 内存结构由128个页(Page) 构成, 所以容量只有 16KB x 128 = 2MB. 128页的Doublewrite Buffer
内存会分两次刷入磁盘, 每次最多64页, 即 1M 的数据(图中将 Doublewrite Buffer 磁盘结构拆分成两个部分).

Doublewrite Buffer 当中的 `Doublewrite` 是由于步骤2和步骤3当中需要2次刷盘由来的.

Doublewrite Buffer 开启会增加两步额外的操作(也就是步骤1和2), 这两步是执行是非常快的, 因此 Doublewrite Buffer 并
不会导致数据库的性能急剧下降, 但是性能会有一定的损耗.

Doublewrite Buffer 相关参数:

- innodb_doublewrite, Doublewrite Buffer开启/关闭的开关, 默认是开启的. InnoDB 将所有的数据存储两次, 首先到双
写缓冲区, 然后到实际数据文件.

- innodb_dblwr_pages_written, 记录写入到 Doublewrite Buffer 中的页数量(累加值)

- innodb_dblwr_writes, 记录写入到 Doublewrite Buffer 写操作的次数.

innodb_dblwr_pages_written/innodb_dblwr_writes 的比例是可以判断系统的负载情况. 如果约等于64, 说明系统的写压力
非常大, 有大量的脏页要往磁盘上写. 如果值比较小, 说明写脏页比较少, 系统压力比较小.

哪些情况下适合关闭 doublewrite buffer? 海量的 DML; 不惧怕数据损坏和丢失; 系统写负载成为主要负载;

> 由于 redo log 写入的单位是 512 字节(磁盘的最小单位), 不存在数据页损坏的情况, 因此不需要将在 redo 写入时去支持
> doublewrite buffer.

### Log Buffer
