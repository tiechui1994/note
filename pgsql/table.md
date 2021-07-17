# postgre 操作

## postgre 主键自增

在 postgre 当中, 主键约束只是唯一约束和非空约束的组合.

```sql
CREATE TABLE t(
  id integer UNIQUE NOT NULL,
  name text
);
```

```sql
CREATE TABLE t(
  id integer PRIMARY KEY,
  name text
);
```

在 postgre 当中, 上述的两张表是等价的.

主键表示一个或多个字段的组合可以用于唯一标识表中的数据行. 这是定义一个主键的直接结果. 

> 注意: 一个唯一约束(unique constraint)实际上并不能提供一个唯一标识, 因为它不排除NULL

一个表最多可以有一个主键(但是它可以有多个唯一和非空约束). 关系型数据库理论告诉我们, 每个表必须有一个主键, Postgre
并不强制这个规则.

**在 SQLite 中, 主键是自动增长的. 在 MySQL 中, 需要添加一个 auto_increment 标识.**

**在 Postgre 中, 有专门的类型 `SERIAL` 来表示自动增加.**


```sql
CREATE SEQUENCE t_id_seq
START WITH 1
INCREMENT BY 1
NO MAXVALUE
NO MINVALUE
CACHE 1;

CREATE TABLE t (
  id integer DEFAULT nextval('t_id_seq') PRIMARY KEY,
  ...
);
```

```sql
CREATE TABLE t (
  id SERIAL PRIMARY KEY,
  ...
);
```

上述的两种方式的语法是等价的, 为每一行生成一个"序列号"(serial number)

## DB导出为CSV格式

- 导出csv, 必须使用`SUPERUSER`权限的用户
```sql
COPY(select * from torder_stus) to '/tmp/tank.csv' with csv header;
```

- 导入csv
```sql
COPY torder_stus from '/tmp/tank.csv' with csv header;
```