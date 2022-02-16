## MySQL命令 - SHOW

### show 常用命令

1. `show databases`; -- 显示mysql中所有数据库的名称. 
2. `show tables` 或 `show tables from database_name`; -- 显示当前数据库中所有表的名称.

3. `show columns from database_name.table_name;` -- 显示表中列名称. 
4. `show index from table_name`; -- 显示表的索引. 

5. `show create database database_name;` -- 显示create database 语句是否能够创建指定的数据库. 
6. `show create table table_name;` -- 显示create database 语句是否能够创建指定的数据库. 

7. `show grants for user_name;` -- 显示一个用户的权限,显示结果类似于grant 命令. 

8. `show table status;` -- 显示当前使用或者指定的database中的每个表的信息.信息包括表类型和表的最新更新时间. 
9. `show innodb status;` -- 显示innoDB存储引擎的状态. 

10. `show status;` -- 显示一些系统特定资源的信息,例如,正在运行的线程数量. 
11. `show variables;` -- 显示系统变量的名称和值. 
12. `show processlist;` -- 显示系统中正在运行的所有进程,也就是当前正在执行的查询.大多数用户可以查看他们自己的进程,但是如果他们拥有process权限,就可以查看所有人的进程,包括密码. 
13. `show privileges;` -- 显示服务器所支持的不同权限. 
14. `show engines;` -- 显示安装以后可用的存储引擎和默认引擎. 
15. `show logs;` -- 显示BDB存储引擎的日志. 
16. `show warnings;` -- 显示最后一个执行的语句所产生的错误、警告和通知. 
17. `show errors;` -- 只显示最后一个执行语句所产生的错误.

### 设置配置参数

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