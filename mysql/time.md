# MySQL 时间类型解析

MySQL 表示时间值的日期和时间类型是`DATE`, `TIME`, `DATETIME`, `TIMESTAMP`. 每个时间类型都有一系列有
效值, 以及当遇到了 MySQL *无法表示的无效值* 时可以使用的"零"值. `TIMESTAMP` 类型具有特殊的自动更新行为, 
稍后将对此进行描述.

## 使用日期和时间类型时, 一般注意事项

- 尽管MySQL试图以多种格式解释数值, 但日期部分必须始终以 `年-月-日` 的顺序(例如,'98-09-04') 给出, 而不是
以 `月-日-年` 或 `日-月-年`.

- 包含两位数年份值的日期不明确, 因为这个世纪是未知的. MySQL使用以下规则解释两位数的年份值:

>70-99范围内的年份值转换为1970-1999. \
>00-69范围内的年份值将转换为2000-2069.

- 如果在数值环境下使用日期类型值, MySQL会自动将 `Date` 或 `Time` 转换成数字. 反之亦然.

- 默认情况下, 当MySQL遇到 *超出范围的日期或时间类型的值* 或者 *对于该类型无效的值*, 它会将该值转换为该类型
的"零"值. **例外情况是超出范围的 TIME 值被剪切到 TIME 范围的适当端点**.

- 通过将SQL模式设置为适当的值, 可以更准确地指定希望MySQL支持的日期类型. 通过启用 `ALLOW_INVALID_DATES`
SQL模式, 可以让MySQL接受某些日期, 例如 `2009-11-31`. 当希望存储用户在数据库中指定的"可能错误"值(例如, 在
Web表单中)以供将来处理时, 这非常有用. 在此模式下, MySQL *仅验证月份是否在1到12的范围内, 并且该日期的范围是
1到31*.
 
- MySQL 允许在 `DATE` 或 `DATETIME` 列中存储day或month和day为零的日期类型值. 应用: 存储不知道确切日期(比
如, 生日).  在这种情况下, 只需将日期存储为 `2009-00-00` 或 `2009-01-00`. 如果存储诸如此类的日期, 则不能
通过调用 `DATE_SUB()` 或 `DATE_ADD()` 等函数去获得需要完整日期的的正确结果. 要想禁止日期中零月或零日时, 请
启用 `NO_ZERO_IN_DATE` SQL模式.

- MySQL允许将 `0000-00-00` 的 "零" 值存储为 "dummy date", 这在某些情况下比使用 `NULL` 值更方便, 并且
使用更少的数据和索引空间. 要想禁止 `0000-00-00`, 请启用 `NO_ZERO_DATE` SQL模式.

- 通过 `Connector / ODBC` 使用的 "零" 日期或时间值会自动转换为 `NULL`, 因为 `ODBC` 无法处理此类值.

下表显示了每种类型的 "零" 值的格式. "零" 值是特殊的, 但可以使用表中显示的值显式地存储或引用它们. 也可以使用值
"0" 或 0 来执行此操作, 这样更容易编写. 对于包含日期部分(`DATE`, `DATETIME` 和 `TIMESTAMP`) 的临时类型, 
如果启用了 `NO_ZERO_DATE` SQL模式, 则使用这些值会产生警告.

| TYPE | "Zero" Value |
| --- | --- |
| DATE | '0000-00-00' |
| TIME | '00:00:00' |
| DATETIME | '0000-00-00 00:00:00 |
| TIMESTAMP | '0000-00-00 00:00:00 |


## DATE, DATETIME, TIMESTAMP 类型

### 类型范围 

`DATE`, `DATETIME` 和 `TIMESTAMP` 类型是相关的.

**DATE** 类型用于 *只包含日期部分的值*. MySQL 以 `YYYY-MM-DD` 格式检索并显示DATE值. 支持的范
围是 `1000-01-01` 到 `9999-12-31`.

**DATETIME** 类型用于 *包含日期和时间部分的值*. MySQL 以 `YYYY-MM-DD hh:mm:ss` 格式检索并显示 `DATETIME`
值. 支持的范围是 `1000-01-01 00:00:00` 到 `9999-12-31 23:59:59`.

**TIMESTAMP** 类型用于 *包含日期和时间部分的值*. TIMESTAMP 的范围为 `1970-01-01 00:00:01 UTC` 到 
`2038-01-19 03:14:07 UTC`.

