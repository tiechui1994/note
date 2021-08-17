# MySQL 树类型结构表设计

mysql树类型的表的设计, 通常有以下四种:

- Adjacency List(邻接表): 每一条记录保存其 `parent_id`.
- Path Enumerations(路径枚举): 每一条记录保存整个tree path经过的node枚举.
- Nested Sets(嵌套集, 实质为双向链表): 每一条记录保存nleft和nright节点.
- Closure Table(闭包表): 维护一个表, 所有的tree path作为记录进行保存.

**操作代价对比:**

| Design | Tables | Query Child | Query Tree | Insert | Delete | Ref |
| ------ | ------ | ----------- | ---------- | ------ | ------ | --- |
| Adjacency List | 1 | Easy | Hard | Easy | Easy | Yes |
| Path Enumerations | 1 | Easy | Easy | Easy | Easy | No |
| Nested Sets | 1 | Hard | Easy | Hard | Hard | No |
| Closure Table | 2 | Easy | Easy | Easy | Easy | Yes |


## Adjacency List(邻接表)

表结构设计:

```
{
    id: int(10) unsigned primary key,
    parentid: int(10) unsigned,
    ...
}
```

特点: 

- 查询一个节点的直接后代和直接前代.
- 增加叶子节点
- 修改节点的位置简单


不足:

- 查询整棵树非常复杂
- 删除中间节点非常复杂


## Path Enumerations (路径枚举)

路径枚举是一个由连续的直接层级关系组成的完整路径.

表结构设计
```
{
    id: int(10) unsigned primary key,
    path: varchar(256),    // 路径, 保存的是祖先节点的信息(当然也可以包含自己)
    ...
}
```

特点:

- 查询方便
- 增加/删除叶子节点简单
- 修改节点方便


不足:

- 数据库不能确保路径的格式总是正确或者路径中的节点确实存在
- 树的深度有限制, 因而不能够支持树结构的无限扩展


## Nested Sets (嵌套集)

嵌套集解决方案是存储子孙节点的相关信息, 而不是节点的直接祖先. 使用两个数字来编码每个节点,
从而表示这一信息, 可以将这两个数字成为nleft和nright.

表结构设计:
```
{
    id: int(10) unsigned primary key,
    nleft: int,
    nright: int,
    ...
}
```

每个节点通过如下方式确定nleft和nright的值: nleft的数值小于该节点所有后代的id, 同时nright
的值大于该节点所有后代的id.

确定这三个值(nleft, id, nright)的简单方法是对树进行一次深度优先遍历, 再逐层深入的过程中
依次分配nleft的值, 并在返回时依次递增地分配nright的值.

[**具体详情参考**](./tree/tree_nested_set.md)

## Closure Table(闭包表)

闭包表的思路和路径枚举类似, 都是空间换时间.

Closure Table, 一种更为彻底的全路径结构, 分别记录路径上相关结点的全展开形式, 能明晰任意两结点关系
而无须多余查询, 级联删除和结点移动也很方便. 但是它的存储开销会大一些, 除了表示结点的Meta信息, 还需
要一张专用的关系表.

表结构设计如下

主表(node): 存储节点的信息
```
{
	id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
	name VARCHAR (255),
}
```

关系表(relation): 存储节点之间的关系
```
{
    ancestor INT NOT NULL, // 祖先节点
    child INT NOT NULL, // 后代节点
    distance INT NOT NULL, // 距离
    PRIMARY KEY (ancestor, child)
}
```

[**具体详情参考**](./tree/tree_closure_table.md)
