# EXPLAIN

[文档](https://weikeqin.com/2020/02/05/mysql-explain/)

[文档](https://segmentfault.com/a/1190000012629884)

案例:

```
mysql root@localhost:test> explain select * from `user` \G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | user
partitions    | <null>
type          | index
possible_keys | <null>
key           | PRIMARY
key_len       | 36
ref           | <null>
rows          | 12
filtered      | 100.0
Extra         | Using index
```

各个列的含义:

- id: SELECT 查询的标识符. 每个SELECT都会自动分配一个唯一的标识符.

- select_type: SELECT查询的类型

- table: 查询涉及到的表或衍生表

- partions: 匹配分区表的分区

- type: 判断此次查询是 `全表扫描` 还是 `索引扫描` 等

- possible_keys: 此次查询中可能选用的索引

- key: 此次查询中确切使用到的索引

- ref: 哪个字段或常数与key一起被使用

- rows: 显示此次查询一共扫描了多少行. 这是一个估计值

- filtered: 此查询条件所过滤的数据的百分比

- extra: 额外的数据.


### select_type

select_type 表示查询的类型, 它的取值有:

- SIMPLE, 表示此查询不包含 "UNION查询" 或 "子查询".

- PRIMARY, 表示此查询最外层的 SELECT.

- UNION, 表示此查询是 UNION 的第二个查询, 或者 UNION 当中更后面的查询.

- DEPENDENT UNION, UNION 中的第二个或后面的查询语句, 依赖于外面的查询.

- UNION RESULT, UNION 的结果.

- SUBQUERY, 子查询中的第一个 SELECT. 

- DEPENDENT SUBQUERY, 子查询中的第一个SELECT, 依赖于外面的查询, 即子查询依赖外层查询的结果.

- DERIVED, 表示派生 SELECT (在FROM子句中的子查询)

- MATERIALIZED, 表示物化子查询

- UNCACHEABLE SUBQUERY, 表示子查询结果无法缓存, 必须针对外部查询的每一行重新进行评估.

- UNCACHEABLE UNION, 表示在UNION中属于不可缓存子查询的第二个或更后面的查询.

> `DEPENDENT` 通常表示使用相关子查询.
>
> `DEPENDENT SUBQUERY` 评估与评估不同 `UNCACHEABLE SUBQUERY`. 因为 `DEPENDENT SUBQUERY` 子查询对于外部上下
文中的每一组不同的变量值只重新计算一次. 对于 `UNCACHEABLE SUBQUERY` 外部上下文的每一行, 子查询都会被重新评估.
>
> 子查询的可缓存性不同于查询缓存中查询结果的缓存.
>
> `DERIVED` 出现在派生表查询中. 派生表是在查询FROM子句范围内生成表的表达式.


案例1: 查询 select_type 为 `DERIVED`. 

```
CREATE TABLE `t1` (
  `id` int(11) DEFAULT NULL,
  `rank` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO t1 VALUES (1,3);
INSERT INTO t1 VALUES (1,5);
INSERT INTO t1 VALUES (2,4);
INSERT INTO t1 VALUES (2,5);
INSERT INTO t1 VALUES (3,4);
```

查询一个分组表中的一组总和的平均值.

```sql
SELECT AVG(sum_rank) 
    FROM (SELECT SUM(rank) as sum_rank 
          FROM t1 GROUP BY id) as t;
```

请注意: 子查询(sum_rank) 中使用的列名在外部查询中被识别.

> 派生表(`derived table`) 可以返回 `标量`, `列`, `行` 或 `表`. 
> 派生表不能是`相关的子查询`, 或者 `包含外部引用或对其他表的引用的查询`. 


### type

> 索引的分类: 聚簇索引(也称为主键)和二级索引(普通索引). 
> 唯一索引全称是唯一二级索引, 是一种特殊的二级索引.

[文档](https://mengkang.net/1124.html)

[文档](https://www.cnblogs.com/zhanjindong/p/3439042.html)

它提供了判断查询是否高效的重要依据. 通过 type 字段, 可以判断此次查询是 `全表扫描` 还是 `索引扫描`等.

type 的值:

- system

该表只有一行(=系统表). 这个类型是 const 类型的特例.

- const

该表至多有一个匹配的行, 在查询开始时读取. 由于只有一行, 因此该行中列的值可以被优化器的其余部分视为常亮. const 表非常快,
因为它们只读一次.

针对索引是 `PRIMARY KEY` 或 `UNIQUE NOT NULL` 的值查询扫描, 最多只返回一行数据. const 查询速度非常快, 因为它仅仅
只读取一次.

```
mysql root@localhost:test> explain select * from order_info where id=1\G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | order_info
partitions    | <null>
type          | const
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | const
rows          | 1
filtered      | 100.0
Extra         | <null>
```

- eq_ref 

对于前面的表中的每一行的组合, 从这个表读取一行. 除了 system 和 const 类型, 这是最好的 join type. 当 join 使用索引
的所有部分并且索引是 `PRIMARY KEY` 或 `UNIQUE NOT NULL` 索引时使用它.

eq_ref 可以用于使用 `=` 运算符进行比较的索引列. 比较值可以是一个常量, 也可以是一个表达式, 该表达式使用在此表之前读取的
表中的列.

```
# 关联查询, 单列匹配

EXPLAIN SELECT * FROM ref_table, other_table 
    WHERE ref_table.key_column=other_table.column;


# 关联查询, 多列匹配(这里就使用到了常量)

EXPLAIN SELECT * FROM ref_table, other_table
    WHERE ref_table.key_column_part1=other_table.column AND ref_table.key_column_part2=1;
```

- ref

对于之前表中的每个行组合, 从此表中读取具有匹配索引值的所有行(注: 这里是多行). ref 如果 join 只使用最左边的前缀, 或者如
果索引不是 `PRIMARK KEY` 或者 `UNIQUE` 索引(换句话说, 如果 join 不能基于键值选择单个行), 则使用该索引. 如果使用的
索引只匹配几行, 这个是一个很好的 join type.

ref 可以用于使用 `=` 或 `<=>` 运算符进行比较的索引列. 

```
SELECT * FROM ref_table WHERE key_column=expr;

# 下面的两个例子和前面的例子是一样的, 但是区别在于使用的索引不一样.

SELECT * FROM ref_table, other_table
    WHERE ref_table.key_column=other_table.column;

SELECT * FROM ref_table, other_table
    WHERE ref_table.key_column_part1=other_table.column AND ref_table.key_column_part2=1;
```

- fulltext

join 使用 FULLTEXT 索引执行.

- ref_or_null

对于二级索引进行等值匹配查询, 该索引的值也可以是 NULL 值时, 那么对该表的访问方法的类型可能是 `ref_or_null`. 一般状况
下等值查询 filtered 列的值100.

这种连接类型与 ref 类似, 但是另外 MySQL 对包含 NULL 值的行进行额外的搜索. 这种连接类型优化最常用于解析子查询.

> 注意: 这是针对二级索引(索引可以是单列, 也可以是多列)的查询, 并且进行等值匹配查询(二级索引的前缀等值匹配).

```
SELECT * FROM ref_table
    WHERE key_column=expr OR key_column IS NULL;
```

- index_merge

一般情况下, 执行一个查询最多只会用到一个索引. 但是在特殊情况下也可能使用多个二级索引, 此时的 type 就是 index_merge. 
在这种情况下, 输出的 key 列包含使用索引列表, key_len列是包含所用索引长度的列表. 

合并分为三种: union, intersection, sort-union

1) intersection合并, 交集. extra列包含 `Using intersect(...)`

1.InnoDB表的主键上的任何范围.

2.二级索引前缀的N部分(即所有二级索引部分被覆盖): `key1=const1 AND key2=const2 AND keyN=constN`

例子:

```
# 主键索引, 二级索引
SELECT * FROM innodb_table
    WHERE primary_key < 10 AND key1 = 20;

# 一个复合二级索引和一个单列二级索引
SELECT * FROM innodb_tbale
    WHERE (key1_part1 = 1 AND key1_part2 = 2) AND key2 = 2;
```

2) union合并, 并集. extra列包含 `Using union(...)`

1.二级索引前缀的N部分(即所有二级索引部分被覆盖):  `key1=const1 OR key2=const2 OR keyN=constN`

例子:

```
SELECT * FROM tbl_name
    WHERE key1=1 OR key2=2
```


3) sort-union合并, union索引合并的使用条件太苛刻, 必须保证各个二级索引在进行等值匹配的条件下才能被用到. sort-union
索引合并: 先按照二级索引记录的主键值进行排序, 之后按照 union 索引合并方式执行. 这种 sort-union 索引合并比单纯的 union
索引合并多了一步对索引记录的主键值排序的过程. extra 列包含 `Using sort_union(...)`. 例如, 下面的例子就可能使用到 
sort-union:

```
SELECT * FROM tbl_name WHERE key1 < 'a' OR key2 > 'z';

SELECT * FROM tbl_name WHERE key1>6 OR key2<1
```


```
# key1, key2 分别都是索引.
SELECT * from tb1_name WHERE key1=10 OR key2=20;
SELECT * from tb1_name WHERE (key1=10 OR key2=20) AND non_key=30;
```

- unique_subquery

类似于两表中被驱动表的 `eq_ref` 访问方法, `unique_subquery` 是针对一些包含 `IN` 子查询的查询语句中, 如果查询优化器
决定将 `IN` 子查询转换为 `EXIST` 子查询, 而且子查询可以使用到主键进行等值匹配的话, 那么该子查询执行计划的 `type` 列
的值就是 `unique_subquery`. 例如:

```
SELECT * FROM tbl_name WHERE value IN (
    SELECT primary_key FROM signle_table WHERE signle_table.xxx=tbl_name.xxx
) OR|AND expr;
```

> 注意事项:
> 1.IN子查询
> 2.子查询返回主键
> 3.子查询当中等值连接匹配
> 4.查询还需要其他条件, 否则类型可能是 `eq_ref`

unique_subquery 只是一个索引查找函数, 可以完全替代子查询以提高效率.

- index_subquery

index_subquery 与 unique_subquery 类似. 只不过访问子查询中的表时使用的是普通索引.

```
SELECT * FROM tbl_name WHERE value IN (
    SELECT index_key FROM signle_table WHERE signle_table.xxx=tbl_name.xxx
) OR|AND expr;
```

- range

使用索引来选择行, 仅检索给定范围内的行. 输出行中的键列指示使用哪个索引. key_len 列是包含使用的最长的键部分. 此类型的 
ref 列为 NULL.
 
这个类型通常出现在 `=`, `<>`, `>=`, `<`, `<=`, `<=>`, `BETWEEN`, `IN` , `IS NULL` 操作中.

```
SELECT * FROM tbl_name WHERE key_column=10;

SELECT * FROM tbl_name WHERE key_column BETWEEN 10 AND 20;

SELECT * FROM tbl_name WHERE key_column IN (10, 20, 30);

SELECT * FROM tbl_name WHERE key_part1=10 AND key_part2 IN (10, 20, 30);
```

> 注意事项:
>
> - 不是索引查询语句使用了 `IN`, type 列就一定是 `range`, 也有可能是 `all` 或 `ref` (例如 `Where key IN (1)`
> 就是 `ref`)
> - 如果索引查询
> - 如果主键查询语句使用了 `IN`, `BETWEEN`, `<`, `>` 等条件, 一般情况下是 `range`.
> - 如果索引查询语句使用了 `IN`, `BETWEEN`, `<`, `>` 等条件, 并且

- index

表示全索引扫描(full index scan), 和 ALL 类型类似, 只不过 ALL 类型是全表扫描, 而 index 类型则仅仅扫描
所有的索引, 而不是扫描数据.

index 类型通常出现在: 
1) 如果索引是查询的覆盖索引, 并且可用于满足表中所需的所有数据, 则只扫描索引树. 在这种情况下, extra 列是 `Using index`.
仅扫描扫描通常比ALL快.

