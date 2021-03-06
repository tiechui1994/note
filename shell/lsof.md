## lsof 

lsof (list open files) 是一个查看当前系统文件的工具. 在 linux 环境下, 任何事物都以文件的形式存在, 筒骨文件不仅仅
可以访问到常规数据, 还可以访问网络连接和硬件. 如传输控制协议(TCP)和用户数据报协议(UDP)套接字等, 系统在后台都为应用程序
分配了一个文件描述符, 该文件描述符提供了大量关于这个应用程序本身的信息.

lsof 打开的文件可以是:

- 普通文件
- 目录
- 网络文件系统的文件
- 字符或设备文件
- (函数)共享库
- 管道
- 符号链接
- 网络文件(例如: NFS file, 网络socket, unix域名socket)
- 其他的文件, 等等.

lsof 输出各列信息的意义如下:

- COMMAND: 进程的名称
- PID: 进程标识符
- PPID: 父进程标识符 (需要指定-R参数)
- USER: 进程所有者
- PGID: 进程所属组

- FD: 文件描述符, 应用程序通过文件描述符识别该文件. 如cwd, txt等

```
1) cwd: current work directory, 即: 应用程序的当前工作目录, 这是该应用程序启动的目录.
2) txt, 该类型的文件是程序代码, 如应用程序二进制本身或共享库.
3) mem, memory-mapped file
4) mmap, memory-mapped device
5) pd, parent directory
6) rtd, root directory
7) 0: 标准输入
2) 1: 标准输出
3) 2: 标准错误
```

- TYPE: 文件类型, 如 DIR, REG, 常见的文件类型:

```
1) DIR: 目录
2) CHR: 字符类型
3) BLK: 块设备类型
4) UNIX: UNIX域套接字
5) FIFO: 先进先出FIFO队列
6) IPv4: 网际(IP)套接字
```

- DEVICE: 指定磁盘的名称
- SIZE: 文件的大小
- NODE: 索引节点(文件在磁盘上的标识)
- NAME: 打开文件的确切名称

命令参数:

- `-c <process>`, 列出指定进程所打开的文件. `<process>支持模糊匹配`
- `-d <fd>`, 列出占用该文件号的进程
- `+d <dir>`, 列出目录下被打开的文件
- `-p <pid>`, 列出指定进程号所打开的文件
- `-i <condition>`, 列出符合条件的进程. (4, 6, 协议, :端口, @ip), 可以使用多次
- `-r <sec>`, 每隔多少秒执行一次


#### 参考文档

- [lsof 一切皆文件](http://linuxtools-rst.readthedocs.io/zh_CN/latest/tool/lsof.html)
