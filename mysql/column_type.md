# MySQL 列的类型解析

## MySQL列的信息包括以下内容:

- Field: 列的名字

- Type: 列的数据类型

- Collation: 非二进制字符串列的排序规则. 其他类型的列的值是NULL

- Null: 列的值是否可以为NULL, 如果NULL值可以存储在列中, 则值为YES, 否则为NO.

- Key: 索引

```
- 如果Key为空, 则列没有索引

- 如果Key是PRI, 则该列是 PRIMARY KEY 或者多列 PROMARY KEY中的列之一

- 如果Key是UNI, 则该列是 UNIQUE 索引的第一列. (UINQUE索引允许多个NULL值, 通过检查 Null 字段判断该
列是否允许 NULL)

- 如果Key是MUL, 则该列是非唯一索引的第一列, 其中在列中允许多次出现给定值.

如果多个Key值应用于表的给定列, 则Key按PRI, UNI, MUL的顺序显示最高优先级的值.

如果 UNIQUE 索引不能包含 NULL 值并且表中没有 PRIMARY KEY, 则它可能显示为PRI.
如果多个列形成复合 UNIQUE 索引, 则 UNIQUE 索引可以显示为MUL; 虽然列的组合是唯一的, 但每列仍然可以保存
给定值的多次出现.
```

- Default: 列的默认值. 如果列具有显示缺省值 NULL, 或者列定义不包含DEFAULT子句, 则此值是NULL

- Extra: 列的其他可用信息. 在以下的情况中, 该值是非空的:

```
- auto_increment 用于具有 AUTO_INCREMENT 属性的列

- on update CURRENT_TIMESTAMP 用于具有 ON UPDATE CURRENT_TIMESTAMP 属性的 TIMESTAMP 或 
DATETIME 列

- VIRTUAL GENERATED 或 VIRTUAL STORED 是生成列.
```

- Privileges: 列的权限


**案例**:

```
show full columns from sys_config;                                                                              
+----------+--------------+-----------------+------+-----+-------------------+-----------------------------+---------------------------------+---------+
| Field    | Type         | Collation       | Null | Key | Default           | Extra                       | Privileges                      | Comment |
+----------+--------------+-----------------+------+-----+-------------------+-----------------------------+---------------------------------+---------+
| variable | varchar(128) | utf8_general_ci | NO   | PRI | <null>            |                             | select,insert,update,references |         |
| value    | varchar(128) | utf8_general_ci | YES  |     | <null>            |                             | select,insert,update,references |         |
| set_time | timestamp    | <null>          | NO   |     | CURRENT_TIMESTAMP | on update CURRENT_TIMESTAMP | select,insert,update,references |         |
| set_by   | varchar(128) | utf8_general_ci | YES  |     | <null>            |                             | select,insert,update,references |         |
+----------+--------------+-----------------+------+-----+-------------------+-----------------------------+---------------------------------+---------+
```

## MySQL 信息查看命令

- 查看创建TABLE语句

```sql
SHOW CREATE TABLE t1;
```

- 查看TABLE的索引信息

```sql
SHOW INDEX FROM t1;
```

- 查看TABLE的列的信息

```sql
SHOW [FULL] COLUMNS FROM t1;

DESC t1;
```

- 查看数据库TABLE的状态

```sql
SHOW TABLE STATUS;
```

