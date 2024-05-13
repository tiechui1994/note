## MySQL 类型 - 字符串

字符串数据类型为 `CHAR`, `VARCHAR`, `BINARY`, `VARBINARY`, `BLOB`, `TEXT`, `LONGTEXT`.

除了上述的常见的类型外, 还有 `ENUM`, `SET`

### 常见字符串类型

MySQL 使用 `CREATE TABLE` 或 `ALERT TABLE` 语句定义数据类型.

对于字符串列 (`CHAR`, `VARCHAR`, `TEXT`)的定义, MySQL以字符单位解析长度规范. 对于二进制字符串列(`BINARY`, 
`VARBINARY`, `BLOB`)的定义, MySQL以字节为单位解析长度规范.

`CHARSET` 指定字符集. 如果需要, 可以使用 `COLLATE` 属性以及任何其他属性来指定字符集的排序规则. 例如:

```
CREATE TABLE t (
    c1 VARCHAR(20) CHARSET utf8,
    c2 TEXT CHARSET latin1 COLLATE latin1_general_cs
);
```

> c2, 字符集是 `latin1`, 排序规则是 `latin1_general_cs` (区分大小写的 `_cs`)

- 为字符串数据类型指定 `CHARSET binary` 属性会使该列创建为相应的二进制字符串数据类型: `CHAR` 变 `BINARY`, `VARCHAR`
变 `VARBINARY`, `TEXT` 变 `BLOB`. 对于 `ENUM` 和 `SET` 数据类型, 不发生这种状况.

- `BINARY` 属性是非标准的 MySQL 扩展, 它是用于指定列字符集(或未指定列字符集合的table默认字符集)的二进制 (`_bin`)
排序规则的简写. 在这种状况下, 比较和排序给予数字字符代码值. 

```
CREATE TABLE t
(
    c1 VARCHAR(10) CHARSET latin1 BINARY,
    c2 TEXT BINARY
) CHARSET utf8mb4;
```

=> 

```
CREATE TABLE t
(
    c1 VARCHAR(10) CHARSET latin1 COLLATE latin1_bin,
    c2 TEXT CHARSET utf8mb4 COLLATE utf8mb4_bin
) CHARSET utf8mb4;
```

> CHARSET 简写:
> 1) `ASCII` 属性是 `CHARSET latin1` 的简写
> 2) `UNICODE` 属性是 `CHARSET ucs2` 的简写

- `CHAR[(M)] [CHARSET charset] [COLLATE collation]`, 一个固定长度的字符串, M表示长度, 在存储时总是用空格填充
到指定的长度. `M` 的范围是 0 到 255. 如果省略, 则长度是1

- `VARCHAR[(M)] [CHARSET charset] [COLLATE collation]`, 可变长度的字符串, M 表示最大长度, 以字符为单位. M
的范围是 0 到 65535. `VARCHAR` 的有效最大长度取决于最大行大小(65535字节, 在所有列之间共享)和所使用的字符集. 例如:
`utf8` 每个字符最多需要3个字节, 因此使用 `utf8` 字符集的 `VARCHAR` 可以声明为最多 21844 个字符.

MySQL 将 `VARCHAR` 值存储为 `1字节或2字节长的前缀+数据`. 长度前缀表示值中的字节数. 如果值要求不超过255个字节, 则
`VARCHAR` 使用一个长度字节; 如果值可能需要255个字节, 则 `VARCHAR` 使用两个长度字节.

- `BINARY[(M)]`, `BINARY` 类型类似于 `CHAR` 类型, 但是存储 `二进制字节字符串` 而不是 `二进制字符串`. 可选长度
M 表示以字节为单位的长度. 如果省略, 默认值是1.

- `VARBINARY[(M)]`, `VARBINARY` 类型类似于 `VARCHAR` 类型.

---

- `TINYBLOB`, 最大长度为255个字节. 每个 `TINYBLOB` 值使用1字节长的前缀存储, 该前缀表示值中的字节数.

- `TINYTEXT [CHARSET charset] [COLLATE collate]`, 最大长度为 255 个字符. 如果该值包含多字节字符, 则有效最大
长度, 则有效长度更小. 每个 `TINYTEXT` 值使用1字节长的前缀存储, 该前缀表示值中的字节数.

- `BLOB[(M)]`, 最大长度为 `2^16-1` 字节, 使用2字节长的前缀存储长度, 该前缀表示值中的字节数. 可以为此类型指定一个
可选的长度 M. 这样, MySQL 将创建该列为最小的 BLOB 类型, 该类型的大小足以容纳值 M 字节长.

- `TEXT[(M)] [CHARSET charset] [COLLATE collate]`, 最大长度为 `2^16-1` 个字符. 如果该值包含多个字节字符, 则
有效长度会更小. 使用2字节长的前缀存储长度, 该前缀表示值中的字节数. 可以为此类型指定一个可选的长度 M. 这样, MySQL 将
创建该列为最小的 TEXT 类型, 该类型的大小足以容纳值 M 字符.

