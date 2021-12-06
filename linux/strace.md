# Linux 程序调试

## strace

系统调用追踪

格式:

```
strace [OPTIONS]  -p PID 
strace [OPTIONS]  [-D] [-E var=val]... [-u username] PROG [ARGS]
```

### 输出格式化 

- `-a column`, 对齐特定列中的返回值(默认列 40)

- `-o file`, 将跟踪输出写入文件 file 而不是 stderr. 如果提供了 -ff 选项, 则使用 file.pid 形式. 如果参数以'|' 或
'!' 开头, 参数的其余部分被视为命令, 所有输出都通过管道传输到它. 这便于将调试输出通过管道传送到程序, 而不会影响已执行程序
的重定向. 后者目前与 -ff 选项不兼容.


### 统计

- `-c`, 统计每个系统调用的时间, 调用次数和出现的错误. 并在程序退出的时候打印相关情况.

- `-C`, 与 `-c` 类似, 但是在运行时打印统计信息.

### 过滤

- `-e expr`, 一个限定性表达式, 用于过滤要追踪的事件. 表达式格式:

```
[qualifier=][!][?]value1[,[?]value2] ...
```

其中 qualifier 是 `trace`, `abbrev`, `verbose`, `raw`, `signal`, `read`, `write`, `fault` 或 `injection`.
value是与qualifier相关的符号或数字. 默认使用 `trace` 追踪. 例如, `-e open` 含义是 `-e trace=open`, 即只追踪open
系统调用. 

- `-e trace=set`, 追踪指定的系统调用. 例如, `trace=open,close,read,write` 表示只追踪这个四个系统调用. 默认值是
`trace=all`

- `-e trace=/regex`, 追踪正则匹配的系统调用.

- `-e trace=%file`, 追踪所有将文件名作为参数的系统调用. 这对于查看进程正在引用哪些文件很有用.

- `-e trace=%process`, 追踪所有涉及进程管理的系统调用. 这对于观察进程的 fork, wait 和 exec 很有用.

- `-e trace=%network`, 追踪所有网络相关的系统调用.

- `-e trace=%ipc`, 追踪所有IPC相关的系统调用.

- `-e trace=%memory`, 追踪所有内存映射相关的系统调用.

- `-e abbrev=set`, 缩写打印大型结构的每个成员的输出. 默认值为 `abbrev=all`. `-v` 选项具有 `abbrev=none` 的效果

### 追踪

- `-f`, 追踪子进程, 因为它们是由当前追踪的进程创建的, 作为fork, vfork 和 clone 系统调用的结果. 

> 注意: `-p PID -f` 将附加进程PID的所有线程(如果它是多线程的), 而不仅仅是具有 thread_id=PID的线程.

- `-ff`, 如果 `-o file` 选项有效, 则每个进程追踪都会写入file.pid, 其中pid是每个进程的进程id. 这与 `-c` 不兼容,
因为没有保留每个进程的计数.

- `-D`, 将追踪进程作为分离的grandchild运行, 而不是作为被追踪进程的父进程运行. 这通过将被追踪者保持为调用进程的直接子
进程来减少 strace 的可见性影响.


### 启动

- `-p pid`, 使用进程pid附加到进程并开始追踪. 追踪随时可以通过`CTRL-C`终止. strace将通过自身与被追踪进程分离, 使其
继续运行来做出响应. 除了命令之外, 还可以使用多个 `-p` 选项附加到多个进程.

- `-E var=value`, 将 `var=value` 添加到环境变量列表当中.

- `-E var`, 从环境变量列表当中移除 `var` 环境变量.

- `-u username`, 以 username 的身份运行命令
