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
```text
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

## innodb_strict_mode

```
默认情况下是ON, 即开启严格模式. OFF表示关闭严格模式
```
