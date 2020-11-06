## 开发过程中的小技巧

### 查询进程id

- 查询条件: **进程命令**

```
# pgrep, pidof, CMD必须完整
pgrep CMD
pidof CMD

# ps
ps -ef | grep CMD
ps aux | grep CMD

# netstat
sudo netstat -anp | grep CMD

# pstree
pstree -p | grep CMD
```


### 查询端口号, 测试端口号是否监听

- 查询端口号, 查询条件: **进程命令**

```
# netstat
sudo netstat -anpl | grep CMD
```