2) 全表扫描使用索引中读取来按索引顺序查找数据行. `Uses index` 不会查询在 extra 列中.
2) 使用对索引的读取执行全表扫描, 以按索引顺序查找数据行. 

当查询只使用属于单个索引一部分时, MySQL可以使用这种 join 连接类型.

- all

对来自之前表的行的每个组合进行全表扫描. 如果该表是未标记为const的第一个表, 则通常不好, 并且在所有其他状况下通常非常糟糕.
通常可以通过加索引来避免 ALL, 这些索引允许基于早期表中的常量值或列值从表中检索行.

全表扫描是针对之前表中的每一行组合完成的. 如果表是没有标记的第一个表 const, 通常情况不好, 而在其他状况下通常很糟糕. 通常
状况下

### key_len

key_len 列表示当优化器决定使用某个索引执行查询时, 该索引记录的最大长度, 它是由三部分构成的:

- 对于使用固定长度类型的索引列来说, 它实际占用的存储空间的最大长度就是该固定值; 对于指定字符集是变长类型的索引列来说, 比
如某个索引列的类型是 `VARCHAR(100)`, 使用的字符集是 `utf8`, 那么该列实际占用的最大存储空间就是 `100 x 3 = 300` 个
字节.

- 如果该索引列可以存储 `NULL` 值, 则 `key_len` 比不可以存储 `NULL` 值时多1个字节.

