## 变量

事务隔离级别

当前会话事务隔离级别:
```
select @@tx_isolation;
```

当前系统事务隔离级别:
```
select @@global.tx_isolation;
```

设置当前会话事务隔离级别:
```
set session transaction isolation level read uncommitted;
```

设置系统事务隔离级别:
```
set global transaction isolation level repeatable read;
```