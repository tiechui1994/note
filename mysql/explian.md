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

- DERIVED, 表示派生 SELECT(在FROM子句中的子查询)

- MATERIALIZED, 表示物化子查询

- UNCACHEABLE SUBQUERY, 表示子查询结果无法缓存, 必须针对外部查询的每一行重新进行评估.

- UNCACHEABLE UNION, 表示在UNION中属于不可缓存子查询的第二个或更后面的查询.

> DEPENDENT 通常表示使用相关子查询.
>
> `DEPENDENT SUBQUERY` 评估与评估不同 `UNCACHEABLE SUBQUERY`. 因为 `DEPENDENT SUBQUERY` 子查询对于外部上下
文中的每一组不同的变量值只重新计算一次. 对于 `UNCACHEABLE SUBQUERY` 外部上下文的每一行, 子查询都会被重新评估.
>
> 子查询的可缓存性不同于查询缓存中查询结果的缓存


### type

[文档](https://mengkang.net/1124.html)

[文档](https://www.cnblogs.com/zhanjindong/p/3439042.html)

它提供了判断查询是否高效的重要依据. 通过 type 字段, 可以判断此次查询是 `全表扫描` 还是 `索引扫描`等.

type 常有的取值:

#### system

> The table has only one row (= system table). This is a special case of the const 
> join type.

表中只有一条数据. 这个类型是特殊的 const 类型

#### const

> The table has at most one matching row, which is read at the start of the query. 
> Because there is only one row, values from the column in this row can be regarded 
> as constants by the rest of the optimizer. const tables are very fast because they
> are read only once.
 

针对`主键`或`唯一索引`的值查询扫描, 最多只返回一行数据. const 查询速度非常快, 因为它仅仅只读取一次.

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


#### eq_ref 

> One row is read from this table for each combination of rows from the previous tables.
> Other than the system and const types, this is the best possible join type. It is 
> used when all parts of an index are used by the join and the index is a PRIMARY KEY
> or UNIQUE NOT NULL index.

只匹配到一行的时候. 除了 `system` 和 `const` 之外, 这是最好的 join 类型了. 当使用 `主键索引` 或 `
唯一索引` 的时候, 且这个索引的所有组成部分都被用上, 才能是该类型.

> eq_ref can be used for indexed columns that are compared using the = operator. The 
> comparison value can be a constant or an expression that uses columns from tables 
> that are read before this table. In the following examples, MySQL can use an eq_ref 
> join to process ref_table

对已经建立索引列进行 `=` 操作的时候, `eq_ref` 会被使用到. 比较值可以使用一个常量也可以是一个表达式. 
这个表达式可以是其他的表的行

```
# 多表关联查询, 单行匹配

EXPLAIN SELECT * FROM ref_table, other_table 
    WHERE ref_table.key_column=other_table.column;

# 多表关联查询, 联合索引, 多行匹配

EXPLAIN SELECT * FROM ref_table, other_table
    WHERE ref_table.key_column_part1=other_table.column
      AND ref_table.key_column_part2=1;
```

#### ref

此类型通常出现在多表的 join 查询, 针对于 `非唯一索引` 或 `非主键索引`,或者是使用了 `最左前缀` 规则索引的
查询.

#### range
 
表示使用索引范围查询, 通过索引字段范围获取表中部分数据记录. 这个类型通常出现在 `=`, `<>`, `>=`, `<`, `<=`,
`<=>`, `BETWEEN`, `IN` 操作中.

当 type 是 `range` 时, 那么 EXPLAIN 输出 ref 字段为 NULL, 并且 key_len 字段是此次查询中使用到的索引
的最长那个.

#### index

表示全索引扫描(full index scan), 和 ALL 类型类似, 只不过 ALL 类型是全表扫描, 而 index 类型则仅仅扫描
所有的索引, 而不是扫描数据.

index 类型通常出现在: 所要查询的数据直接在索引树中就可以获取到, 而不需要扫描数据. 当这种状况下, extra 字段
会显示 `using index`

#### all

全表扫描



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


