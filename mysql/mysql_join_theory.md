# MySQL 专题 - join 原理

数据准备:

```sql
CREATE TABLE `t2` (
  `id` int(11) NOT NULL,
  `a` int(11) DEFAULT NULL,
  `b` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `a` (`a`)
) ENGINE=InnoDB;

drop procedure idata;
delimiter ;;
create procedure idata()
begin
  declare i int;
  set i=1;
  while i<=1000 do
    insert into t2 values(i, i, i);
    set i=i+1;
  end while;
end;;
delimiter ;
call idata();

create table t1 like t2;
insert into t1 (select * from t2 where id<=100)
```

### Index Nested-Loop Join

sql语句:

```sql
select * from t1 straight_join t2 on (t1.a=t2.a);
```

如果直接使用 join, MySQL 优化器可能会选择表 t1 或 t2 作为驱动表. 使用 straight_join, MySQL 会使用固定的连接方式执
行查询.

这条语句里, 被驱动表t2的字段a上有索引, join过程中用上了这个索引, 因此语句的执行流程:

1)从表t1读入一行数据R;

2)从数据行R中, 取出字段a, 到表t2里查找;

3)取出表t2中满足条件的行, 跟R组成一行, 放入结果集.

4)重复执行上述步骤1到3, 直到表t1的末尾循环结束.

### Block Nested-Loop Join

sql语句:

```sql
select * from t1 straight_join t2 on (t1.a=t2.b);
```

由于表t2的字段b上没有索引, 因此无法使用 Index Nested-Loop Join 的流程执行, 每次到 t2 去匹配的时候, 都要做一次全表
扫描.

该语句的执行流程如下:

1)把表t1的数据读入线程内存join_buffer, 由于是执行语句是 `select *`, 因此把整个表 t1 放入内存.

2)扫描表t2, 把表t2中的每一行取出来, 与 join_buffer 当中的数据比较, 满足 join 条件的, 作为结果集的一部分.

流程如下:

![image](/images/mysql_join_block_nlj_example.jpeg)

可以看到, 在这个过程中, 对表 t1 和 t2 都做了一次全表扫描, 因此总的扫描次数是 1100. 由于 join_buffer 是无序的, 因此
对表t2中的每一行， 都要做100次判断， 总共需要在内存中做的判断次数: 100*1000=10万次

在这种情况下, 应该选择哪个表做驱动表?

假设小表行数是 N, 大表行数是 M, 那么这个算法:

1.两个表都做一次全表扫描, 总扫描行数为 M+N

2.内存中的判断次数是M*N

可以看出, 调换 M 和 N是没有差别的, 这种情况下选择小表还是大表做驱动表, 执行的耗时是一样的.

但是, 这里还有一个影响因素: join_buffer, 如果扫描的表的 join_buffer 放不下呢, 那该如何? 这时候需要分段放.

还是以之前的语句为例, 此时将 join_buufer_size 设置为1200, 那么执行流程如下:

1.扫描表t1, 顺序读取数据放入join_buffer, 放完第88行join_buffer就满了, 继续第2步.

2.扫描表t2, 把t2表中的每一行取出来, 与join_buffer中的数据进行对比, 满足join条件的, 作为结果集的一部分返回.

3.清空 join_buffer

4.继续扫描表t1, 顺序读取最后的12行数据放入join_buffer, 继续执行第2步.

上述的流程才体现了算法 "Block" 的由来. 可以看到, 这个时候表 t1 被分为 2 次放入 join_buffer, 导致表 t2 会被扫描 2 
次, 虽然分为2次放入 join_buffer, 但是判断等值次数还是不变的. 依然是 10 万次.

假设, 驱动表行数是 N, 需要分为 K 次才能完成算法流程, 被驱动表数据行数是 M. 这里的 K 不是常数, N 越大, K 就越大. 可以
把 K 表示为 `λ*N`, 其中 `λ` 范围是 (0,1), 算法执行:

1.扫描行数 `N + λ*N*M`

