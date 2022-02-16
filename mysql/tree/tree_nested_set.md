# MySQL 树类型结构表 - 嵌套集 (Nested Sets)

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

一旦为每个节点分配了这些数值, 就可以使用它们来找到给定节点的祖先节点和后代.

计算案例如下:

![image](/images/mysql_tree_nested_picture.png)


![image](/images/mysql_tree_nested_stats.png)

例如: 获取id为4的所有后代

```sql
SELECT t2.*
FROM t as t1 JOIN t as t2 ON t2.nleft BETWEEN t1.nleft AND t1.nright
WHERE t1.id = 4;
```

例如: 获取id为6的所有祖先

```sql
SELECT t2.*
FROM t as t1 JOIN t as t2 ON t1.nleft BETWEEN t2.nleft AND t2.nright
WHERE t1.id = 6;
```

特点:

- 删除非叶子节点时, 它的后代会自动代替被删除的节点,成为其直接祖先节点的直接后代.


缺点:

- 获取一个节点的直接祖先或者直接后代, 在嵌套集的设计中会变得比较复杂. 

```
在嵌套集中, 如果需要查询一个节点的直接祖先, 思路: 给定节点node的直接祖先是这个节点的一个
祖先, 且这两个节点之间不应该有任何其他节点, 因此,可以使用递归的外联结来查询一个节点x, 它
既是node的祖先, 也同时是另外一个y节点的后代, 随后让y=x并继续查找, 直到查询返回空, 即不
存在这样的节点, 此时y便是c的直接祖先节点.
```


## 数据结构

嵌套集中, 使用新的视角看待树状结构. **不是使用节点或行, 而是使用嵌套容器**, 结构如下图
所示:

![image](/images/mysql_tree_nested_categories.png)


- 数据结构: category

```sql
CREATE TABLE category (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(20),
    nleft INT,
    nright INT
);

#插入元素
INSERT INTO category VALUES(1,'ELECTRONICS',1,20),(2,'TELEVISIONS',2,9),
(3,'TUBE',3,4), (4,'LCD',5,6),(5,'PLASMA',7,8),(6,'PORTABLE ELECTRONICS',10,19),
(7,'MP3 PLAYERS',11,14), (8,'FLASH',12,13),(9,'CD PLAYERS',15,16),
(10,'2 WAY RADIOS',17,18);
```

```
+----+----------------------+------+-------+
| id | name                 | nleft | nright |
+----+----------------------+------+-------+
| 1  | ELECTRONICS          |   1  |  20   |
| 2  | TELEVISIONS          |   2  |   9   |
| 3  | TUBE                 |   3  |   4   |
| 4  | LCD                  |   5  |   6   |
| 5  | PLASMA               |   7  |   8   |
| 6  | PORTABLE ELECTRONICS |  10  |  19   |
| 7  | MP3 PLAYERS          |  11  |  14   |
| 8  | FLASH                |  12  |  13   |
| 9  | CD PLAYERS           |  15  |  16   |
| 10 | 2 WAY RADIOS         |  17  |  18   |
+----+----------------------+------+-------+
```

下面是插入数据进行编号图:

![image](/images/mysql_tree_nested_numbered.png)

这种设计可以使用树状结构展示:

![image](/images/mysql_tree_nested_numbered_tree.png)

说明: 构建这种树需要从左向右, 每次一层的向下遍历其子节点, 对于叶子节点则指定其右值并移动到
其右边的兄弟节点. 这种算法: **深度优先遍历**

---

## 遍历整棵树

基于这样一个前提遍历整个树: 一个节点的左值总数处于父节点的左值和右值之间:

```sql
SELECT node.name
FROM category AS node, category AS parent
WHERE node.nleft BETWEEN parent.nleft AND parent.nright AND parent.name='ELECTRONICS'
ORDER BY node.nleft;
```

- 找出所有的叶子节点

叶子节点的左值和右值永远是连续的．

```sql
SELECT name 
FROM category
WHERE nright=nleft+1;
```