> 无效的 `DATE`, `DATETIME` 或 `TIMESTAMP` 值将转换为相应类型的 "零" 值(`0000-00-00` 或 `0000-00-00 00:00:00`).

**TIME** 类型用于 *只包含时间部分的值*, MySQL 以 `hh:mm:ss` 格式检索并显示 `TIME` 值. 支持是范围是
`-838:59:59.000000` 到 `838:59:59.000000`.

### DATETIME 或 TIMESTAMP 的共同点

`DATETIME` 或 `TIMESTAMP` 值可以包括高达 *微秒* (6位)精度的尾随小数秒部分. 

特别地, 插入 `DATETIME` 或 `TIMESTAMP` 列的值中的任何小数部分都将被存储而不是被丢弃. 包含小数部分, 这些值的
格式为 `YYYY-MM-DD hh:mm:ss[.us]`. 小数部分应始终与其余时间分开一个小数点; 不能识别出其他小数秒分隔符.

> `DATETIME` 值的范围为 `1000-01-01 00:00:00.000000` 到 `9999 -12-31 23:59:59.999999`. \
> `TIMESTAMP`值的范围是 `1970-01-01 00:00:01.000000` 到 `2038-01-19 03:14:07.999999`. 

`DATETIME` 和 `TIMESTAMP` 数据类型提供自动初始化和更新到当前日期和时间.


### TIMESTAMP 特征

MySQL 将 `TIMESTAMP` 值从当前时区转换为 `UTC` 以进行存储, 并从 `UTC` 转换回当前时区以进行检索. (对于其他类
型, 例如 `DATETIME`, 不会发生这种情况.) 

默认情况下, 每个连接的当前时区是服务器的时间. 可以基于每个连接设置时区. 只要时区设置保持不变, 就会获得存储的相同值. 
如果存储了 `TIMESTAMP` 值, 然后更改时区并检索该值, 则检索的值与存储的值不同. 发生这种情况是因为在两个方向上都没有
使用相同的时区进行转换. 当前时区可用作 `time_zone` 系统变量的值.


### **MySQL中 DATE 值的属性**

- 1.MySQL允许对指定为字符串的值使用 "relaxed(宽松)" 格式, 其中任何标点符号都可以用作日期部分或时间部分之间的分
隔符. 但是在某些情况下, 这种语法可能是欺骗性的. 例如, `10:11:12` 之类的值可能看起来像时间值, 因为使用了 `:`, 
但如果在日期上下文中使用, 则会被解释为年份 `2010-11-12`. 值 `10:45:15` 被转换为 `0000-00-00`, 因为 `45` 
不是有效月份.

> 在日期和时间部分与小数秒部分之间识别的唯一分隔符是小数点.

- 2.MySQl服务端要求月和日值有效, 而不仅仅分别在1到12和1到31的范围内. 如果禁用了严格模式后, `2004-04-31` 等无
效日期将转换为 `0000-00-00`, 并产生警告. 如果启用严格模式后, 无效日期会产生错误. 要允许此类日期, 启用 SQL 模式
`ALLOW_INVALID_DATES`.

- 3.MySQL 不接受在日期或月份列中包含 "零" 的 `TIMESTAMP` 值或不是有效日期的值. 该规则的唯一例外是特殊的 "零" 
值 `0000-00-00 00:00:00`.

- 4.可以在启用 `MAXDB` SQL模式的情况下运行MySQL服务端. 在这种情况下, `TIMESTAMP` 与 `DATETIME` 相同. 如果
在创建表时启用此模式, 则会将 `TIMESTAMP` 列创建为 `DATETIME` 列. 因此, 此类列使用 `DATETIME` 显示格式, 具有
相同的值范围, 并且**没有自动初始化或更新到当前日期和时间**.

> MySQL 5.7.22 之后, MAXDB 模式就弃用了.


## TIME 类型

MySQL 以 `hh:mm:ss` 格式(或 `hhh:mm:ss` 格式) 检索并显示 `TIME` 值. `TIME` 值的范围可以从 `-838:59:59`
到 `838:59:59`.  小时部分可能非常大, 因为 `TIME` 类型不仅可以用来表示一天中的时间(必须小于24小时), 还可以用于
表示两个事件之间的经过时间或时间间隔 (可能远大于24小时, 甚至是负数).

