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

[文档](https://mengkang.net/1124.html)

[文档](https://www.cnblogs.com/zhanjindong/p/3439042.html)

它提供了判断查询是否高效的重要依据. 通过 type 字段, 可以判断此次查询是 `全表扫描` 还是 `索引扫描`等.

type 的值:

- system

该表只有一行(=系统表). 这个类型是 const 类型的特例.

- const

该表至多有一个匹配的行, 在查询开始时读取. 由于只有一行, 因此该行中列的值可以被优化器的其余部分视为常亮. const 表非常快,
因为它们只读一次.

针对`主键`或 `唯一索引`的值查询扫描, 最多只返回一行数据. const 查询速度非常快, 因为它仅仅只读取一次.

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

这种连接类型与 ref 类似, 但是另外 MySQL 对包含 NULL 值的行进行额外的搜索. 这种连接类型优化最常用于解析子查询.

```
SELECT * FROM ref_table
    WHERE key_column=expr OR key_column IS NULL;
```

- index_merge

此 join 类型表示使用索引合并优化. 在这种情况下, key 输出行中的列包含使用索引列表, 且 key_len 包含所用索引的最长关键
部分列表. 

- unique_subquery

这种类型取代了以下形式的 eq_ref 一些 IN 子查询:

```
value IN (SELECT primary_key FROM sigle_table WHERE som_expr)
```

unique_subquery 只是一个索引查找函数, 可以完全替代子查询以提高效率.

- index_subquery

这种连接类型与 unique_subquery. 它取代了 IN 子查询, 但它适合于以下形式的子查询中的非唯一索引:

```
value IN (SELECT key_column FROM sigle_table WHERE some_expr)
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



#### type 性能比较

all < index < range < ref < eq_ref < const < system

all 类型是全表扫描. 查询速度最慢.


### extra

extra 字段表示额外信息

- using filesort, 当 extra 中有 `using filesort` 时, 表示 MySQL 需额外的排序操作. 不能通过索引达到
排序效果. 一般有 `using filesort`, 都建议优化去掉.

- using index, 覆盖索引扫描, 表示查询在索引树中就可以查找到所需数据, 不用扫描表数据文件, 往往说明性能不错.

- using temporary, 查询使用临时表, 一般出现于排序, 分组和多表join 的情况, 查询效率不高, 建议优化.

- using where, 列数据是从仅仅使用了索引中的信息而没有读取实际实际的表返回的, 这发生在对表全部请求列都是同一
个索引部分的时候.

- using join buffer, 该值强调join条件时没有使用索引, 并且需要 join buffer 来存储中间结果. 如果出现了
这个值, 那么应该注意, 根据查询的具体情况可能需要添加索引来改进性能.

- impossible where, 该值强调 where 语句条件总是 false, 表里没有满足条件的记录

- impossible where noticed after reading cosnt tables: 优化器评估了const表之后,发现where条件均
不满足.

- select tables optimized away, 该值意味着仅通过使用索引, 优化器可能仅从聚合函数结果中返回一行.


