# MySQL 主-从相关的问题

## 并行复制算法

coordinator 分发的基本要求:

1.不能造成更新覆盖. 这要求更新同一行的两个事务, 必须被分发到同一个woker中.

2.同一个事务不能被拆开, 必须放到同一个worker中.

### 按表分发与按行分发

- 按表分发策略

按表分发事务的基本思路是, 如果两个事务更新不同的表, 它们可以并行. 因为数据是存储在表里, 所以按表分发, 可以保证两个worker
不会更新同一行.

如果有跨表的事务, 是需要把两张表放在一起考虑的. 例如:

```
worker1_hashtable:
  - db.t1: 4
  - db.t2: 1

worker2_hashtable:
  - db.t3: 1

worke3_hashtable:
  
  ...  
```

每个worker线程对应一个hash表, 用于保存当前正在这个 worker 的"执行队列"里的事务所涉及的表. hash表的 key 是 "库名.表名",
value是一个数字, 表示队列中有多少个事务修改这个表.

在有事务分配给worker时, 事务里涉及的表会被加到对应的hash表中. worker执行完成后, 这个表会被从 hash 表中去掉.

在上面的例子中, worker1_hashtable 表示, 现在在 worker1 的 "待执行事务队列" 里, 有4个事务涉及到表 "db.t1", 有1个事
务涉及到表 "db.t2". worker1_hashtable 表示, 现在在 worker1 的 "待执行事务队列" 里, 有1个事务涉及到表 "db.t3".

在例子当中的情况下, coordinator 从中转日志中读入一个新的事务T, 这个事务修改的行涉及到表 t1 和 t3. 那么:

1).由于事务T中涉及修改表t1, 而worker1队列中有事务在修改表t1, 事务T和队列中的某个事务要修改同一个表的数据, 这种情况下
事务T和worker1是冲突的.

2).按照这个逻辑, 顺序判断事务T和每个worker队列的冲突关系, 会发现事务T与worker2也冲突.

3).事务T跟对于一个worker冲突, coordinator 线程就进入等待.

4). 每个worker继续执行, 同时修改 worker 的 hash表. 假设 worker2_hashtable 里面涉及到修改表 t3 的事务先执行完成,
就会从 worker2_hashtable 中将 db.t3 这一项删除.

5).这样 coordinator 会发现跟事务T冲突的 worker 只有 woker1 了, 因此把它分配给 worke1.

6).coordinator继续读下一个中转日志, 继续分配事务.

每个事务在分发的时候, 跟所有worker的冲突关系包含三种:

1.如果跟所有worker都不冲突, coordinator 线程就会把这个事务分配给最空闲的 worker.

2.如果跟多于1个worker冲突, coordinator 线程就进入等待状态, 直到和这个事务存在冲突关系的worker只剩下1个.

3.如果只跟1个worker冲突, coordinator 线程就会把这个事务分配给这个存在冲突关系的 worker.

按表分发的方案, 在多个表负载均匀的场景里应用效果最好. 但是, 如果碰到热点表, 比如所有的更新事务都会涉及到某一个表的时候,
所有事务都会被分配到一个worker中, 就变成单线程复制了.


- 按行分发策略

按行分发核心思路: 如果两个事务没有更新相同的行, 它们在备库上可以并行执行. 这种模式要求 binlog 格式必须是 row.

这个时候, 判断一个事务T和worker是否冲突, 用的规则不再是"修改同一个表", 而是"修改同一行".

按行复制与按表复制的数据结构类似, 也是为每个worke分配一个 hash 表. 只是要实现按行分发, 这个时候的 key 的格式是, "库名+表名+唯一键的值".

但是, 这个 "唯一键" 只是主键id还不够, 还需要考虑到下面的场景, 表t1中除了主键, 还有唯一索引a:

```sql
CREATE TABLE `t1` (
  id int(11) NOT NULL,
  a  int(11) DEFAULT NULL,
  b  int(11) DEFAULT NULL,
  PRIMARY KEY (id),
  UNIQUE KEY a (a)
) ENGINE=InnoDB;

insert into t1 values(1,1,1),(2,2,2),(3,3,3),(4,4,4),(5,5,5);
```

接下来, 在主库当中执行两个事务:

```
session A:
update t1 set a=6 where id=1;

session B:
update t2 set a=1 where id=2;
```

可以看到, 这两个事务更新的行的主键值不同, 但是如果被分到不同的worker, 就有可能 session B的语句先执行. 这时候 id=1 的
行的 a 值还是1, 唯一键冲突, 导致主从复制失败.

因此, 按行分发, 事务 hash 表中还需要考虑唯一键, 即 key 应该是 "库名+表名+索引a的名称+a的值".

在上面的例子中, 在表 t1 上执行 `update t1 set a=1 where id=2` 语句, 在 binlog 里面记录了整行的数据修改前后各个字
段的值.

因此, coordinator 解析这个语句的 binlog 时候, 这个事务 hash 表有三个项:

1)key='db+t1+"primary"+2', value=2, 这里的2是因为前后的行id不变, 出现了2次

2)key='db+t1+"a"+2', value=1, 表示会影响到这个表的a=2的行

3)key='db+t1+"a"+1', value=1, 表示会影响到这个表的a=1的行


这两个方案存在的约束:

1.要能够从binlog里面解析出表名, 主键值和唯一索引的值. 也就是说, 主库的binlog必须是 row

2.表必须有主键

3.不能有外键. 表上如果有外键, 级联更新的行不会记录在 binlog 中, 这样冲突检查就不准确.

### MySQL5.6 并行复制

MySQL 5.6, 支持了并行复制, 只是支持的粒度是按库并行. 与前面的按行分发策略基本一致.

### MariaDB 的并行复制

MariaDB 并行复制利用了 redo log 组提交特性:

1) 能够在同一组里提交的事务, 一定不会修改同一行

2) 主库上可以并行执行的事务, 备库上也一定是可以并行执行的.

实现:

1.在一组里面一起提交的事务, 有一个相同的 commit_id, 下一组就是 commit_id+1;

2.commit_id 直接写入到 binlog 里面

3.传到备库应用的时候, 相同commit_id的事务分发到多个worker执行;

4.这一组全部执行完成后, coordinator 再去取下一批.