MySQL以多种格式识别 `TIME` 值, 其中一些格式可包括精确到 *微秒*(6位) 的尾随小数秒部分. 存储的时候不是丢弃插入到 
`TIME` 列中的值中的任何小数部分. 包含小数部分, `TIME` 值的范围是 `-838:59:59.000000` 到 `838:59:59.000000`.


将缩写值分配给 `TIME` 列时要小心. MySQL用 '冒号' 解释缩写的 `TIME` 值作为一天中的时间. 也就是说, `11:12` 表示
的是 `11:12:00`, 而不是 `00:11:12`. 

MySQL使用假设最右边的两个数字代表秒数 (即经过时间而不是时间) 来解释没有冒号的缩写值. 例如, 可能会将 `'1112'` 和 
`1112` 视为 `11:12:00` (11点后12分钟), 但MySQL将其解释为 `00:11:12` (11分12秒). 类似地, `'12'`和 `12` 被
解释为 `00:00:12`.

> 在时间部分和小数秒部分之间识别的唯一分隔符是小数点.


默认情况下, 位于 `TIME` 范围之外但其他方式有效的值将剪切到范围的最近端点. 例如, `-850:00:00` 和 `850:00:00` 
被转换为 `-838:59:59` 和 `838:59:59`. 无效的 `TIME` 值将转换为 `00:00:00`. 

注意, 因为 `00:00:00` 本身是一个有效的 `TIME` 值, 所以无法从表中存储的 `00:00:00` 值中判断原始值是否指定为 
`00:00:00` 或是否无效.

要对无效 `TIME` 值进行更严格的处理, 请启用严格SQL模式以导致错误发生.

---

## TIMESTAMP 和 DATETIME 的自动初始化和更新

`TIMESTAMP` 和 `DATETIME` 列可以自动初始化并更新为当前日期和时间(即当前时间戳).

对于表中的任何 `TIMESTAMP` 或 `DATETIME` 列, 可以将当前时间戳分配为默认值.

只要满足下面任何一种状况, 就会 `auto-update`:

1. 在插入一行数据的时候, **如果 `auto-initialized` 列没有指定值, 会被设置为当前时间戳**.

2. 当行中任何其他列的值从 `其当前值` 更改时, `auto-updated` 列将自动更新为当前时间戳.  如果 `所有其他列都设置为
其当前值(不改变)`, 则 `auto-updated` 列保持不变. 为了防止在其他列更改时, `auto-updated` 列发生更新, 请将其显
示设置为 `其当前值`. 如果要更新 `auto-updated` 列(即使其他列未更改), 也要将其显式设置为应具有的值(例如, 将其设置
为 `CURRENT_TIMESTAMP`).


此外, 如果禁用了系统变量 `explicit_defaults_for_timestamp` (设置为 `OFF` 或者 `FALSE`), 则可以通过为其分配
`NULL` 值来初始化或更新任何 `TIMESTAMP` (但不是 `DATETIME`) 列到当前日期和时间, 除非已使用 `NULL` 属性定义以
允许 `NULL` 值.


要指定 `automatic` 属性, 请在列定义中使用 `DEFAULT CURRENT_TIMESTAMP` 和 `ON UPDATE CURRENT_TIMESTAMP` 
子句. 语句的顺序无关紧要. 如果两者都存在于列定义中, 任何一个都可以先执行.  `CURRENT_TIMESTAMP`  的任何同义词与
`CURRENT_TIMESTAMP`具有相同的含义. 这些是 `CURRENT_TIMESTAMP()`, `NOW()`, `LOCALTIME`, `LOCALTIME()`, 
`LOCALTIMESTAMP` 和 `LOCALTIMESTAMP()`.


使用 `DEFAULT CURRENT_TIMESTAMP` 和 `ON UPDATE CURRENT_TIMESTAMP` 只能限定于 `TIMESTAMP` 和 `DATETIME`
类型. `DEFAULT` 子句也可用于指定常量(非自动)默认值; 例如, `DEFAULT 0` 或 `DEFAULT '2000-01-01 00:00:00'`.

> 以下示例使用 `DEFAULT 0`, 这是一个默认值, 可能产生警告或错误, 具体取决于是否启用了严格的SQL模式或 `NO_ZERO_DATE` 
SQL模式. 注意, `TRADITIONAL` SQL模式包括严格模式和 `NO_ZERO_DATE`.