---

## 查询单一路径

- **sql语句:**

```sql
SELECT parent.name
FROM category AS node, category AS parent
WHERE node.nleft BETWEEN parent.nleft AND parent.nright AND node.name='FLASH'
ORDER BY parent.nleft;
```

---

## 获取节点深度

- **sql语句:**

```sql
SELECT node.name, (COUNT(parent.name)-1) AS depth
FROM category AS node, category AS parent
WHERE node.nleft BETWEEN parent.nleft AND parent.nright
GROUP BY node.name
ORDER BY node.nleft;
```

- **展示树的sql语句:[使用depth结合CONCAT以及REPEAT函数来在前面添加空格]**

```sql
SELECT CONCAT(REPEAT(' ', COUNT(parent.name)-1), node.name) AS name
FROM category AS node, category AS parent
WHERE node.nleft BETWEEN parent.nleft AND parent.nright
GROUP BY node.name
ORDER BY node.nleft;
```

---

## 子树的深度

- **sql语句:**

```sql
SELECT node.name (COUNT(parent.name) - (sub_tree.depth+1)) AS depth
FROM category AS node, 
     category AS parent, 
     category AS sub_parent,
     (
        SELECT node.name, (COUNT(parent.name)-1) AS depth
        FROM category AS node, category AS parent
        WHERE node.nleft BETWEEN parent.nleft AND parent.nright AND node.name='PORTABLE ELECTRONICS'
        GROUP BY node.name
        ORDER BY node.nleft
     ) AS sub_tree
WHERE node.nleft BETWEEN parent.nleft AND parent.nright AND 
      node.nleft BETWEEN sub_parent.nleft AND sub_parent.nright AND 
      sub_parent.name = sub_tree.name
GROUP BY node.name
ORDER BY node.nleft;
```

---

## 查找一个节点的直属子节点

- **sql语句:**

```sql
SELECT node.name, (COUNT(parent.name) - (sub_tree.depth + 1)) AS depth
FROM category AS node,
        category AS parent,
        category AS sub_parent,
        (
                SELECT node.name, (COUNT(parent.name) - 1) AS depth
                FROM category AS node,
                        category AS parent
                WHERE node.nleft BETWEEN parent.nleft AND parent.nright
                        AND node.name = 'PORTABLE ELECTRONICS'
                GROUP BY node.name
                ORDER BY node.nleft
        )AS sub_tree
WHERE node.nleft BETWEEN parent.nleft AND parent.nright
        AND node.nleft BETWEEN sub_parent.nleft AND sub_parent.nright
        AND sub_parent.name = sub_tree.name
GROUP BY node.name
HAVING depth <= 1
ORDER BY node.nleft;
```

---

## 添加节点

- **(添加兄弟节点)存储过程: [在 `TELEVISIONS` 和 `PORTABLE ELECTRONICS` 节点之间添加一个新的节点, 这个新的节点
的左值是10, 右值是11, 而它右边所有节点的值都应该加2.]**

```sql
LOCK TABLE category WRITE;

SELECT @r := nright FROM category WHERE name='TELEVISIONS';

UPDATE category SET nright = nright + 2 WHERE nright > @r;
UPDATE category SET nleft  = nleft  + 2 WHERE nleft  > @r;

INSERT INTO category (name, nleft, nright) VALUES('GAME CONSOLES', @r+1, @r+2);

UNLOCK TABLES;
```

- **(添加孩子节点)存储过程: [给 `2 WAY RADIOS` 添加一个叶子节点 `FRS`.]**

```sql
LOCK TABLE category WRITE;

SELECT @l := nleft FROM category WHERE name='2 WAY RADIOS';

UPDATE category SET nright = nright + 2 WHERE nright > @l;
UPDATE category SET nleft  = nleft  + 2 WHERE nleft  > @l;

INSERT INTO category (name, nleft, nright) VALUES('FRS', @l+1, @l+2);

UNLOCK TABLES;
```

