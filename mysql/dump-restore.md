# MySQL 备份与恢复

## mysqldump备份, mysql,source恢复

使用mysqldump可以将数据备份sql文件. 

使用mysql或者source去执行备份的sql文件从而恢复数据.

### mysqldump备份命令

mysqldump客户端是一个最初由Igor Romanenko编写的备份程序. 它可用于转储数据库或数据库集合以进行备份或传输到另一个SQL服
务器(不一定是MySQL服务器). 转储通常包含用于创建表, 填充表或两者的SQL语句. 但是, mysqldump也可用于生成CSV, 分隔文本或
XML格式的文件.

如果在服务器上进行备份并且表都是MyISAM表, 可以考虑使用mysqlhotcopy, 因为它可以实现更快的备份和更快的恢复.

格式:
```
mysqldump [options] [db_name [table_name ...]]
mysqldump [options] --database db_name ...
mysqldump [options] --all-databases
```

默认情况下, mysqldump不会转储INFORMATION_SCHEMA或performance_schema数据库. 要转储它们, 需要在命令行中显式命名它
们, 而且还必须使用--skip-lock-tables选项.

mysqldump是逐行检索和转储表内容, 或者它可以从表中检索整个内容并在转储之前将其缓冲在内存中. 如果要转储大型表, 则在内存中
缓冲可能会出现问题. 要逐行转储表, 请使用--quick选项(或--opt, 它会启用--quick). 默认情况下启用--opt选项(包含了--quick), 
因此要启用内存缓冲, 请使用--skip-quick. 

如果使用最新版本的mysqldump生成要重新加载到非常旧的MySQL服务器的dump, 则不应使用--opt或--extended-insert选项. 改
用--skip-opt.

mysqldump支持下面的选项, 可以在命令行或\[mysqldump]和\[client]配置文件节中指定. mysqldump还支持处理选项文件的选项.

- --add-drop-database
在每个CREATE DATABASE语句之前添加DROP DATABASE语句. 此选项通常与--all-databases或--databases选项一起使用, 因为
除非指定了其中一个选项, 否则不会写入CREATE DATABASE语句.

- --add-drop-table
在每个CREATE TABLE语句之前添加DROP TABLE语句

- --add-drop-trigger
在每个CREATE TRIGGER语句之前添加DROP TRIGGER语句

- --add-locks
使用LOCK TABLES和UNLOCK TABLES语句环绕每个表转储. 重新加载转储文件时, 这会导致更快的插入.

- --all-databases, -A
转储所有数据库中的所有表. 这与使用--databases选项数作用相同.

- --databases, -B db
转储指定的数据库

- --comments, -i
在转储文件中写入其他信息, 例如程序版本, 服务器版本和主机. 默认情况下启用此选项. 要禁止显示此附加信息, 请使用
--skip-comments.

- --compact
产生更紧凑的输出. 此选项启用--skip-add-drop-table, --skip-add-locks, --skip-comments, --skip-disable-keys
和--skip-set-charset选项.


- --compatible=name
生成与其他数据库系统或旧MySQL服务器更兼容的输出. name的值可以是ansi, mysql323, mysql40, postgresql, oracle, 
mssql, db2, maxdb, no_key_options, no_table_options或no_field_options. 要使用多个值, 请用逗号分隔. 这些值
与用于设置服务器SQL模式的相应选项具有相同的含义.

此选项不保证与其他服务器的兼容性. 它仅启用当前可用于使转储输出更兼容的那些SQL模式值. 例如, --compatible=oracle不会将
数据类型映射到Oracle类型或使用Oracle注释语法.

- --compress, -C
如果两者都支持压缩, 则压缩客户端和服务器之间发送的所有信息.

- --extended-insert, -e
使用包含多个VALUES列表的多行INSERT语法. 这会导致较小的转储文件, 并在重新加载文件时加快插入速度.

- --force, -f

- --ignore-table=db_name.tb_name
需要忽略的表, 可以多次使用.

- --insert-ignore
使用INSERT IGNORE语句代替INSERT

- --no-data, -n
不要写任何表行信息(即不要转储表内容). 如果要仅转储表的CREATE TABLE语句(例如,通过加载转储文件来创建表的空副本), 这将非
常有用.

- --where='where_condition', -w 'where_condition'
仅转储由给定WHERE条件选择的行. 如果条件包含空格或其他对命令解释程序特殊的字符, 则必须引用该条件.
例如: --where="user='jimf'"
     -w"userid>1"
     -w"userid<1"
     
- --xml, -X
转储为xml格式


# MySQL导入导出excel

## 导出excel

- sql语句, (MySQL Server动需要带设置--secure-file-priv=/path/to/dir/, 或者修改my.cnf在 `[mysqld]` 内加入
secure_file_priv=/path/to/dir/)
```sql
SELECT * INTO outfile '/tmp/xxx.xlsx' FROM t_table WHERE xx;
```

- shell语句
```bash
mysql DATABASE -u USER [-h IP] -p -e "SELECT * FROM t_table WHERE xxx" > /tmp/xxx.xlsx
```

## 导入excel

- sql语句

```sql
LOAD DATA LOCAL infile '/tmp/xxx.xlsx' INTO TABLE t_table FIELDS TERMINATED BY "\t" LINES TERMINATED BY "\n";
```

> note: 此语句可以通过 mysql 或者 mysql 连接的 shell 执行. 对于使用 mycli 连接的 shell 无法执行此类原生 SQL.

可能出现的问题: `(1148, 'The used command is not allowed with this MySQL version')`

解决方法:

方法1: 确保MySQL Server的local_infile是开启的.
```sql
SHOW GLOBAL VARIABLES LIKE '%local_infile';
```

方法2: 确保MySQL Client的连接的local_infile是开启的.

```bash
mysql -u root --local-file -p
```

或者在my.cnf当中添加如下选项.
```
[client]
loose-local-infile=1
```