### automatic 属性

`TIMESTAMP` 或 `DATETIME` 列定义可以指定默认值和自动更新值的当前时间戳, 对于指定其中的任何一个, 或两者都不指定. 
不同的列可以具有不同的自动属性组合. 以下规则描述了可能性:

- 使用 `DEFAULT CURRENT_TIMESTAMP` 和 `ON UPDATE CURRENT_TIMESTAMP` 时, 该列具有其默认值的当前时间戳,
并自动更新为当前时间戳.

```sql
CREATE TABLE t1 (
  ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  dt DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

- 使用 `DEFAULT` 子句但没有 `ON UPDATE CURRENT_TIMESTAMP` 子句时, 该列具有给定的默认值, 并且不会自动更新
为当前时间戳.

缺省值取决于 `DEFAULT` 子句是指定 `CURRENT_TIMESTAMP` 还是常量值. 使用 `CURRENT_TIMESTAMP`, 默认值是当
前时间戳.

```sql
CREATE TABLE t1 (
  ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  dt DATETIME DEFAULT CURRENT_TIMESTAMP
);
```

使用常量, 默认值是给定值. 在这种情况下, 该列根本没有自动属性.

```sql
CREATE TABLE t1 (
  ts TIMESTAMP DEFAULT 0,
  dt DATETIME DEFAULT 0
);
```

- 使用 `ON UPDATE CURRENT_TIMESTAMP` 子句和常量 `DEFAULT` 子句, 该列会自动更新到当前时间戳; 该列拥有给定的
默认的时间值

```sql
CREATE TABLE t1 (
  ts TIMESTAMP DEFAULT 0 ON UPDATE CURRENT_TIMESTAMP,
  dt DATETIME DEFAULT 0 ON UPDATE CURRENT_TIMESTAMP
);
```

- 使用 `ON UPDATE CURRENT_TIMESTAMP` 子句但没有 `DEFAULT` 子句时, 该列会自动更新为当前时间戳; 该列没有当前
时间戳作为其默认值.

在这种情况下, 默认值取决于类型. 如果使用 `NULL` 属性定义, 这种情况下默认值为`NULL`, 否则 `TIMESTAMP` 的默认值
为0.

```sql
CREATE TABLE t1 (
  ts1 TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,     -- default 0
  ts2 TIMESTAMP NULL ON UPDATE CURRENT_TIMESTAMP -- default NULL
);
```

如果使用了 `NOT NULL` 属性定义, 在这种情况下, 默认值为0, 否则 `DATETIME` 的默认值为 `NULL`.

```sql
CREATE TABLE t1 (
  dt1 DATETIME ON UPDATE CURRENT_TIMESTAMP,         -- default NULL
  dt2 DATETIME NOT NULL ON UPDATE CURRENT_TIMESTAMP -- default 0
);
```


### 禁止自动属性

如果显示设置了 `TIMESTAMP` 和 `DATETIME` 列的值, 则它们没有自动属性. 但有以下异常: 如果禁用了系统变量 
`explicit_defaults_for_timestamp`, 则第一个 `TIMESTAMP`列同时具有 `DEFAULT CURRENT_TIMESTAMP` 和
`ON UPDATE CURRENT_TIMESTAMP` (如果两者都未明确指定). 要禁止第一个 `TIMESTAMP` 列的自动属性, 请使用以下
策略之一:

- 启用 `explicit_defaults_for_timestamp` 系统变量. 在这种情况下, 指定自动初始化和自动更新的 `DEFAULT 
CURRENT_TIMESTAMP` 和 `ON UPDATE CURRENT_TIMESTAMP` 子句可用, 但除非明确包含在列定义中, 否则不会分配给
任何 `TIMESTAMP` 列.


- 如果禁用 `explicit_defaults_for_timestamp`, 请执行以下任一操作:

```
使用 DEFAULT 子句定义列, 该子句指定常量默认值.

