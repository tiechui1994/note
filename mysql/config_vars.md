# mysql 参数解析

## sql_mode

默认值域:

```
ONLY_FULL_GROUP_BY,
STRICT_TRANS_TABLES,
NO_ZERO_IN_DATE,
NO_ZERO_DATE,
ERROR_FOR_DIVISION_BY_ZERO,
NO_AUTO_CREATE_USER,
NO_ENGINE_SUBSTITUTION
```

- ONLY_FULL_GROUP_BY
```
ONLY_FULL_GROUP_BY的语义就是确定select target list中的所有列的值都是明确语义, 简单的说来,
在ONLY_FULL_GROUP_BY模式下, target list中的值要么是来自于聚集函数的结果, 要么是来自于group by list中的表达式的值.

因为有ONLY_FULL_GROUP_BY, 所以要在MySQL中正确的使用group by语句的话, 只能是select column1 from tb1 group by column1
(即只能查询group by的字段,其他均都要报1055的错)

MySQL允许target list中对于非聚集函数的alias column被group by, having以及order by语句引用.

注: 从MySQL 5.7.5开始, 默认的SQL模式包括ONLY_FULL_GROUP_BY
```

- NO_ZERO_DATE
```
NO_ZERO_DATE模式影响 mysql 是否允许 '0000-00-00' 作为有效日期. 其效果还取决于是否启用了严格的SQL模式.
    1.如果未启用此模式，则允许使用'0000-00-00'并且插入不会产生警告.
    2.如果启用此模式，则允许使用'0000-00-00'并且插入会产生警告.
    3.如果启用此模式和严格模式, 则不允许使用'0000-00-00'并且插入会产生错误,除非同时给出IGNORE. 
    对于 INSERT IGNORE 和 UPDATE IGNORE, 允许使用'0000-00-00'并且插入产生警告.

错误: Error 1292: Incorrect date|datetime|time value
```

- NO_ZERO_IN_DATE
```
NO_ZERO_IN_DATE模式会影响mysql是否允许 "年份为不为0但月份或日期为0的日期". (此模式会影响日期类型,
例如 "2010-00-01" 或 "2010-01-00", 但不会要控制 mysql 是否允许'0000-00-00', 请使用NO_ZERO_DATE模式.)
NO_ZERO_IN_DATE的效果还取决于是否启用了严格的SQL模式.
    1. 如果未启用此模式, 则允许 "月份或日期为0"的日期, 并且插入不会产生警告。
    2. 如果启用此模式，则 "月份或日期为0" 的日期 将作为 "0000-00-00" 插入并生成警告。
    3. 如果启用此模式和严格模式, 则不允许 "月份或日期为0" 的日期, 并且插入会产生错误. 除非同时给出IGNORE.
    对于 INSERT IGNORE 和 UPDATE IGNORE, "月份或日期为0" 的日期将作为 '0000-00-00' 插入并产生警告。

注: NO_ZERO_IN_DATE已弃用. NO_ZERO_IN_DATE不是严格模式的一部分, 但应与严格模式一起使用, 默认情况下启用.
如果启用NO_ZERO_IN_DATE而未启用严格模式, 则会发出警告,反之亦然.

错误: Error 1292: Incorrect date|datetime value
```

- STRICT_TRANS_TABLES
```
只对支持事务的表启用严格模式.
    1. 对于事务性存储引擎, 在语句中任何地方出现的不良数据值(包括类型不符合, 数据值越界,等)均会导致语句终止,
    并执行回滚操作.
    2. 对于非事务性存储引擎, 如果错误出现在插入或更新的第一行, 将终止该语句. 首行之后出现的错误不会导致该语
    句终止, 取而代之的是, 将调整不良数据值, 并且给出警告, 而不是错误. 
```

- STRICT_ALL_TABLES
```
对所有引擎的表都启用严格模式.
    1. 对于事务性存储引擎, 在语句中任何地方出现的不良数据值(包括类型不符合, 数据值越界,等)均会导致放弃语句,
    并执行回滚操作.
    2. 对于非事务性存储引擎, 在语句中任何地方出现的不良数据值, 在该行数据之前的插入或者更新操作执行, 而该行(
    包括该行)之后的插入或者更新操作终止.
```

- ERROR_FOR_DIVISION_BY_ZERO 
```
ERROR_FOR_DIVISION_BY_ZERO模式影响除零的处理, 包括MOD(N, 0). 对于数据更改操作(INSERT, UPDATE), 其效
果还取决于是否启用了严格的SQL模式.
    1. 如果未启用此模式, 则除以零将插入NULL并且不会生成警告.
    2. 如果启用此模式, 则除以零将插入NULL并生成警告.
    3. 如果启用此模式 和 严格SQL模式, 除非同时给出IGNORE, 除以零会产生错误. 对于INSERT IGNORE和UPDATE IGNORE,
    除以零插入NULL并产生警告.

注: 对于SELECT, 除以零返回NULL. 无论是否启用严格模式, 启用ERROR_FOR_DIVISION_BY_ZERO都会导致产生警告.
```