- `MEDIUMBLOB`, 最大长度为 `2^24-1` 字节, 使用4字节长的前缀存储长度.

- `MEDIUMTEXT[(M)] [CHARSET charset] [COLLATE collate]`, 最大长度为 `2^24-1` 个字符, 使用3字节长的前缀存储长度.

- `LONGBLOB`, 最大长度为 `2^32-1` 字节, 使用4字节长的前缀存储长度.

- `LONGTEXT[(M)] [CHARSET charset] [COLLATE collate]`, 最大长度为 `2^32-1` 个字符, 使用4字节长的前缀存储长度.

> `BLOB` vs `TEXT`, BLOB 不可排序, TEXT 可排序

---

- `ENUM('value1', 'value2', ...) [CHARSET charset] [COLLATE collate]`, 枚举. 一个字符串对象, 只能有一个值,
可以从 `'value1'`, `'value2'`, `...`, `NULL` 或特殊 `''` 当中选择. `ENUM` 值在内部 table 表示整数. `ENUM`
列最多可包含 `2^16-1` 个不同的元素. 

- `SET('value1', 'value2', ...) [CHARSET charset] [COLLATE collate]`可以具有0个或多个值的字符串对象, 每个值
必须从值 `'value1'`, `'value2'`, `...` SET 的值列中选择. 在内部以整数表示. SET 列最多可包含 64 个不同的成员.

### CHAR, VARCHAR 类型

CHAR 与 VARCHAR 类型类似, 但是存储和检索方式不同.  CHAR 与 VARCHAR 类型声明表示要存储的最大字符数. 例如 `CHAR(20)` 
表示最多容纳 20 个字符.

CHAR 列的长度固定为在创建表时声明的长度. 长度可以是 0 到 255 之间的任意值. 存储 CHAR 值时, 会在右侧用空格填充到指
定的长度.

VARCHAR 列中的值是可变长度字符串. 长度可以指定为 0 到 65535 之间的值. VARCHAR 的有效最大长度取决于最大行大小和使用
的字符集(CHARSET). 与 CHAR 不同, VARCHAR 值存储为 1 字节或 2 字节长度前缀加数据. 长度前缀指示值中的字节数. 如果值
需要不超过 255 个字节, 则列使用一个长度字节; 如果值可能需要超过 255 个字节, 则列使用两个长度字节.

> InnoDB 将长度大于或等于 768 字节的固定长度字段编码为可变长度字段, 可以存储在页外. 例如: 如果字符集的最大字节长度大于 3(例如utf8mb4),
> 则 CHAR(255) 列可能会超过 768 个字节, 就像 utf8mb4 一样.

### BLOB, TEXT 类型

BLOB 是一种二进制大对象, 可以保存可变数量的数据, 共有四种类型. 它们具有二进制字符集和排序规则, 比较和排序基于列值中
字节的数值.

TEXT 值被视为非二进制字符串(字符串). 它们具有二进制以外的字符集, 并且根据字符集的排序规则对值进行排序和比较.

> 对于 BLOB 和 TEXT 列上的索引, 必须指定索引前缀长度.

由于 BLOB 和 TEXT 值可能非常长, 因此在使用它们时可能会遇到一些限制:

1) 排序时使用前 max_sort_length 字节, 默认值是 1024

2) BLOB 或 TEXT 对象的最大大小由其类型决定, 但实际由在客户端和服务器之间传输的最大值由可用内存量和通信缓冲区的大小
决定 max_allowed_packet 变量. 

3) 每个 BLOB 或 TEXT 值在内部由单独分配的对象表示.

### ENUM 类型

ENUM 是一个字符串对象, 其值是允许值的列中选择.

ENUM 优点:

- 在列的一组可能值有限的情况下, 压缩数据存储. 

- 可读的查询和输出.

潜在的问题:

- 如果使枚举看起来像数字, 则很容易将 Literals 值与它们的内部索引混合使用.

- 在 `ORDER BY` 子句中使用 `ENUM` 列需要格外小心.

- 创建和使用 ENUM 列

- 枚举 Literals 的索引值

- 枚举 Literals 的处理

- 空或NULL枚举值

创建:

```
CREATE TABLE shirt (
    name VARCHAR(40),
    size SET('x-small', 'small', 'medium', 'large', 'x-large')
);
```

枚举 Literals 的索引值:

- 列规范中列出的元素分配有索引号, 从1开始

- 空字符串错误值的索引值为0, 这意味可以使用 `enum_col=0` 条件去查询无效 ENUM 值的行.

- NULL 值是索引是 NULL

> 注: 上述的索引指的是枚举值在列ENUM当中的位置.

枚举 Literals 的处理:

创建 table 时, 会从 table 定义中的 ENUM 成员中自动删除尾随的空格.

如果讲数字存储到 ENUM 列中, 则该数字被视为可能值的索引, 并且存储的值是具有还索引的枚举成员. (但是, 这不适应于 LOAD DATA,
它会将所有的导入到视为字符串.) 如果用带引号的数字, 但如果枚举值列当中没有匹配的字符串, 则仍将其解析为索引. 由于上述的原因,
不建议使用枚举值定义数字的 `ENUM` 列, 很容易造成混淆. 

