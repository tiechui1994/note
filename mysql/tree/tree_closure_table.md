# Closure Table(闭包表)

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



## 插入节点

- **插入数据:使用存储过程**

```sql
DELIMITER $$
DROP PROCEDURE IF EXISTS addnode;
CREATE PROCEDURE addnode(in parent_name varchar(255), in node_name varchar(255))
BEGIN
	DECLARE _child INT;
	DECLARE _parent INT;
	IF NOT EXISTS(SELECT id From node WHERE name = node_name)
	THEN
	  /** insert node **/
		INSERT INTO node (name) VALUES(node_name);
		SET _child = (SELECT id FROM node WHERE name = node_name);
		INSERT INTO relation (ancestor,child,distance) VALUES(_child,_child,0);

		/** insert relation node and parent **/
		IF EXISTS(SELECT id FROM node WHERE name = parent_name)
		THEN
			SET _parent = (SELECT id FROM node WHERE name = parent_name);
			INSERT INTO relation (ancestor,child,distance) SELECT ancestor,_child,distance+1 FROM relation WHERE child=_parent;
		END IF;
	END IF;
END $$
DELIMITER ;
```


**数据库数据**

```
select * from node;                                                                                                       
+----+--------+
| id | name   |
+----+--------+
| 1  | Food   |
| 2  | Fruit  |
| 3  | Red    |
| 4  | Cherry |
| 5  | Yellow |
| 6  | Banana |
| 7  | Meat   |
| 8  | Beef   |
| 9  | Pork   |
+----+--------+

select * from relation;                                                                                                                                      
+----------+-------+----------+
| ancestor | child | distance |
+----------+-------+----------+
| 1        | 1     | 0        |
| 1        | 2     | 1        |
| 1        | 3     | 2        |
| 1        | 4     | 3        |
| 1        | 5     | 2        |
| 1        | 6     | 3        |
| 1        | 7     | 1        |
| 1        | 8     | 2        |
| 1        | 9     | 2        |
| 2        | 2     | 0        |
| 2        | 3     | 1        |
| 2        | 4     | 2        |
| 2        | 5     | 1        |
| 2        | 6     | 2        |
| 3        | 3     | 0        |
| 3        | 4     | 1        |
| 4        | 4     | 0        |
| 5        | 5     | 0        |
| 5        | 6     | 1        |
| 6        | 6     | 0        |
| 7        | 7     | 0        |
| 7        | 8     | 1        |
| 7        | 9     | 1        |
| 8        | 8     | 0        |
| 9        | 9     | 0        |
+----------+-------+----------+
```

## 查询节点

- **查询所有子节点: (以Fruit为例)**

祖先节点id -(relation)-> 子节点id,且距离非0 -(node)-> 子节点信息 

```sql
SELECT n.name
FROM node 
INNER JOIN relation r ON node.id = r.ancestor
INNER JOIN node n ON r.child = n.id
WHERE node.name = 'Fruit' AND r.distance != 0
```

- **查询直属子节点: (以Fruit为例)**

祖先节点id -(relation)-> 子节点id,且距离是1 -(node)-> 子节点信息 

```sql
SELECT n.name
FROM node
INNER JOIN relation r ON node.id = r.ancestor
INNER JOIN node n ON r.child = n.id
WHERE
	node.name = 'Fruit' AND r.distance = 1
```

- **查询节点所处的层级: (以Pork为例子)**

子节点id -(relation)-> 祖先节点id -(node)-> 子节点信息 

```sql
SELECT r.*, n.name
FROM node
INNER JOIN relation r ON node.id = r.child
INNER JOIN node n ON r.ancestor = n.id
WHERE node.name = 'Pork'
ORDER BY r.distance DESC
```

## 删除节点

- **删除节点,(所有的子节点全部被删除)**

```sql
DELIMITER $$
DROP PROCEDURE IF EXISTS delnode;
CREATE PROCEDURE delnode(in node_name varchar(255))
BEGIN
    DECLARE _id INT;
    DECLARE error INT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error=1; /* sql异常, 出错处理 */

    SET autocommit = 0;
      /** 删除以当前节点为祖先的关联关系 **/
      DELETE FROM relation WHERE ancestor IN (
        SELECT n.id
        FROM node 
        INNER JOIN relation r ON node.id = r.ancestor
        INNER JOIN node n ON r.child = n.id
        WHERE node.name = node_name
      );
      
      /** 删除所有子节点 **/
      DELETE FROM node WHERE id IN (
        SELECT n.id
        FROM node 
        INNER JOIN relation r ON node.id = r.ancestor
        INNER JOIN node n ON r.child = n.id
        WHERE node.name = node_name
      );
      
      IF error=1 THEN
        ROLLBACK;
      ELSE
        COMMIT;
      END IF;
    SET autocommit = 1;

END $$
DELIMITER ;
```

- **删除节点,(但是节点的子节点不删除)**

```sql
DELIMITER $$
DROP PROCEDURE IF EXISTS delnode;
CREATE PROCEDURE delnode(in node_name varchar(255))
BEGIN
    DECLARE _id INT;
    DECLARE error INT;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET error=1; /* sql异常, 出错处理 */

    SET autocommit = 0;
      SET _id = (SELECT id FROM node WHERE name = node_name);
      
      /** 更新子节点与祖先节点的距离 **/
      UPDATE relation INNER JOIN (
        SELECT * FROM (
          SELECT ancestor,child
          FROM relation
          WHERE child IN(
            SELECT n.id
            FROM node
            INNER JOIN relation r ON node.id=r.ancestor
            INNER JOIN node n ON r.child=n.id
            WHERE node.name=node_name
          ) AND distance >= 2) AS temp
      ) r ON r.ancestor = relation.ancestor AND r.child = relation.child SET distance = distance-1;
      
      /** 删除以当前节点为祖先节点的关系和当前节点 **/
      DELETE FROM relation WHERE ancestor=_id;
      DELETE FROM node WHERE name = node_name;
      
      IF error=1 THEN
        ROLLBACK;
      ELSE
        COMMIT;
      END IF;
    SET autocommit = 1;

END $$
DELIMITER ;
```
