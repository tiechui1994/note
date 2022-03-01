DROP PROCEDURE IF EXISTS init;
CREATE PROCEDURE init()
BEGIN
  TRUNCATE TABLE t;
  INSERT INTO t VALUES(0,0,0), (5,5,5), (10,10,10), (15,15,15), (20,20,20), (25,25,25);
END;;


DROP PROCEDURE IF EXISTS idata;
CREATE PROCEDURE idata()
BEGIN
  DECLARE i INT;
  SET i = (SELECT MAX(id) FROM t1)+1;
  while i<=1000 DO
    insert into t1 values(i, 1001-i, i),(i+1, 1001-(i+1), i+1),(i+2, 1001-(i+2), i+2),(i+3, 1001-(i+3), i+3);
    SET i=i+4;
  end while;

  SET i = (SELECT MAX(id) FROM t2)+1;
  while i<=1000000 DO
    insert into t2 values (i, i, i), (i+1,i+1,i+1), (i+2,i+2,i+2), (i+3,i+3,i+3), (i+4,i+4,i+4),
      (i+5, i+5, i+5), (i+6,i+6,i+6), (i+7,i+7,i+7), (i+8,i+8,i+8), (i+9,i+9,i+9);
    SET i=i+10;
  end while;
END;;