- 对于变长字段来说, 都会有2个字节的空间来存储该变长列的实际长度.

### ref

当使用索引列等值匹配的条件去执行查询时, 也就是在访问方法是 `const`, `eq_ref`, `ref`, `ref_or_null`, `unique_subquery`
`index_subquery` 其中之一时, ref 列展示的就是与索引列作等值匹配的具体信息, 比如一个常数或者是某个列.


### extra

extra 字段表示额外信息

- `Using filesort`, 当 extra 中有 `Using filesort` 时, 表示 MySQL 需额外的排序操作. 不能通过索引达到排序效果. 
一般有 `Using filesort`, 都建议优化去掉.

- `Using temporary`, 在许多查询的执行过程中, MySQL可能会借助临时表来完成一些功能, 比如去重, 排序之类的. 比如在执行
许多包含 `DISTINCT`, `GROUP BY`, `UNION` 等子句的查询过程中, 如果不能有效利用索引完成查询, MySQL 很可能寻求通过
建立内部的临时表来执行查询.

```
mysql> EXPLIAN SELECT DISTINCT none FROM t3 \G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | t3
partitions    | None
type          | ALL
possible_keys | None
key           | None
key_len       | None
ref           | None
rows          | 13
filtered      | 100.0
Extra         | Using temporary
```