- PAD_CHAR_TO_FULL_LENGTH
```
默认情况下, 在检索时从CHAR列值中修剪尾随空格. 如果启用了PAD_CHAR_TO_FULL_LENGTH, 则不会进行修剪, 并且检
索到的CHAR值将填充到其全长. 
注: 此模式不适用于VARCHAR列, 在检索时保留尾随空格.

mysql> CREATE TABLE t1 (c1 CHAR(10));

mysql> INSERT INTO t1 (c1) VALUES('xy');

mysql> SET sql_mode = '';

mysql> SELECT c1, CHAR_LENGTH(c1) FROM t1;
+------+-----------------+
| c1   | CHAR_LENGTH(c1) |
+------+-----------------+
| xy   |               2 |
+------+-----------------+

mysql> SET sql_mode = 'PAD_CHAR_TO_FULL_LENGTH';

mysql> SELECT c1, CHAR_LENGTH(c1) FROM t1;
+------------+-----------------+
| c1         | CHAR_LENGTH(c1) |
+------------+-----------------+
| xy         |              10 |
+------------+-----------------+
```

- PIPES_AS_CONCAT
```
对待 || 作为字符串连接运算符(与CONCAT()相同) 而不是 OR 的同义词.
```

- NO_AUTO_CREATE_USER
```
当启用 NO_AUTO_CREATE_USER 模式之后, 在GRANT语句自动创建新用户帐户时, 该语句必须使用IDENTIFIED BY或使用IDENTIFIED WITH
为创建的账户指定非空密码. 否则, 语句执行失败

最好使用 CREATE USER 而不是 GRANT 创建MySQL帐户. 
默认的SQL模式包括NO_AUTO_CREATE_USER. 
在sql_mode添加NO_AUTO_CREATE_USER模式会产生警告, 但将sql_mode设置为DEFAULT的除外.
NO_AUTO_CREATE_USER将在未来的MySQL版本中被删除, 此时它的效果将始终启用(GRANT不会创建帐户).

注: ERROR 1133
```

- NO_AUTO_VALUE_ON_ZERO
```
NO_AUTO_VALUE_ON_ZERO会影响AUTO_INCREMENT列的处理. 通常, 通过在其中插入NULL或0来为列生成下一个序列号. 
NO_AUTO_VALUE_ON_ZERO将此行为限制为只能通过NULL生成下一个序列号, 0则不可以.

如果0已存储在表的AUTO_INCREMENT列中, 则此模式非常有用.(顺便说一句,存储0不是推荐的做法.) 
例如, 如果使用mysqldump转储表, 然后重新加载它, MySQL通常会在遇到0值时生成新的序列号, 从而导致新创建的表内容和
dumped的表内容不一致. 
在重新加载转储文件之前启用NO_AUTO_VALUE_ON_ZERO可以解决此问题. 因此, mysqldump 会在其输出中自动包含启用
NO_AUTO_VALUE_ON_ZERO的语句.
```

- NO_ENGINE_SUBSTITUTION
```
当CREATE TABLE 或 ALTER TABLE等语句指定禁用或未编译的存储引擎时, 控制默认存储引擎的自动替换.
默认情况下, 启用NO_ENGINE_SUBSTITUTION.

存储引擎可以在运行时插入.

    1.当禁用 NO_ENGINE_SUBSTITUTION 后, 对于 CREATE TABLE, 如果所需引擎不可用,将使用默认引擎,并且发出警告,
    创建表. 对于ALTER TABLE, 会发生警告并且不会更改表.
    2.当启用 NO_ENGINE_SUBSTITUTION 后, 如果所需的引擎不可用, 则会发生错误并且不会创建或更改表.
```

- NO_UNSIGNED_SUBTRACTION
```
整数之间做减法(其中一个类型为UNSIGNED), 默认情况下会生成无符号结果.  如果结果否则为负,则会导致错误:

mysql> SET sql_mode = '';

mysql> SELECT CAST(0 AS UNSIGNED) - 1;
ERROR 1690 (22003): BIGINT UNSIGNED value is out of range in '(cast(0 as unsigned) - 1)'

如果启用了NO_UNSIGNED_SUBTRACTION SQL模式，则结果为负:

mysql> SET sql_mode = 'NO_UNSIGNED_SUBTRACTION';
mysql> SELECT CAST(0 AS UNSIGNED) - 1;
+-------------------------+
| CAST(0 AS UNSIGNED) - 1 |
+-------------------------+
|                      -1 |
+-------------------------+

如果使用此类操作的结果更新UNSIGNED整数列: 
如果禁用了NO_UNSIGNED_SUBTRACTION, 则结果将剪切为列类型的最大值, 
如果启用了NO_UNSIGNED_SUBTRACTION, 则结果将剪切为0. 如果启用严格的SQL模式后, 会发生错误并且列保持不变.
```

## innodb_strict_mode

```
默认情况下是ON, 即开启严格模式. OFF表示关闭严格模式
```
