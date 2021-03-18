## MySQL 常用的技巧

1. `GROUP BY` 后进行条件选择, 例如: 选择各科成绩最高的学生

```sql
SELECT a.score, a.name, a.courseid
FROM (
  SELECT max(score) as score, courseid
  FROM tscore 
  GROUP BY courseid
) temp INNER JOIN tscore ON temp.score=tscore.score AND temp.courseid=tscore.courseid
```

> 注意: 上面的语句的 sql_mode 的值当中不能包含 `ONLY_FULL_GROUP_BY`