2.内存判断 `N*M` 次

考虑到扫描行数, 在 M 和 N 之间, N 小一些, 整个结果会更小. 因此, 应该让小表作为驱动表.

关于 "小表", **在决定哪个表做驱动表的时候,应该是两个表按照各自的条件过滤,过滤完成之后, 计算参与join的各个字段的总数据量,
数据量小的那个表, 就是"小表", 用过作为驱动表.**


### Multi-Range Read 优化

Multi-Range Read 优化, 主要目的是尽量使用顺序读盘.

关于"回表", InnoDB 在普通索引 a 上查到主键id 的值后, 再根据一个个主键id的值到主键索引上去查整行数据的过程.

回表过程是一行行地查数据, 还是批量地查数据?

```
select * from t1 where a>=1 and a<=100; 
```

> t1 表, 在 a 上存在普通索引.

主键索引是一棵 B+ 树, 每次只能根据一个主键 id 查到一行数据. 因此, 回表肯定是一行行搜索主键索引的.

如果随着 a 的值递增顺序查找的话, id的值变得随机, 那么就会出现随机访问, 性能相对较差. 虽然"按行查"这个机制不能改, 但是调
整查询的顺序, 还是能够加速的.

**因为大多数的数据都是按照主键递增顺序插入得到的, 所以可以认为, 如果按照主键递增顺序查询的话, 对磁盘的读比较接近顺序读,
就能够提升读性能.**

上述就是 MRR 优化的设计思路. 此时, 之前语句执行的流程如下:

1)根据索引a, 定位满足条件的记录, 将id放入read_rnd_buffer当中;

2)将read_rnd_buffer中的id进行递增排序;

3)排序后的id数组,依次到主键id索引中查记录, 并作为结果返回.

read_rnd_buffer 是由于 read_rnd_buffer_size 控制大小的(默认是256KB). 如果在步骤1当中, read_rnd_buffer满了, 就
会先执行步骤2和3, 然后清空 read_rnd_buffer. 之后继续到步骤1.

> 注: 如果要稳定地使用MRR优化, 需要设置 set optimizer_swithch="mrr_cost_based=off". (官方文档, 现在的优化器策
略, 判断消耗的时候, 会更倾向于不使用MRR, 把mrr_cost_based设置为off, 就是固定使用MRR了)

**MRR能够提升性能的核心在于, 这条查询语句在索引a上做的是一个范围查询(多值查询), 可以得到足够多的主键id. 通过排序后, 再
去主键索引查数据, 才能体现'顺序性'的优势.**

### Batched Key Access

BKA 算法, 是对 NLJ(Index Nested-Loop Join) 算法的优化.

![image](/images/mysql_join_index_nlj.jpeg)

NLJ 算法逻辑: 从驱动表 t1, 一行行地取出 a 的值, 再到被驱动表 t2 去做 join. 也就是说, 对于表t2而言, 每次都是匹配一个
值, 这时MRR的优势就用不上了.

如何才能一次性多传些值给表t2呢? 就是从表t1里一次性地多拿些行, 一起传递给表 t2.

既然如此, 就把表t1的数据取出来一部分, 先放到临时内存(join_buffer), 从而可以使用到 MRR 优化.

下图就是 NKL 优化后的 BKA 算法流程:

![image](/images/mysql_join_index_bka.jpeg)

图中, join_buffer 里放入数据是 R1~R100(已经按照 a 字段排好顺序, 这样后续查找 t2 表的索引可以使用 MRR 优化了), 表示
的是只保存查询(join条件)所需要的字段. 如果 join_buffer 放不下这么多数据, 那么就会分成多段执行上图的流程. 

> 使用 BKA 优化算法, 需要设置 `set optimizer_switch='mrr=on,mrr_cost_based=off,batched_key_access=on';` 
其中前两个参数是启用MRR, 因此 BAK 依赖 MRR.

### Block Nested-Loop Join 算法性能

