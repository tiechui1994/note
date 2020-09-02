## explain

explain 可用于分析 SQL 的执行计划. 格式如下:

```
{EXPLIAN | DESCRIBE | DESC }
    tb_name [col_name | wild]

{EXPLIAN | DESCRIBE | DESC }
    [ explain_type ]
    { explainable_stmt | FOR CONNECTION connection_id }

{EXPLIAN | DESCRIBE | DESC } ANALYZE select_statement

explain_type: {
    FORMAT = {TRADITIONAL | JSON | TREE }
}

explainable_stmt: {
      SELECT statement 
    | TABLE statement
    | DELETE statement
    | INSERT statement
    | REPLACE statement
    | UPDATE statement
}
```

各个列的含义:

| 字段 | 含义 |
| --- | --- |
| id | SELECT 查询的标识符. 每个SELECT都会自动分配一个唯一的标识符. |
| select_type | SELECT查询的类型 |
| table | 查询涉及到的表或衍生表 |
| partions | 匹配分区表的分区 |
| **type** | 判断此次查询是 `全表扫描` 还是 `索引扫描` 等 |
| **possible_keys** | 此次查询中可能选用的索引 |
| **key** | 此次查询中确切使用到的索引 |
| **key_len** | 索引长度 |
| ref | 哪个字段或常数与key一起被使用 |
| **rows** | 显示此次查询一共扫描了多少行. 这是一个估计值 |
| **filtered** | 此查询条件所过滤的数据的百分比 |
| **extra** | 额外的数据. |

### select_type 

取值包括:

- `SIMPLE`, 简单查询 (**未使用UNION或子查询**)

- `PRIMARY`, `UNION` 的第一个查询

- `UNION`, 在 `UNION` 中的第二个和随后的 `SELECT` 被标记为 `UNION`. 如果 `UNION` 被 `FROM` 子句中的子查询包含,
那么它的第一个 `SELECT` 会被标记为 `DERIVED`.

```
> desc select * from paymentinfo where id=3 union select * from paymentinfo where id=1;
+--------+---------------+-------------+--------------+--------+-----------------+---------+-----------+--------+--------+------------+--------------------------------+
|     id | select_type   | table       |   partitions | type   | possible_keys   | key     |   key_len | ref    |   rows |   filtered | Extra                          |
|--------+---------------+-------------+--------------+--------+-----------------+---------+-----------+--------+--------+------------+--------------------------------|
|      1 | PRIMARY       | <null>      |       <null> | <null> | <null>          | <null>  |    <null> | <null> | <null> |     <null> | no matching row in const table |
|      2 | UNION         | paymentinfo |       <null> | const  | PRIMARY         | PRIMARY |         4 | const  |      1 |        100 | <null>                         |
| <null> | UNION RESULT  | <union1,2>  |       <null> | ALL    | <null>          | <null>  |    <null> | <null> | <null> |     <null> | Using temporary                |
+--------+---------------+-------------+--------------+--------+-----------------+---------+-----------+--------+--------+------------+--------------------------------+
```

> FROM 子句当中包含 UNION

```
> desc select * from (select userid from paymentinfo where id=3 union select userid from paymentinfo where id=1) as a;
+--------+---------------+-------------+--------------+--------+-----------------+---------+-----------+--------+--------+------------+--------------------------------+
|     id | select_type   | table       |   partitions | type   | possible_keys   | key     |   key_len | ref    |   rows |   filtered | Extra                          |
|--------+---------------+-------------+--------------+--------+-----------------+---------+-----------+--------+--------+------------+--------------------------------|
|      1 | PRIMARY       | <derived2>  |       <null> | ALL    | <null>          | <null>  |    <null> | <null> |      2 |        100 | <null>                         |
|      2 | DERIVED       | <null>      |       <null> | <null> | <null>          | <null>  |    <null> | <null> | <null> |     <null> | no matching row in const table |
|      3 | UNION         | paymentinfo |       <null> | const  | PRIMARY         | PRIMARY |         4 | const  |      1 |        100 | <null>                         |
| <null> | UNION RESULT  | <union2,3>  |       <null> | ALL    | <null>          | <null>  |    <null> | <null> | <null> |     <null> | Using temporary                |
+--------+---------------+-------------+--------------+--------+-----------------+---------+-----------+--------+--------+------------+--------------------------------+
```

- `DEPENDENT UNION`, `UNION` 中的第二个或后面的查询, 依赖了外面的查询

- `UNION RESULT`, `UNION` 的结果集合

- `SUBQUERY`, 子查询中的第一个 `SELECT`

- `DEPENDENT SUBQUERY`, 子查询中的第一个 `SELECT` 依赖了外面的查询

- `DERIVED`, 用来表示包含在 `FROM` 子句中的子查询中 `SELECT`, MySQL 会递归执行并将结果放入到一个临时表中. MySQL
内部将其称为 Derived table (派生表), 因为该临时表是从子查询派生的

- `DEPENDENT DERIVED`, 派生表, 依赖了其他的表

- `MATERIALIZED`, 物化子查询

- `UNCHANGEBLE SUBQUERY`, 子查询, 结果无法缓存, 必须针对外部查询的每一行重新评估

- `UNCHANGEBLE UNION`, `UNION` 属于 `UNCHANGEBLE UNION` 的第二个或后面的查询.