- **添加节点, 展示树的存储过程:**

```sql
DELIMITER $$
DROP PROCEDURE IF EXISTS addNoChild;
CREATE PROCEDURE addNoChild(in parent varchar(64), in child varchar(64))
  BEGIN
    DECLARE l INT DEFAULT 0; /** 参数l **/
    DECLARE error INT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error=1; /** sql异常, 出错处理 **/

    /** 事物操作 **/
    SET autocommit = 0;
      SET l = (SELECT nleft FROM category WHERE name=parent);
      UPDATE category SET nright = nright + 2 WHERE nright > l;
      UPDATE category SET nleft  = nleft  + 2 WHERE nleft  > l;
      INSERT INTO category (name, nleft, nright) VALUES(child, l+1, l+2);

      IF error=1 THEN
        ROLLBACK;
      ELSE
        COMMIT;
      END IF;
    SET autocommit = 1;

  END $$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS addExistChild;
CREATE PROCEDURE addExistChild(in parent varchar(64), in child varchar(64))
  BEGIN
    DECLARE r INT DEFAULT 0; /** 参数r **/
    DECLARE error INT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error=1; /* sql异常, 出错处理 */

    /** 事物操作 **/
    SET autocommit = 0;
      SET r = (SELECT nright FROM category WHERE name=parent);
      UPDATE category SET nright = nright + 2 WHERE nright > r;
      UPDATE category SET nleft  = nleft  + 2 WHERE nleft  > r;
      INSERT INTO category (name, nleft, nright) VALUES(child, r+1, r+2);

      IF error=1 THEN
        ROLLBACK;
      ELSE
        COMMIT;
      END IF;
    SET autocommit = 1;
  END $$
DELIMITER ;


DELIMITER $$
DROP PROCEDURE IF EXISTS showTree;
CREATE PROCEDURE showTree()
  BEGIN
    SELECT CONCAT(REPEAT('  ', COUNT(parent.name)-1), node.name) AS name
    FROM category AS node, category AS parent
    WHERE node.nleft BETWEEN parent.nleft AND parent.nright
    GROUP BY node.name
    ORDER BY node.nleft;
  END $$
DELIMITER ;
```

---

## 删除节点

删除节点的行为取决于被删除节点在树状结构所处的层级, 删除叶子节点比删除子节点容易, 因为不需要考虑孤儿节点
的问题.

- **删除叶子节点:**

```sql
LOCK TABLE category WRITE;

SELECT @l := nleft, @r := nright, @w := nright - nleft + 1
FROM category
WHERE name = 'GAME CONSOLES';

DELETE FROM category WHERE nleft BETWEEN @l AND @r;

UPDATE category SET nright = nright - @w WHERE nright > @r;
UPDATE category SET nleft  = nleft  - @w WHERE nleft  > @r;

UNLOCK TABLES;
```

- **删除非叶子节点及其子节点:**

```sql
LOCK TABLE category WRITE;

SELECT @l := nleft, @r := nright, @w := nright - nleft + 1
FROM category
WHERE name = 'MP3 PLAYERS';

DELETE FROM category WHERE nleft BETWEEN @l AND @r;

UPDATE category SET nright = nright - @w WHERE nright > @r;
UPDATE category SET nleft  = nleft  - @w WHERE nleft  > @r;

UNLOCK TABLES;
```

- **删除非叶子节点, 保留其子节点:**

```sql
LOCK TABLE category WRITE;

SELECT @l := nleft, @r := nright, @w := nright - nleft + 1
FROM category
WHERE name = 'PORTABLE ELECTRONICS';

DELETE FROM category WHERE nleft = @l;

UPDATE category SET nright = nright - 1, nleft = nleft - 1 WHERE nleft BETWEEN @l AND @r;
UPDATE category SET nright = nright - 2 WHERE nright > @r;
UPDATE category SET nleft = nleft - 2 WHERE nleft > @r;

UNLOCK TABLES;
```
