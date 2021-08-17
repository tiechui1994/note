# COLLATE

MySQL 中使用 COLLATE 来指定非二进制字符串列(例, VARCHAR, CHAR, TEXT类型)的排序规则. **简而言之, COLLATE 会影响
到ORDER BY语句的顺序, 会影响到 WHERE 条件中大于小于号筛选的结果, 会影响 DISNCT, GROUP BY, HAVING 语句的查询结果.** 
另外, MySQL建索引的时候, 如果索引是字符类型, 也会影响索引的创建. 总之, 凡是涉及到字符串类型比较或排序的地方, 都会和 
COLLATE 有关.

## 各种 COLLATE 的区别

COLLATE 通常是和数据编码 (CHARSET) 相关的, 一般来说每种 CHARSET 都有多种它支持的 COLLATE, 并且每种 CHARSET 都指
定一种 COLLATE 为默认值. 例如, Latin1 编码的默认 COLLATE 是 latin1_swedish_ci, GBK 编码的默认 COLLATE 是 
gbk_chinese_ci, utf8mb4 编码的默认 COLLATE 是 utf8mb4_general_ci

> mysql 中有 `utf8` 和 `utf8mb4` 两种编码, 推荐使用 `utf8mb4`. 这是mysql的一个遗留问题, mysql中的 `utf8` 最多
只能支持 3bytes 长度的字符编码, 对于一些需要占据 4bytes 的文字, mysql 的 `utf8` 就不支持了, 要使用 `utf8mb4` 才
可以.

COLLATE 中 `ci` (Case Insensitive) 后缀, 即大小写无关.  `ca` (Case Sensitive), 即大小写敏感.

在MySQL中使用 `show collation` 可以查看MySQL所支持的所有的 COLLATE.

在国内比较常用的是 `utf8mb4_general_ci` (默认), `utf8mb4_unicode_ci`, `utf8mb4_bin` 这三个. 三者的区别是:

- 首先, `utf8mb4_bin` 的比较方法其实就是直接将所有字符看作二进制串, 然后从最高位往最低位比对. 所以它是区分大小写的.

- 其次, `utf8mb4_unicode_ci` 和 `utf8mb4_general_ci` 对中文和英文来说, 其实是没有任何区别的. 只是对某些西方国
家的字母来说, `utf8mb4_unicode_ci` 会比 `utf8mb4_general_ci` 更符合他们的语言习惯一些, `general` 是 MySQL 
一个比较老的标准. 例如, 德语字母 `ß`, 在 `utf8mb4_unicode_ci` 中等价于 `ss` 两个字母的(这是符合德国人习惯的做法), 
而在 `utfmb4_general_ci` 中, 它却和字母 `s` 等价.

## COLLATE 设置级别及其优先级

设置 COLLATE 可以在实例级别, 库级别, 表级别, 列级别, 以及SQL指定. 实例级别的 COLLATE 设置就是 MySQL 配置文件或者启
动指令中的 `collation_connection` 系统变量.


库级别设置 COLLATE 的语句如下:

```sql
CREATE DATABASE db DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE DATABASE db DEFAULT CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;

CREATE DATABASE db DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

> MySQL8.0 以下的版本中, 默认的 CHARSET 是 Latin1, 默认的 COLLATE 是 latin1_swedish_ci. MySQL8.0开始, 默认
的 CHARSET 是 utf8mb4, 默认的 COLLATE 是 utf8mb4_0900_ai_ci.


表级别的 COLLATE 设置:

```sql
CREATE TABLE t(
  ...
) ENGIN=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

列级别的 COLLATE 设置:

```sql
CREATE TABLE t (
  c1 VARCHAR(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  c2 VARCHAR(32) CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  ...   
) ...
```

> 说明: `CHARACTER SET` 和 `CHARSET` 是等价的