建议使用最好使用索引来替换掉使用临时表.

- `Start temporary`, `End temporary`, 在将 IN 子查询转换成 `semi-join`, 如果执行策略采用 `DuplicateWeedout` 
时, 也就是通过建立临时表来实现为外层查询中的记录进行去重操作时,驱动表查询执行计划的 extra 列将显示 `Start temporary`, 
被驱动表查询计划的 extra 列将显示 `End temporary`.

- `LooseScan`, 在将 IN 子查询转换为 `semi-join` 时, 如果执行策略采用 `LooseScan`, 则在驱动表执行计划的 extra 列
将显示 `LooseScan`. 一般是使用到了索引.

> 注意: 驱动表的 extra 列

- `FirstMatch(table_name)`, 在将 IN 子查询转换为 `semi-join` 时, 如果执行策略采用 `FirstMatch`, 则在被驱动表
执行计划的 extra 列显示为 `FirstMatch(table_name)`

> 注意: 被驱动表的 extra 列


- `Using join buffer (Block Nested Loop)`, 在连接查询执行过程中, 当被驱动表不能有效的利用索引加快访问速度, MySQL
一般会为其分配一块叫 `join buffer` 的内存块来加快查询速度, 也就是常说的`基于块的嵌套循环算法`.

- `Using index condition`

- using index, 覆盖索引扫描, 表示查询在索引树中就可以查找到所需数据, 不用扫描表数据文件, 往往说明性能不错.

- using where, 列数据是从仅仅使用了索引中的信息而没有读取实际实际的表返回的, 这发生在对表全部请求列都是同一
个索引部分的时候.

- impossible where, 该值强调 where 语句条件总是 false, 表里没有满足条件的记录

- impossible where noticed after reading cosnt tables: 优化器评估了const表之后,发现where条件均
不满足.

- select tables optimized away, 该值意味着仅通过使用索引, 优化器可能仅从聚合函数结果中返回一行.


