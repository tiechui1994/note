## MySQL索引

### 索引的缺点
- 创建索引和维护索引要耗费时间, 这种时间随着数据量的增加而增加
- 索引需要占用物理空间, 除了数据表占用数据空间之外, 每一个索引还要占一定的物理空间, 如果建立聚簇索引, 那么需要的空间就会更大
- 当对表中的数据进行增加、删除和修改的时候, 索引也需要维护, 降低数据维护的速度

### 索引的优点
- 创建唯一性索引, 保证数据库表中每一行数据的唯一性
- 大大加快数据的检索速度, 这是创建索引的最主要的原因
- 加速数据库表之间的连接, 特别是在实现数据的参考完整性方面特别有意义
- 在使用分组和排序子句进行数据检索时, 同样可以显著减少查询中分组和排序的时间
- 通过使用索引, 可以在查询中使用优化隐藏器, 提高系统的性能

### 在什么情况下适合建立索引
- 为经常出现在关键字order by、group by、distinct后面的字段, 建立索引. 
- 在union等集合操作的结果集字段上, 建立索引. 其建立索引的目的同上. 
- 为经常用作查询选择 where 后的字段, 建立索引. 
- 在经常用作表连接 join 的属性上, 建立索引. 
- 考虑使用索引覆盖. 对数据很少被更新的表, 如果用户经常只查询其中的几个字段, 可以考虑在这几个字段上建立索引, 从而将表的
扫描改变为索引的扫描. 


### 索引失效

- 如果MySQL估计使用全表扫秒比使用索引快, 则不适用索引. 

例如, 如果列key均匀分布在1和100之间, 下面的查询使用索引就不是很好:`select * from table_name where key>1 and key<90;`

- 如果条件中有or, 即使其中有条件带索引也不会使用

例如:`select * from table_name where key1='a' or key2='b';`如果在key1上有索引而在key2上没有索引, 则该查询也
不会走索引

- 复合索引, 如果索引列不是复合索引的第一部分, 则不使用索引（即不符合最左前缀）

例如, 复合索引为(key1,key2),则查询`select * from table_name where key2='b';`将不会使用索引

- 如果like是以 % 开始的, 则该列上的索引不会被使用. 

例如 `select * from table_name where key1 like '%a';` 该查询即使key1上存在索引, 也不会被使用如果列类型是字符串, 
那一定要在条件中使用引号引起来, 否则不会使用索引

- 如果列为字符串, 则**where条件中必须将字符常量值加引号**, 否则即使该列上存在索引, 也不会被使用. 

例如,`select * from table_name where key1=1;` 如果key1列保存的是字符串, 即使key1上有索引, 也不会被使用. 

- 如果使用MEMORY/HEAP表, 并且where条件中不使用"="进行索引列, 那么不会用到索引, head表只有在"="的条件下才会使用索引