# MySQL 中的 COLLATE 关键字

MySQL 中使用 COLLATE 来指定非二进制字符串列(例, VARCHAR, CHAR, TEXT类型)的排序规则. **简而言之,
COLLATE 会影响到ORDER BY语句的顺序, 会影响到 WHERE 条件中大于小于号筛选的结果, 会影响 DISNCT,
GROUP BY, HAVING 语句的查询结果.** 另外, MySQL建索引的时候, 如果索引是字符类型, 也会影响索引的创建.
总之, 凡是涉及到字符串类型比较或排序的地方, 都会和 COLLATE 有关.

## 各种 COLLATE 的区别

COLLATE 通常是和数据编码 (CHARSET) 相关的, 一般来说每种 CHARSET 都有多种它支持的 COLLATE, 并且每
种 CHARSET 都指定一种 COLLATE 为默认值. 例如, Latin1 编码的默认 COLLATE 是 latin1_swedish_ci,
GBK 编码的默认 COLLATE 是 gbk_chinese_ci, utf8mb4 编码的默认 COLLATE 是 utf8mb4_general_ci

> mysql 中有 `utf8` 和 `utf8mb4` 两种编码, 推荐使用 `utf8mb4`. 这是mysql的一个遗留问题, mysql中
的 `utf8` 最多只能支持 3bytes 长度的字符编码, 对于一些需要占据 4bytes 的文字, mysql 的 `utf8` 就不支
持了, 要使用 `utf8mb4` 才可以.


COLLATE 中 `ci` (Case Insensitive) 后缀, 即大小写无关.  `ca` (Case Sensitive), 即大小写敏感.