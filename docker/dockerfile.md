# Dockerfile 介绍

## 基本结构

Dockerfile 由一行行命令语句组成, 并且支持以 `#` 开头的注释行.

一般的, Dockerfile 分为四个部分: 基础镜像信息, 维护者信息, 镜像操作指令, 容器启动时执行指令.

```dockerfile
# base image, must be set as the first line.
FROM ubuntu:16.04

# maintainer info
MAINTAINER dockeruser dockeruser@email.com

# commands to operate 
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted" > /etc/apt/sources.list
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial universe" >> /etc/apt/sources.list
RUN echo "deb http://mirrors.aliyun.com/ubuntu/ xenial multiverse" >> /etc/apt/sources.list

RUN apt-get update && apt-get install -y nginx
RUN echo "\ndaemon off;" >> /etc/nginx/nginx.conf


# commands to start container
CMD /usr/sbin/nginx
```

## 指令

- FROM

格式:

```dockerfile
FROM <image>
FROM <image>:<tag>
```

>第一条指令必须是 `FROM` 指令. 并且, 如果在同一个Dockerfile中创建多个镜像时, 可以使用多个 `FROM` 指令(每个镜像一次).


- MAINTAINER

格式:

```dockerfile
MAINTAINER <name> 
```

> 指定维护者信息

- RUN

格式:

```dockerfile
RUN <command>
RUN ["executable", "param1", "param2"]
```

前者将在shell终端中运行命令, 即 `/bin/sh -c`; 后者则使用 `exec` 执行.
指定使用其他终端可以使用第二种方式实现. 例如 `RUN ["/bin/bash", "-c" "echo hello"]`.
每条 `RUN` 指令都将在当前镜像基础上执行指定命令, 并提交为新的镜像. 当命令较长时可以使用 `\` 来换行.

- CMD

格式:

```dockerfile
CMD ["executable", "param1", "param2"] # 使用 exec 执行, 推荐方式.
CMD command param1 param2  # 在/bin/sh中执行, 提供给需要交互的应用.
CMD ["param1", "param2"]  # 提供给 ENTRYPOINT 的默认参数.
```

指定启动容器时执行的命令, 每个 Dockerfile 只能有一条 `CMD` 命令. 如果指定多条, 只有最后一条会被执行.

如果用户启动容器时候指定了运行的命令, 则会覆盖掉 `CMD` 指定的命令.


- EXPOSE

格式:

```dockerfile
EXPOSE <port> [<port> ...]
```

告诉docker服务端容器暴露的端口号, 供互联系统使用. 在启动容器时需要通过 `-P`, Docker主机会自动分配一个端口
转发到指定的端口.


- ENV

格式:

```dockerfile
ENV <key> <value>
```

指定环境变量, 会被后续 `RUN` 指令使用, 并在容器运行时保持.


- ADD

格式:

```dockerfile
ADD <src> <dest>
```

复制指定的 `<src>` 到容器中的 `<dest>`. 其中 `<src>` 可以是Dockerfile所在目录的一个相对路径; 也可以是一个
url; 还可以是一个 tar 文件(自动解压为目录)


- COPY

格式:

```dockerfile
COPY <src> <dext>
```

复制本地主机的 `<src>` (为Dockerfile所在目录的相对路径) 到容器中的 `<dest>`. 

当使用本地目录为源目录时, 推荐使用 `COPY`.


- ENTRYPOINT

格式:

```dockerfile
ENTRYPOINT ["executable", "param1", "param2"]
ENTRYPOINT command param1 param2
```

配置容器启动后执行的命令, 并且不可被 `docker run` 提供的参数覆盖.

每个 Dockerfile 中只能有一个 `ENTRYPOINT`, 当指定多个时, 只有最后一个起效.


- VOLUME

格式: 

```dockerfile
VOLUME ["/data"]
```

创建一个可以从本地或其他容器挂载的挂载点, 一般用来存放数据库和需要保持的数据等.


- USER

格式: 

```dockerfile
USER daemon
```

指定运行容器时的用户名或UID, 后续的 `RUN` 也会使用指定用户.

当服务不需要管理员权限时, 可以通过该命令指定运行用户. 并且可以在之前所创建所需要的用户. 例如 `RUN groupadd -r 
postgres && useradd -r -g postgres postgres`. 要临时获取管理员权限可以使用 `gosu`, 而不推荐 `sudo`.



- WORKDIR

格式:

```dockerfile
WORKDIR /path/to/workerdir
```

为后续的 `RUN` `CMD` `ENTRYPOINT` 指令配置工作目录. 可以使用多个 `WORKDIR` 指令, 后续命令如果参数是相对路
径, 则会基于之前命令执行的路径. 


- ONBUILD

格式:

```dockerfile
ONBUILD [INSTRUCTION]
```

配置当所创建的镜像作为其他新创建镜像的基础镜像时, 所执行的操作命令.


案例:

```dockerfile
# [...]
ONBUILD ADD . /app/src
ONBUILD RUN /usr/local/bin/python-build --dir /app/src
# [...]
```


## 创建镜像

编写完成 Dockerfile 之后, 通过 `docker build` 命令来创建镜像.

格式:

```bash
docker build [选项] 路径
```

该命令将读取指定路径下(包括子目录)的Dockerfile, 并将该路径下所有的内容发送给Docker服务端, 由服务端来创建镜像.
因此一般建议放置 Dockerfile 的目录为空目录. 也可以通过 `.dockerigore` 文件(每一行添加一条匹配模式)来让Docker
忽略路径下的目录和文件.
