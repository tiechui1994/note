# EXPLAIN

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

- SIMPLE, 表示此查询不包含 UNION 查询或子查询

- PRIMARY, 表示此查询是 UNION 的第一个查询

- UNION, 表示此查询是 UNION 的第二个查询

- DEPENDENT UNION, UNION 中的第二个或后面的查询语句, 取决于外面的查询

- UNION RESULT, UNION 的结果

- SUBQUERY, 子查询中的第一个 SELECT 

- DEPENDENT SUBQUERY, 子查询中的第一个 SELECT, 取决于外面的查询, 即子查询依赖外层查询的结果


### type

它提供了判断查询是否高效的重要依据. 通过 type 字段, 可以判断此次查询是 `全表扫描` 还是 `索引扫描`等.

type 常有的取值:

- system: 表中只有一条数据. 这个类型是特殊的 const 类型

- const: 针对`主键`或`唯一索引`的等值查询扫描, 最多只返回一行数据. const 查询速度非常快, 因为它仅仅
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


- eq_ref: 此类型通常出现在多表的 join 查询, 表示对于当前表的每一个结果, 都只能匹配到后表的一行结果. 并且
查询的比较操作通常是 `=`, 查询效率较高.

```
mysql root@localhost:test> explain select * from user_info join order_info on user_info.id=order_info.user_id \G;
***************************[ 1. row ]***************************
id            | 1
select_type   | SIMPLE
table         | order_info
partitions    | <null>
type          | index
possible_keys | user_product_detail_index
key           | user_product_detail_index
key_len       | 254
ref           | <null>
rows          | 9
filtered      | 100.0
Extra         | Using where; Using index
***************************[ 2. row ]***************************
id            | 1
select_type   | SIMPLE
table         | user_info
partitions    | <null>
type          | eq_ref
possible_keys | PRIMARY
key           | PRIMARY
key_len       | 8
ref           | test.order_info.user_id
rows          | 1
filtered      | 100.0
Extra         | <null>
```

- ref: 此类型通常出现在多表的 join 查询, 针对于 `非唯一索引` 或 `非主键索引`,或者是使用了 `最左前缀` 规
则索引的查询.

- range: 表示使用索引范围查询, 通过索引字段范围获取表中部分数据记录. 这个类型通常出现在 `=`, `<>`, `>=`
`<`, `<=`, `<=>`, `BETWEEN`, `IN` 操作中.

当 type 是 `range` 时, 那么 EXPLAIN 输出 ref 字段为 NULL, 并且 key_len 字段是此次查询中使用到的索引
的最长那个.

- index: 表示全索引扫描(full index scan), 和 ALL 类型类似, 只不过 ALL 类型是全表扫描, 而 index 类型
则仅仅扫描所有的索引, 而不是扫描数据.

index 类型通常出现在: 所要查询的数据直接在索引树中就可以获取到, 而不需要扫描数据. 当这种状况下, extra 字段
会显示 `using index`

- all: 全表扫描

#### type 性能比较

all < index < range < ref < eq_ref < const < system

all 类型是全表扫描. 查询速度最慢.


### extra

extra 字段表示额外信息

- using filesort, 当 extra 中有 `using filesort` 时, 表示 MySQL 需额外的排序操作. 不能通过索引达到
排序效果. 一般有 `using filesort`, 都建议优化去掉.

- using index, 覆盖索引扫描, 表示查询在索引树中就可以查找到所需数据, 不用扫描表数据文件, 往往说明性能不错.

- using temporary, 查询使用临时表, 一般出现于排序, 分组和多表join 的情况, 查询效率不高, 建议优化.



