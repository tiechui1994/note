--
-- 没有主键
--
DROP TABLE user;
CREATE TABLE user (
  name VARCHAR(10)
) engine=innodb;

INSERT INTO user VALUES('shenjian');
INSERT INTO user VALUES('shenjian');
SELECT *,1 FROM user;

--
-- 主键非空
-- Field id doesn't have a default value
--
DROP TABLE user;
CREATE TABLE user (
  id INT,
  name VARCHAR(10),
  PRIMARY KEY(id)
) engine=innodb;

INSERT INTO user (name) VALUES('shenjian');
INSERT INTO user (name) VALUES('shenjian');
SELECT *,2 FROM user;

--
-- 多个字段主键
--
DROP TABLE user;
CREATE TABLE user (
  id INT NOT NULL,
  name VARCHAR(10) NOT NULL,
  PRIMARY KEY(id,name)
) engine=innodb;

INSERT INTO user VALUES(1,'shenjian');
INSERT INTO user VALUES(1,'zhangsan');
INSERT INTO user VALUES(2,'shenjian');
SELECT *,3 FROM user;


--
-- 自增主键, auto_increment包含有not null
--
DROP TABLE user;
CREATE TABLE user (
  id INT auto_increment,
  name VARCHAR(10) NOT NULL,
  PRIMARY KEY(id)
) engine=innodb;

INSERT INTO user (name) VALUES('shenjian');
INSERT INTO user (id, name) VALUES(10, 'shenjian');
INSERT INTO user (name) VALUES('shenjian');
SELECT *,4 FROM user;

--
-- 联合自增主键
-- Incorrect table definition; there can be only one auto column and it must be defined as a key
--
DROP TABLE user;
CREATE TABLE user (
  id INT auto_increment,
  name VARCHAR(10) NOT NULL,
  PRIMARY KEY(name,id)
--   PRIMARY KEY(id,name)  success, (id,name) is primary key
) engine=innodb;

INSERT INTO user (name) VALUES('shenjian');
INSERT INTO user (id, name) VALUES(10, 'shenjian');
INSERT INTO user (name) VALUES('shenjian');
SELECT *,5 FROM user;