## Postgre 索引

### Postgre 索引名称的唯一性

Postgres 当中要求, `index`(包含 `pkey`, `unique`, `index`), `sequence` 名称在数据库当中是唯一的.(如果使用已经
存在的索引名称创建新的索引, 则不会创建成功.)

查询 `index`, 使用的表是 `pg_indexes`, 当中包含了 'tablename', 'indexname', 'indexdef' 等信息.

查询 `sequence`, 使用的表是 `pg_sequences`, 其中包含了 'sequencename' 等信息.

> `pkey` 和 `unique` 本质上都是 "UNIQUE INDEX", 只是 pkey 是主键索引. 而 `unique` 是用户创建的唯一索引.

> 当主键索引当中包含 "自增" 的 "integer" 列时, 会创建相应的 sequence. 需要注意, 在 Postgres 当中, 一个表当中自增
列可以有多个.

当使用 `ALTER TABLE tb_old RENAME TO tb_new` 进行对表重命名时, 表内原有的 `index` 和 `sequence` 保持原样, 不
会随之改动.

Postgres 当中 'table', 'sequence', 'index' 重命名:

```sql
ALTER TABLE tb_old RENAME TO tb_new;

ALTER SEQUENCE seq_old RENAME TO seq_new;

ALTER INDEX idx_old RENAME TO idx_new;
```
