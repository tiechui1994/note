## docker-compose 配置文件

基本格式:

```yaml
version: '3'
services:
    web:
      build: .
      ports: 
        - "5000:5000"
      volumes:
        - .:/code
      environment:
        FLASK_ENV: dev
      depends_on:
        - redis
    
    redis:
      image: "redis:4.0"
```

每个 docker-compose.yml 必须定义 `image` 或 `build` 中的一个, 其他的是可选的.

- image

指定镜像 tag 或者 ID.

```
image: redis
image: ubuntu:14.04
image:  example-registry.com:4000/postgresql
```

- build

用来指定一个包含 `Dockerfile` 文件的路径. 一般是当前目录 `.`.

```
build: .

build:
    context: .
    dockerfile: redis.Dockerfile
    args:
        buildno:1
```

> context: 可以是 `Dockerfile` 的路径, 或者是指向 `git` 仓库的 url.
>
> dockerfile: 备用 `Dockerfile`, 需要替换默认 Dockerfile 的文件名
>
> args: 为构建(build)过程中的环境变量, 用于替换 Dockerfile 里定义的 ARG 参数, 容器中不可用.


- command

用来覆盖缺省命令.

```
command: bundle exec thin -p 3000

command: [bundle, exec, thin, -p, 3000]
```

- env_file

从文件中获取环境变量, 可以为单独的文件路径或列表. 如果通过 `docker-compose -f FILE` 指定了模板文件, 则 `env_file`
中路径会给予模板文件路径. 如果有变量名称与 `environment` 指令冲突, 则以后者为准.

```
env_file: .env

env_file:
    - ./common.env
    - ./apps/web.env
```

> 环境变量文件中每一行必符合格式, 支持 `#` 开头的注释行

```
# common.env
ENV = dev
```

- links

用于链接另一容器服务, 例如, 需要使用到另一容器的 `mysql` 服务. 可以给出服务名和别名; 也可以仅给出服务名, 这样别名和服
务名相同.

```
links:
    - db
    - db:mysql
    - redis
```

- ports

暴露端口

```
ports:
    - "3000"
    - "8000:8000"
    - "9002:22"
```

> 冒号前面是 `主机上的端口`, 冒号后面的是 `容器内部的端口`.


- expose

提供 container 之间的端口访问, 不会暴露给主机使用.

```
expose:
    - "3000"
    - "8000"
```

- volumes

装载路径或命名卷(可选)指定主机上的路径(`HOST:CONTAINER`) 或 访问模式(`HOST:CONTAINER:ro`).

```
volumes:
    - /var/lib/mysql
    - /opt/data:/var/lib/mysql
    - ~/configs:/etc/configs:ro
    - datavolume: /var/lib/mysql
```

- volumes_from

从另一个服务或容器装入所有卷, 可选择指定只读访问(`ro`) 或 读写(`rw`). 如果未指定访问级别, 则将使用读写.

```
volumes_from:
    - service_name
    - service_name:ro
    - container:container_name
    - container:container_name:rw
```

- cpu_shares, cpu_quota, cpuset, domainname, ipc, mac_address, mem_limit, memswap_limit, privilege,
oom_score_adj, read_only, restart, shm_size, stdin_open, tty, user, wordking_dir

每个都是一个单独的值. 

```
cpu_shares: 73
cpu_quota: 50000
cpuset: 0,1

user: postgresql
working_dir: /code

domainname: foo.com
hostname: foo
ipc: host
mac_address: 02:42:ac:11:65:43

mem_limit: 1000000000
memswap_limit: 2000000000
privileged: true

oom_score_adj: 500

restart: always

read_only: true
shm_size: 64M
stdin_open: true
tty: true
```

- cgroup_parent

为容器指定可选的父cgroup

```
parent_cgroup: m-executor
```

- container_name

指定自定义容器名称, 而不是生成的默认名称.

```
container_name: web
```

- depends_on

容器之间的依赖关系. 有两个作用:

>- `docker-compose up` 将按照依赖顺序启动服务. 下面案例, db和redis在web之前启动.
>
>- `docker-compose up SERVICE`, 将自动包含 SERVICE 的依赖关系. 下面案例, `docker-compose up web` 也将创建
>并启动 db 和 redis

```yaml
version: '3'
services:
    web:
      build: .
      depends_on:
        - db
        - redis
    
    redis:
      image: redis
    
    db:
      image: postgres
```


- extends

在当前文件或另一个文件中扩展另一个服务, 可选地覆盖配置.

`extends` 值必须是使用必须的 `service` 和 可选 `file` 字段定义的字典.

```
extends:
    file: common.yml
    service: web
```

`service` 是正在扩展的服务的名称. 例如, `web` 或 `mysql`. 

`file` 是定义正在扩展服务的compose配置文件的路径. 如果省略, 则从当前的文件中查找服务配置.


- logging

日志服务的配置.

```
logging:
    driver: syslog
    options:
        syslog-address: "tcp://127.0.0.1:123"
```

> driver 名称指定了服务器容器的日志驱动程序. 如 `docker` 运行的 `--log-driver` 选项. 从 `json-file`, `syslog`,
> `journald`, `none` 当中选择其一. 默认值是 `json-file`.
> 
>>只有 `json-file` 和 `journald` 驱动程序使日志可以之间从 `docker-compose up` 和 `docker-compose logs`获取.
>>使用任何其他驱动程序都讲不会打印任何日志.
> 



