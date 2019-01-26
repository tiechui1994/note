# mysql当中树类型结构表的设计

mysql树类型的表的设计, 通常有以下四种:

- Adjacency List(链表): 每一条记录保存其 `parent_id`.
- Path Enumerations(路径枚举): 每一条记录保存整个tree path经过的node枚举.
- Nested Sets(嵌套集, 实质为双向链表): 每一条记录保存left和right节点.
- Closure Table(闭包表): 维护一个表, 所有的tree path作为记录进行保存.

**操作代价对比:**

| Design | Tables | Query Child | Query Tree | Insert | Delete | Ref |
| ------ | ------ | ----------- | ---------- | ------ | ------ | --- |
| Adjacency List | 1 | Easy | Hard | Easy | Easy | Yes |
| Path Enumerations | 1 | Easy | Easy | Easy | Easy | No |
| Nested Sets | 1 | Hard | Easy | Hard | Hard | No |
| Closure Table | 2 | Easy | Easy | Easy | Easy | Yes |