指定 NULL 属性. 这也会导致列允许 NULL 值, 这意味着无法通过将列设置为 NULL 来分配当前时间戳. 分配NULL会将列设
置为 NULL, 而不是当前时间戳. 要分配当前时间戳, 请将列设置为 CURRENT_TIMESTAMP 或 同义词, 例如 NOW().
```

### 案例:

```sql
CREATE TABLE t1 (
  ts1 TIMESTAMP DEFAULT 0,
  ts2 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE t2 (
  ts1 TIMESTAMP NULL,
  ts2 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE t3 (
  ts1 TIMESTAMP NULL DEFAULT 0,
  ts2 TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

以上的 Table 具有的属性:

- 在每个表定义中, 第一个 `TIMESTAMP` 列没有自动初始化或更新.

- 这些表的不同之处在于 `ts1` 列如何处理 `NULL` 值. 对于 `t1`, `ts1` 为 `NOT NULL`, 并为其赋值为 `NULL`,
将其设置为当前时间戳. 对于 `t2` 和 `t3`, `ts1` 允许 `NULL` 并为其赋值 `NULL` 将其设置为 `NULL`.

- `t2` 和 `t3` 在 `ts1` 的默认值上有所不同. 对于`t2`, `ts1` 被定义为允许 `NULL`, 因此在没有显式 `DEFAULT`
子句的情况下, 默认值也为 `NULL`. 对于 `t3`, `ts1` 允许 `NULL` 但显式默认值为0.


如果 `TIMESTAMP` 或 `DATETIME` 列定义在任何位置包含显式小数秒精度值, 则必须在整个列定义中使用相同的值. 下表允
许的:

```sql
CREATE TABLE t1 (
  ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6)
);
```

下表是不允许的:

```sql
CREATE TABLE t1 (
  ts TIMESTAMP(6) DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP(3)
);
```

### TIMESTAMP 初始化和 NULL 属性

如果禁用 `explicit_defaults_for_timestamp` 系统变量, 则默认情况下 `TIMESTAMP` 列为 `NOT NULL`, 不能包含
`NULL`值, 而赋值 `NULL` 则指定当前时间戳. 要允许 `TIMESTAMP` 列包含 `NULL`, 请使用 `NULL` 属性显式声明它.  
在这种情况下, 除非使用指定不同默认值的 `DEFAULT` 子句覆盖, 否则默认值也将变为 `NULL`. `DEFAULT NULL` 可用于显
式指定 `NULL` 作为默认值. (对于未使用 `NULL` 属性声明的 `TIMESTAMP` 列, `DEFAULT NULL` 无效.) 如果 `TIMESTAMP`
列允许 `NULL` 值, 则分配 `NULL` 会将其设置为 `NULL`, 而不是当前时间戳.


下表包含几个允许NULL值的TIMESTAMP列:

```sql
CREATE TABLE t (
  ts1 TIMESTAMP NULL DEFAULT NULL,
  ts2 TIMESTAMP NULL DEFAULT 0,
  ts3 TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);
```


允许 `NULL` 值的 `TIMESTAMP` 列在插入时不会占用当前时间戳, 除非在以下条件之一下:

- 其默认值定义为 `CURRENT_TIMESTAMP`, 并且当前列没有设定值.

- `CURRENT_TIMESTAMP` 或 其任何同义词(如 `NOW()`)都显式插入到列中.


换句话说, 定义为允许 `NULL` 值的 `TIMESTAMP` 列仅在其定义包含 `DEFAULT CURRENT_TIMESTAMP` 时自动初始化:

```sql
CREATE TABLE t (  
  ts TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);
```


如果 `TIMESTAMP` 列允许 `NULL` 值但其定义不包括 `DEFAULT CURRENT_TIMESTAMP`, 则必须显式插入与当前日期和时间
对应的值. 假设表t1和t2具有以下定义:

```sql
CREATE TABLE t1 (
  ts TIMESTAMP NULL DEFAULT '0000-00-00 00:00:00'
);

CREATE TABLE t2 (
  ts TIMESTAMP NULL DEFAULT NULL
);
```

要在任一表中将 `TIMESTAMP` 列设置为插入时的当前时间戳, 请显式为其分配该值. 例如:

```sql
INSERT INTO t2 VALUES (CURRENT_TIMESTAMP);
INSERT INTO t1 VALUES (NOW());
```

如果启用了 `explicit_defaults_for_timestamp` 系统变量, 则 `TIMESTAMP` 列仅在使用 `NULL` 属性声明时才允许
`NULL`值. 此外, `TIMESTAMP` 列不允许分配 `NULL` 以分配当前时间戳, 无论是使用 `NULL` 还是 `NOT NULL` 属性声
明. 要分配当前时间戳, 请将列设置为 `CURRENT_TIMESTAMP` 或 同义词, 例如 `NOW()`.


## DATE 和 TIME 类型之间的转换

在某种程度上, 可以将值从一种时间类型转换为另一种时间类型. 但是, 信息的价值或损失可能会有一些变化. 在所有情况下, 时
间类型之间的转换受结果类型的有效值范围的限制. 例如,尽管可以使用相同的格式集指定 `DATE`, `DATETIME` 和 `TIMESTAMP`
值, 但这些类型并不都具有相同的值范围.\
`TIMESTAMP`值不能早于 `1970 UTC` 或晚于 `2038-01-19 03:14:07 UTC`. 这意味着诸如 `1968-01-01` 之类的日期
使用 `DATE` 或 `DATETIME` 类型值才会有效, 但使用 `TIMESTAMP` 类型值会无效并且转换为 `0`.


### 转换 DATE 值:

- 转换为 `DATETIME` 或 `TIMESTAMP` 值会添加 `00:00:00` 的时间部分, 因为 `DATE` 值不包含时间信息.

- 转换为 `TIME` 值无效, 结果是 `00:00:00`.

### 转换 DATETIME 和 TIMESTAMP 值

- 转换为 `DATE` 值需要考虑小数秒并对时间部分进行舍入. 例如, `1999-12-31 23:59:59.499` 变为 `1999-12-31`, 而
`1999-12-31 23:59:59.500` 变为 `2000-01-01`.

- 转换为 `TIME` 值会丢弃日期部分, 因为 `TIME` 类型不包含日期信息.

### 对于 TIME 值转换为其他时间类型

`CURRENT_DATE()` 的值用于日期部分. `TIME` 被解释为经过时间(不是时间)并添加到日期. 这意味着如果时间值超出`00:00:00`
到 `23:59:59` 的范围, 则结果的日期部分与当前日期不同.

假设当前日期为 `2012-01-01`. `TIME` 值为 `12:00:00`, `24:00:00` 和 `-12:00:00`, 转换为 `DATETIME` 
或 `TIMESTAMP`值时, 结果分别是 `2012-01-01 12:00:00`, `2012-01-02 00:00:00` 和 `2011-12-31 12:00:00`.

`TIME` 转换为 `DATE` 类似, 但会从结果中丢弃时间部分: `2012-01-01`, `2012-01-02` 和 `2011-12-31`.

---

显式转换可用于覆盖隐式转换. 例如, 在 `DATE` 和 `DATETIME` 值的比较中, 通过添加 `00:00:00` 的时间部分将 `DATE`
值强制转换为 `DATETIME` 类型. 要通过忽略 `DATETIME` 值的时间部分来执行比较, 请按以下方式使用 `CAST()` 函数:

```sql
date_col = CAST(datetime_col AS DATE)
```

将 `TIME` 和 `DATETIME` 值转换为数字形式(例如, 通过添加+0)取决于该值是否包含小数秒部分. 当N为0(或省略)时, 
`TIME(N)` 或 `DATETIME(N)` 转换为整数, 当N大于0时, 转换为具有N个十进制数字的 `DECIMAL`值:

```sql
mysql> SELECT CURTIME(), CURTIME()+0, CURTIME(3)+0;
+-----------+-------------+--------------+
| CURTIME() | CURTIME()+0 | CURTIME(3)+0 |
+-----------+-------------+--------------+
| 09:28:00  |       92800 |    92800.887 |
+-----------+-------------+--------------+

mysql> SELECT NOW(), NOW()+0, NOW(3)+0;
+---------------------+----------------+--------------------+
| NOW()               | NOW()+0        | NOW(3)+0           |
+---------------------+----------------+--------------------+
| 2012-08-15 09:28:00 | 20120815092800 | 20120815092800.889 |
+---------------------+----------------+--------------------+
```

## MySQL 获得当前日期时间函数

- 获得当前日期+时间(date + time)函数: `now()`

```
mysql> select now();

+---------------------+
| now()               |
|---------------------|
| 2020-04-28 17:25:45 |
+---------------------+
```

- 获得当前日期+时间(date + time)函数: `sysdate()`

> sysdate() 日期时间函数跟 now() 类似,不同之处在于:

> now() 在执行开始时值就得到了, sysdate() 在函数执行时动态得到值. 看下面的例子就明白了:

```
mysql> select now(), sleep(3), now();

+---------------------+------------+---------------------+
| now()               |   sleep(3) | now()               |
|---------------------+------------+---------------------|
| 2020-04-28 17:25:24 |          0 | 2020-04-28 17:25:24 |
+---------------------+------------+---------------------+
```


> sysdate() 日期时间函数, 一般情况下很少用到.

 

- MySQL 获得当前时间戳函数: `current_timestamp`, `current_timestamp()`

```
mysql> select current_timestamp, current_timestamp();

+---------------------+-----------------------+
| current_timestamp   | current_timestamp()   |
|---------------------+-----------------------|
| 2020-04-28 17:26:40 | 2020-04-28 17:26:40   |
+---------------------+-----------------------+
```
 
- MySQL 日期转换函数, 时间转换函数

1. MySQL Date/Time to Str(日期/时间转换为字符串)函数: `date_format(date,format)`, `time_format(time,format)`


```
mysql> select date_format('2008-08-08 22:23:01', '%Y%m%d%H%i%s');

+------------------------------------------------------+
|   date_format('2008-08-08 22:23:01', '%Y%m%d%H%i%s') |
|------------------------------------------------------|
|                                       20080808222301 |
+------------------------------------------------------+
```


MySQL 日期,时间转换函数: date_format(date,format), time_format(time,format) 能够把一个日期/时间转换成各种各样的字符串格式, 
它是 `str_to_date(str,format)` 函数的 一个逆转换.

 

- MySQL Str to Date (字符串转换为日期)函数: `str_to_date(str, format)`

```
select str_to_date('08/09/2008', '%m/%d/%Y'); -- 2008-08-09
select str_to_date('08/09/08' , '%m/%d/%y'); -- 2008-08-09
select str_to_date('08.09.2008', '%m.%d.%Y'); -- 2008-08-09
select str_to_date('08:09:30', '%h:%i:%s'); -- 08:09:30
select str_to_date('08.09.2008 08:09:30', '%m.%d.%Y %h:%i:%s'); -- 2008-08-09 08:09:30
```

可以看到, `str_to_date(str,format)` 转换函数,可以把一些杂乱无章的字符串转换为日期格式. 另外,它也可以转换为时间. "format" 可以参看 MySQL 手册.


- MySQL (日期,天数)转换函数: `to_days(date)`, `from_days(days)`

```
select to_days('0000-00-00'); -- 0
select to_days('2008-08-08'); -- 733627
```

- MySQL (时间,秒) 转换函数: `time_to_sec(time)`, `sec_to_time(seconds)`

```
select time_to_sec('01:00:05'); -- 3605
select sec_to_time(3605); -- '01:00:05'
```

 

- MySQL 拼凑日期, 时间函数: `makdedate(year,dayofyear)`, `maketime(hour,minute,second)`

```
select makedate(2001,31); -- '2001-01-31'
select makedate(2001,32); -- '2001-02-01'

select maketime(12,15,30); -- '12:15:30'
```

- MySQL (Unix 时间戳、日期)转换函数

```angular2html
unix_timestamp(),
unix_timestamp(date),

from_unixtime(unix_timestamp),
from_unixtime(unix_timestamp,format)
```


下面是示例:

```
select unix_timestamp(); -- 1218290027
select unix_timestamp('2008-08-08'); -- 1218124800
select unix_timestamp('2008-08-08 12:30:00'); -- 1218169800

select from_unixtime(1218290027); -- '2008-08-09 21:53:47'
select from_unixtime(1218124800); -- '2008-08-08 00:00:00'
select from_unixtime(1218169800); -- '2008-08-08 12:30:00'

select from_unixtime(1218169800, '%Y %D %M %h:%i:%s %x'); -- '2008 8th August 12:30:00 2008'
```

- MySQL 日期时间计算函数

MySQL 为日期增加一个时间间隔: `date_add()`

```
set @dt = now();

select date_add(@dt, interval 1 day); -- add 1 day
select date_add(@dt, interval 1 hour); -- add 1 hour
select date_add(@dt, interval 1 minute); -- ...
select date_add(@dt, interval 1 second);
select date_add(@dt, interval 1 microsecond);
select date_add(@dt, interval 1 week);
select date_add(@dt, interval 1 month);
select date_add(@dt, interval 1 quarter);
select date_add(@dt, interval 1 year);
select date_add(@dt, interval -1 day); -- sub 1 day
```

MySQL `adddate()`, `addtime()` 函数, 可以用 date_add() 来替代. 下面是 date_add() 实现 addtime() 功能示例:

```
mysql> set @dt = '2008-08-09 12:12:33';

mysql> select date_add(@dt, interval '01:15:30' hour_second);
+------------------------------------------------+
| date_add(@dt, interval '01:15:30' hour_second) |
+------------------------------------------------+
| 2008-08-09 13:28:03                            |
+------------------------------------------------+

mysql> select date_add(@dt, interval '1 01:15:30' day_second);
+-------------------------------------------------+
| date_add(@dt, interval '1 01:15:30' day_second) |
+-------------------------------------------------+
| 2008-08-10 13:28:03                             |
+-------------------------------------------------+
```


MySQL 为日期减去一个时间间隔: `date_sub()`

```
mysql> select date_sub('1998-01-01 00:00:00', interval '1 1:1:1' day_second);
+----------------------------------------------------------------+
| date_sub('1998-01-01 00:00:00', interval '1 1:1:1' day_second) |
+----------------------------------------------------------------+
| 1997-12-30 22:58:59                                            |
+----------------------------------------------------------------+
```

MySQL `date_sub()` 日期时间函数 和 `date_add()`用法一致, 不再赘述.
 

MySQL 日期,时间相减函数: `datediff(date1,date2)`, `timediff(time1,time2)`

MySQL datediff(date1,date2):两个日期相减 date1 - date2,返回天数.
```
select datediff('2008-08-08', '2008-08-01'); -- 7
select datediff('2008-08-01', '2008-08-08'); -- -7
```

MySQL timediff(time1,time2):两个日期相减 time1 - time2,返回 time 差值.
```
select timediff('2008-08-08 08:08:08', '2008-08-08 00:00:00'); -- 08:08:08
select timediff('08:08:08', '00:00:00'); -- 08:08:08
```

> 注意: timediff(time1,time2) 函数的两个参数类型必须相同.


- MySQL 时间戳(timestamp)转换, 增, 减函数:

timestamp(date) -- date to timestamp
timestamp(dt,time) -- dt + time
timestampadd(unit,interval,datetime_expr) --
timestampdiff(unit,datetime_expr1,datetime_expr2) --

```
select timestamp('2008-08-08'); -- 2008-08-08 00:00:00
select timestamp('2008-08-08 08:00:00', '01:01:01'); -- 2008-08-08 09:01:01
select timestamp('2008-08-08 08:00:00', '10 01:01:01'); -- 2008-08-18 09:01:01
```

````
select timestampadd(day, 1, '2008-08-08 08:00:00'); -- 2008-08-09 08:00:00
select date_add('2008-08-08 08:00:00', interval 1 day); -- 2008-08-09 08:00:00
````

MySQL `timestampadd()` 函数类似于 `date_add()`.


```
select timestampdiff(year,'2002-05-01','2001-01-01'); -- -1
select timestampdiff(day ,'2002-05-01','2001-01-01'); -- -485
select timestampdiff(hour,'2008-08-08 12:00:00','2008-08-08 00:00:00'); -- -12

select datediff('2008-08-08 12:00:00', '2008-08-01 00:00:00'); -- 7
```

MySQL `timestampdiff()` 函数就比 `datediff()` 功能强多了, `datediff()` 只能计算两个日期(date)之间相差的天数.


- MySQL 时区(timezone)转换函数: `convert_tz(dt,from_tz,to_tz)`

```
select convert_tz('2008-08-08 12:00:00', '+08:00', '+00:00'); -- 2008-08-08 04:00:00
```

> 时区转换也可以通过 date_add, date_sub, timestampadd 来实现.

```
select date_add('2008-08-08 12:00:00', interval -8 hour); -- 2008-08-08 04:00:00
select date_sub('2008-08-08 12:00:00', interval 8 hour); -- 2008-08-08 04:00:00
select timestampadd(hour, -8, '2008-08-08 12:00:00'); -- 2008-08-08 04:00:00
```