例如: 枚举成员, 字符串值为 `'0', '1', '2'`, 但数字索引值是 1, 2, 3.

如果存储 `2`, 它被解析为一个索引值, 并成为 `'1'`. 

如果存储 `'2'`, 则它于枚举值匹配, 因此将其存储为 `'2'`.

如果存储 `'3'`, 则它与任何枚举值都不匹配, 因此它将被视为索引并成为 `'2'`

空或NULL枚举值:

在某些状况下, 枚举值可以是空字符串('') 或 NULL.

1) 如果将无效值插入 ENUM (即, 在允许值列中不存在的字符串), 则插入空字符串作为特殊错误值. 通过讲该字符串的数值设为0, 可
以将该字符串与"正常"的字符串区分开来.  如果启用了严格SQL模式, 则尝试插入无效的 ENUM 值将导致错误.

2) 如果将 ENUM 列声明为允许 NULL, 则 NULL 值是该列的有效值. 默认值为 NULL. 如果讲 ENUM 列声明为 NOT NULL, 则其
默认值是允许值列的第一个元素.


枚举排序:

ENUM 值根据其索引排序, 该索引号取决于列规范列出的枚举成员的顺序. 空字符串排在非空字符串之前, NULL值排在所有其他枚举值之
前.

为了防止在 ENUM 列上使用 `ORDER BY` 子句出现意外结果, 请使用以下一种技术.

1) 按字母顺序指定 ENUM 列

2) 确保通过编码 `ORDER BY CAST(col AS CHAR)` 或 `ORDER BY CONCAT(col)` 对列进行词汇排序, 而不是按照索引号排序.

### SET 类型

SET 是一个字符串对象, 可以具有0个或多个值, 每个值都必须从创建 table 时指定的允许列中选择. 由多个集合成员组成的 SET 列
值用逗号 `,` 分隔的成员指定.  这样的结果是 `SET` 成员本身不能包含逗号.

创建:

```
CREATE TABLE myset (
    col SET('a', 'b', 'c', 'd')
);
```

插入:

插入后, 元素是按照 `SET` 当中的元素进行排序的. 例如, `SET('b','a','d','c')`, 当插入 `'a,b,c'` 时, 则在数据库当中
数据的顺序是 `b,a,c`.

查询:

```
SELECT * FROM myset WHERE (col>>0)&1 AND (col>>1)&1;

SELECT * FROM myset WHERE col='a,d';

SELECT * FROM myset WHERE col LIKE '%value%';
```

第一条语句查询的是 `col` 包含 `SET` 当中第一个元素 'a' 和 第二个元素 'b' 的行. 注: 如果对 col 建立索引的话, 该条语
句是可以命中索引的. find_in_set(value, col), 使用该函数也是可以命中索引的.

第二条语句查询的是 `col` 是 'a,d' 的列(确定匹配). 需要注意, 如果匹配写成 'd,a', 则结构可能不一样.

第三条语句查询的是模糊匹配.


## 优化建议

对于 BLOB, TEXT, VARCHAR(5120) 这类的大字段, InnoDB 只会存储前 768 字节在数据页中, 而剩余的数据则会存储在溢出段(
发生溢出情况). 最大 768 字节的作用是便于创建前缀索引(prefix index), 其余更多的内容存在额外的 page 里.

大字段引起的问题:

1) 可能浪费大量的空间. 例如, 若存储字段值只是比行的要求多了一个字节, 也会使用整个页面来存在剩余的字节, 浪费了页面的
大部分空间; 

2) 扩展存储禁用了自适应哈希, 因为需要完整比较列的整个长度, 才能发现是不是正确的数据. 因为自适应哈希是完全的内存结构,
并且直接指向 Buffer Pool 中访问 "最频繁的页面", 对于扩展存储空间无法使用 Adaptive Hash. 

MySQL 的 io 以page为单位, 因此不必要的数据(大字段) 也会随着需要操作的数据一同被读取到内存中来, 这样带来的问题由于
大字段会占用较大的内存(相比其他小字段), 使得内存利用率较差, 造成更多的随机读取. 优化思路:

1. 压缩 与 合并

1) 可以把大字段用 `COMPRESS()` 压缩后存储为 BLOB, 或者在发送到 MySQL 前在应用程序中进行压缩.

2) 一张表有多个 BLOB 字段, 把它们组合起来, 再压缩存储.

3) 如果预期长度范围 varchar 可以满足, 就避免使用 TEXT

2. 拆分

将主表拆分为一对一的两个关联表, 将大字段单独存放到另外一张表后, 单行长度变得非常小, page 的行密度比原来的表大很多,
这样就能缓存足够的的行, buffer pool 的命中率就会提高, 应用需要维护的是一张大字段的子表, 还可以通过覆盖索引来优化, 
将索引和源表结构分开, 从访问密度较小的数据页改为访问密度很大的索引页, 随机 io 转换为顺序 io

