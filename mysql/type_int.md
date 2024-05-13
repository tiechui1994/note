## MySQL 类型 - 值

对于整数类型(int), M 表示最小显示宽度. 最大显示宽度为 255. 显示宽度与类型可以存储的值的范围无关.

对于浮点(float)和定点数据(fixed)类型, M 是可以存储的总位数.

> 如果为数字列指定 ZEROFILL, MySQL 会自动向该列添加 UNSIGNED 属性.

- `BIT[(M)]`, M 表示每个值的位数, `1` 到 `64`, 如果省略, 默认值是 1. 插入有范围限制.

- `BOOL`, 与 `TINYINT(1)` 具有相同的含义.

- `TINYINT[(M)] [UNSIGNED] [ZEROFILL]`, signed 范围是 `-2^7-1` 到 `2^7-1`, unsigned 区间是 `0` 到 `2^8-1`

- `SMALLINT[(M)] [UNSIGNED] [ZEROFILL]`, signed 范围是 `-2^15-1` 到 `2^15-1`, unsigned 区间是 `0` 到 `2^16-1`

- `MEDIUMINT[(M)] [UNSIGNED] [ZEROFILL]`, signed 范围是 `-2^31-1` 到 `2^31-1`, unsigned 区间是 `0` 到 `2^32-1`

- `INT[(M)] [UNSIGNED] [ZEROFILL]`, signed 范围是 `-2^63-1` 到 `2^63-1`, unsigned 区间是 `0` 到 `2^64-1`

- `BIGINT[(M)] [UNSIGNED] [ZEROFILL]`, signed 范围是 `-2^127-1` 到 `2^127-1`, unsigned 区间是 `0` 到 `2^128-1`

- `FLOAT[(M,D)] [UNSIGNED] [ZEROFILL]`, 单精度浮点数. M 是总位数, D 是小数点后的位数. 单精度浮点数大约精确到小
数点后7位

- `DOUBLE[(M,D)] [UNSIGNED] [ZEROFILL]`, 双精度浮点数. M 是总位数, D 是小数点后的位数. 单精度浮点数大约精确到小
数点后15位