在使用 Block Nested-Loop Join 时, 可能会对被驱动表进行多次扫描. 如果这个被驱动表是一个大的冷数据表, 除了会导致IO压力
大外, 还有什么影响?

之前提到, InnoDB 对 Buffer Pool 的LRU算法做了改进, 即: 第一次从磁盘读入内存的数据页, 会先放到old区域. 如果1秒之后
这个数据页不再被访问了, 就不会移动到LRU链表头部, 这样对Buffer Pool的命中率影响不大.

但是, 如果一个使用 BNL 算法的 join 语句, 多次扫描一个冷表, 而且这个语句执行时间超过1秒, 就会在再次扫描冷表的时候, 把冷
表的数据页移到LRU链表头部. 这种情况下对应的, 冷表数据量小鱼整个Buffer Pool的3/8, 能够完全放入 old 区域.

如果冷表很大, 就会出现另外一种情况: 业务正常访问的数据页, 没有机会进入 young 区域. 一个正常访问的数据页, 要进入 young 
区域, 需要间隔1秒后再次被访问到. 但是, 在join语句循环读磁盘和淘汰内存页, 进入old区域的数据页, 很可能在1秒之内就被淘汰
了. 这样就会导致整个 MySQL 实例的 Buffer Pool 在这段期间, young 区域的数据页没有被合理的淘汰.

**大表join操作虽然对IO有影响, 但是在语句执行结束后, 对IO的影响也就结束了. 但是, 对Buffer Pool的影响是持续的, 需要依
靠后续的查询请求慢慢恢复内存命中率.**

为了减少上述请, 需要考虑增大 join_buffer_size 值, 减少对被驱动表的扫描次数.

BNL的影响来自三个方面:

1)可能会多次扫描被驱动表, 占用磁盘IO资源;

2) 判断join条件需要执行 M*N 次内存比较, 如果是大表, 会占用非常的CPU资源.

3) 可能导致 Buffer Pool的热数据被淘汰, 影响内存命中率.

如果要优化 BNL 算法, 常见做法就是给被驱动表 join 字段加上索引, 将 BNL 转换为 BKA.

### BNL 转 BKA

一些情况下, 可以直接在被驱动表上建索引, 这时就可以直接转换为 BKA 算法了.

但是, 确实碰到一些不适合在被驱动表上建索引, 比如:

```
select * from t1 join t2 on (t1.b=t2.b) where t2.b>=1 and t2.b<=2000;
```

在表t2当中有100万条数据, 但是经过where条件过滤后, 需要参与 join 的只有 2000 多行了. 如果这条语句同时也是一个低频的
SQL语句, 那么在表t2上为字段b创建一个索引就很浪费了.

使用 BNL 算法 join 的话, 执行流程如下:

1)把表t1的所有字段取出, 存入 join_buffer. 该表是1000行, join_buffer_size默认是254k, 可以完全存入.

2)扫描表t2, 取出每一行数据与 join_buffer 中是数据比较. 如果不满足 t1.b=t2.b, 跳过; 如果满足 t1.b=t2.b, 再判断其
他条件, 也就是是否满足 t2.b 处在 `[1,2000]` 的条件, 如果是, 就作为结果集的一部分返回, 否则跳过.

经过实际测试, 该语句执行大约得 1 分钟左右.

在表t2的字段b上创建索引是浪费资源, 但是不创建索引的话, 等值条件要判断10亿次. 这时候, 可以考虑使用临时表. 大致思路:

1)把表t2中满足条件的数据存放到临时表 tmp_t 中.

2)为了让join使用BKA算法, 给临时表 tmp_t 加上索引;

3)让表t1和tmp_t做 join 操作.

```sql
create temporary table temp_t(
  id int primary key, 
  a int, 
  b int, 
  index(b)
) engine=innodb;

insert into temp_t select * from t2 where b>=1 and b<=2000;
select * from t1 join temp_t on (t1.b=temp_t.b);
```

另一种思路: 将表 t1 和 t2 满足要求的数据全部查询出来, 然后在业务端使用 hash 匹配.