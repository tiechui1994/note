- 共享锁

> 又称之为 读锁，简称 S 锁，顾名思义,共享锁就是**多个事务对于同一数据**可以共享一把锁, 都能访问到数据库, 但是只能读不
能修改;


加锁方式:
select * from users where id = 1 lock in share mode;

释放方式:
rollback/commit;


测试

事务t1:(先)
```
begin;
select * from t lock in share mode; // 1
```

事务t2:(后)
```
begin;
update t set name='ww' where id=1; // 2
```

注意: 1 和 2 不能同时执行, 必须要有一方commit/rollback, 另一方才能继续执行.

共享锁不影响其他事务的读取操作, 但是会影响更改操作(删除,更新,添加)


- 排他锁

> 又称为 写锁，简称 X 锁, 排它锁不能与其他锁并存, 如一个事务获取了一个数据行的排它锁, 其他事务就不能再获取改行的锁 (包
括共享锁和排它锁), 只有当前获取了排它锁的事务可以对数据进行读取和修改(此时其他事务要读取数据可从快照获取).

加锁方式:
delete  update  insert 默认加排他锁
select * from users where id = 1 for update;

释放方式:
rollback/commit;


测试

事务t1:(先)
```
begin;
select * from t for update; // 1
```

事务t2:(后)
```
begin;
update t set name='ww' where id=1; // 2
select * from t lock in share mode; // 3
```

注意: 1与2, 或者 1与3 不能同时执行. 


- 行锁

InnoDB的行锁是通过索引上的索引项加锁实现的, 只有通过索引条件进行数据检索, InnoDB才使用行锁. 否则, 将使用表锁(锁住
索引的所有记录). 条件指定为特定的一行.


测试:

事务t1:(先)
```
start;
update t set name='www' where id=1; // 1
```

事务t2:(后)
```
start;
update t set name='qqq' where id=1; // 2
update t set name='zzz' where id=2; // 3
```

注意: 1 和2 不能同时执行, 因为在操作1的时候,已经添加了行锁, 那么2将无法执行,除非 1 commit/rollback. 但是
1 和 3 可以同时执行, 属于不同的行, 是不同的行锁.


**行锁的算法**

- 临键锁 Next-Key locks
  当sql执行按照索引进行数据的检索时, 查询条件为范围查找(between and < > 等等)并有数据命中, 则测试SQL语句加上的
  锁为Next-Key locks, 锁住索引的记录区间加下一个记录区间, 这个区间是`左开右闭的`

- 间隙锁 Gap:
  当记录不存在时, 临键锁退化成Gap. 在上述检索条件下, 如果没有命中记录,则退化成Gap锁, 锁住数据不存在的区间(`左开右开`)

- 记录锁 Record Lock:
  唯一性索引条件为精准匹配, 退化成Record锁. 当SQL执行按照唯一性(Primary Key, Unique Key) 索引进行数据的检索时,
  查询条件等值匹配且查询的数据存在, 这是SQL语句上加的锁即为记录锁Record locks, 锁住具体的索引项.

关系: next-key = gap + record

测试:

已经存在的数据
```
+----+---------+-----+
| id | account | i   |
+----+---------+-----+
| 1  | 333     | 1   |
| 4  | 2000    | 2   |
| 7  | 122     | 12  |
| 9  | 11      | 110 |
+----+---------+-----+
```
在上述状况下, InnoDB默认的行锁算法(Next-Key Lock), 此时的区间是 (-oo, 1] (1, 4] (4,7] (7,10], (10,+oo)


```
begin;
select * from t where id>5 and id<9 for update;
```

锁定的区间: (4,7] 和 (7,10]

验证next-key

左开:
```
select * from t where id=4 for update; // 验证左开, 可以正常执行. id=4的记录没有被锁住.
```

右闭:
```
select * from t where id=7 for update; // 验证右闭, 不能执行. id=7的记录被锁住
```

下一区间:  
```
insert into t (id,account,i) values(9,100,100); // 插入id=9, 不能执行, 说明命中区间[7,10) 的下一区间记录被
锁定
```

验证gap:

```
begin;
select * from t where id>4 and id<6 for update; // 1
select * from t where id=6 for update; // 2
```

1或者2产生锁住的区间 (4,7)

左开:
```
select * from t where id=4 for update; // 可以执行
```

右开:
```
select * from t where id=7 for update; // 可以执行
```

下一区间:  
```
insert into t (id,account,i) values(5,1,1); // 插入id=5, 不能执行, 说明命中区间(4,7) 的下一区间记录被
锁定
```

验证record

```
begin;
select * from t where id=4 for update; 
```

下一区间:  
```
insert into t (id,account,i) values(5,1,1); // 可以执行, 没有被锁定
锁定
```

- 自增锁

针对自增列自增长的一个特殊的表级别锁.

测试:

```
begin;
insert into t (name) values('aaa');
rollback;
```

执行3次之后, 发现新增加的主键是上一条记录加3. 原因是, 3次插入导致自增主键增加, 但是由于事务未提交, 所以, 自增的主键
永久性丢失.


结论:

加 X 锁 避免了数据的脏读
加 S 锁 避免了数据的不可重复读
加上 Next Key 避免了数据的幻读