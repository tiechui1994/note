## 常识内容

### 查询pid

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


### 代理的分类

proxy 代理类型: 透明代理, 匿名代理, 高匿代理, 混淆代理. 常见的是前三种. 这4种代理, 主要是在代理服务器的配置不同, 导致
其向目标地址发送请求时, REMOTE_ADDR, HTTP_VIA, HTTP_X_FORWARDED_FOR 三个变量不同. 从安全角度, 高匿 > 混淆 > 匿
名 > 透明.

- 透明代理 (Transport Proxy)

```
REMOTE_ADDR = Proxy IP
HTTP_VIA = Proxy IP
HTTP_X_FORWARDED_FOR = Your IP
```

- 匿名代理 (Anonymous Proxy)

```
REMOTE_ADDR = Proxy IP
HTTP_VIA = Proxy IP
HTTP_X_FORWARDED_FOR = Proxy IP
```

- 混淆代理 (Distorting Proxy)

```
REMOTE_ADDR = Proxy IP
HTTP_VIA = Proxy IP
HTTP_X_FORWARDED_FOR = Random IP
```

- 高匿代理 (High Anonymity Proxy)

```
REMOTE_ADDR = Proxy IP
HTTP_VIA = not determined
HTTP_X_FORWARDED_FOR = not determined
```

高匿代理让别人根本无法发现你是在使用代理.

- 高度匿名代理不改变客户机的请求, 这样在服务器看来就像有个真正的客户浏览器在访问它, 这时客户的真实IP是隐藏的, 服务器不会
认为我们使用了代理.

- 普通匿名代理能隐藏客户机的真实IP, 但会改变请求的信息, 服务器端有可能会认为客户机使用了代理.

- 透明代理, 它不但改变了请求信息, 还会传送真实的IP地址.