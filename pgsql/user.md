## pgsql 用户授权

- 先切换到 Linux 用户 `postgres`, 并执行 psql:

```
$su - postgres

$ psql

postgres=#
```

目前为止, 已经进入数据库当中.

- 创建数据库新用户, 如 admin:

```sql
postgres=# CREATE USER admin WITH PASSWORD '*****';
```

注意: 语句要以分号结尾, 密码要用单引号括起来.

- 创建用户数据库, 如exampledb:

```sql
postgres=# CREATE DATABASE exampledb OWNER admin;
```

- 将 exampledb 数据库的所有权限都赋予 admin: 

```sql
postgres=# GRANT ALL PRIVILEGES ON DATABASE exampledb TO admin;
```

- 授予admin用户super权限
```sql
ALTER ROLE admin WITH SUPERUSER;
```

- 使用命令 `\q` 退出psql:

```
postgres=# \q
```

## pgsql 常用命令

- 查看数据库: `\list`

- 数据库切换: `\connect db`

- 查看数据库表: `\d` 

- 查看数据库表结构: `\d table`

- 查看数据库索引: `\di`

- 查看当前连接信息: `\conninfo`
