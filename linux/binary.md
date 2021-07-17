## 二进制文件查看

### file

作用: 帮助确定文件类型

这是进行二进制分析的起点.

```
> file /bin/ls
/bin/ls: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), dynamically linked, 
interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 2.6.32, 
BuildID[sha1]=d0bc0fb9b3f60f72bbad3c5a1d24c9e2a1fde775, stripped

> file /lib/x86_64-linux-gnu/libpam.so.0.83.1 
/lib/x86_64-linux-gnu/libpam.so.0.83.1: ELF 64-bit LSB shared object, x86-64, 
version 1 (SYSV), 
dynamically linked, BuildID[sha1]=a2ae7b18e356a9433e3c9fae6b42d5c7a92d7140, 
stripped

> file /ect/passwd
/etc/passwd: ASCII text
```

### ldd

作用: 二进制文件共享对象依赖关系

如果一个可执行文件上使用了上面的 `file` 命令, 肯定能够看到输出中的 `动态链接(dynamic linked)` 信息. 

在开发软件的时候, 尽量不要重复造轮子. 有一组常见的任务是大多数软件需要的, 比如打印输出或从标准输入, 打开的文件中读取等. 这些
常见的任务都被抽象成一组通用的函数, 然后每个人都可以使用, 而不是写出自己的变体. 这些常用的函数被放在一个叫 `libc` 或 `glibc` 
的库中.

如何找到可执行程序所依赖的库? 这就是 `ldd` 命令的作用了. 对动态链接的二进制文件运行该命令会显示出所有依赖库和它们的路径.

```
> ldd /bin/ls
	linux-vdso.so.1 =>  (0x00007ffc9adf7000)
	libselinux.so.1 => /lib/x86_64-linux-gnu/libselinux.so.1 (0x00007f5330522000)
	libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f5330158000)
	libpcre.so.3 => /lib/x86_64-linux-gnu/libpcre.so.3 (0x00007f532fee8000)
	libdl.so.2 => /lib/x86_64-linux-gnu/libdl.so.2 (0x00007f532fce4000)
	/lib64/ld-linux-x86-64.so.2 (0x00007f5330744000)
	libpthread.so.0 => /lib/x86_64-linux-gnu/libpthread.so.0 (0x00007f532fac7000)
```

### ltrace

作用: 库调用跟踪器

`ldd` 命令是找到可执行程序所依赖的库. 然而, 一个库可以包含数百个函数. 在这上百个函数中, 哪些是二进制程序正在使用的实际函数?

`ltrace` 可以显示 `运行时` 从库中调用的所有函数. 下面的例子中, 可以看到被调用的函数名称, 以及传递给该函数的参数. 也可以在
输出的最右边看到函数的返回内容.

```
> ltrace pwd
__libc_start_main(0x401720, 1, 0x7ffe80d59d38, 0x404c60 <unfinished ...>
getenv("POSIXLY_CORRECT")                                    = nil
strrchr("pwd", '/')                                          = nil
setlocale(LC_ALL, "")                                        = "en_US.UTF-8"
bindtextdomain("coreutils", "/usr/share/locale")             = "/usr/share/locale"
textdomain("coreutils")                                      = "coreutils"
__cxa_atexit(0x402440, 0, 0, 0x736c6974756572)               = 0
getopt_long(1, 0x7ffe80d59d38, "LP", 0x405200, nil)          = -1
getcwd(0, 0)                                                 = ""
puts("/home/user"/home/user
)                                                            = 11
free(0xdb8030)                                               = <void>
__fpending(0x7efe30f30620, 0, 0x402440, 0x7efe30f30c70)      = 0
fileno(0x7efe30f30620)                                       = 1
__freading(0x7efe30f30620, 0, 0x402440, 0x7efe30f30c70)      = 0
__freading(0x7efe30f30620, 0, 2052, 0x7efe30f30c70)          = 0
fflush(0x7efe30f30620)                                       = 0
fclose(0x7efe30f30620)                                       = 0
__fpending(0x7efe30f30540, 0, 0x7efe30f31780, 0)             = 0
fileno(0x7efe30f30540)                                       = 2
__freading(0x7efe30f30540, 0, 0x7efe30f31780, 0)             = 0
__freading(0x7efe30f30540, 0, 4, 0)                          = 0
fflush(0x7efe30f30540)                                       = 0
fclose(0x7efe30f30540)                                       = 0
+++ exited (status 0) +++
```

### hexdump

作用: 以ASCII, 十进制, 十六进制 或 八进制显示文件内容.

通常情况下, 当使用应用程序打开一个文件, 而它不知道处理该文件时, 就会出现这种状况. 尝试使用 `vim` 打开一个可执行文件或者视
频文件, 会在屏幕上看到的只是抛出的乱码.

在 `hexdump` 中打开未知文件, 可以帮助你看到文件的具体内容. 

### strings

作用: 打印文件中的可打印字符的字符串.

如果只是在二进制中寻找可打印的字符, 那么 `hexdump` 就显得矫枉过正. 

在开发软件的时候, 各种文件/ASCII信息会被添加到其中, 比如打印的信息, 调试信息, 帮助信息, 错误信息等. 只要这些信息都存在于二
进制当中, 就可以使用 `strings` 命令将其转储到屏幕上.

### readelf

作用: 显示有关 ELF 文件的信息.

`ELF (Executable and Linked File Format)` 是可执行文件或二进制文件的主流格式, 不仅是 Linux 系统, 也是各种 UNIX 
系统的主流文件格式. 如果已经使用了像 `file` 命令这样的工具, 它告诉你文件的格式是 ELF 格式, 那么下一步就是使用 `readelf` 
命令和它的各种选项来进一步分析文件.

```
> readelf -h /bin/ls
ELF 头：
  Magic：  7f 45 4c 46 02 01 01 00 00 00 00 00 00 00 00 00 
  类别:                              ELF64
  数据:                              2 补码，小端序 (little endian)
  版本:                              1 (current)
  OS/ABI:                            UNIX - System V
  ABI 版本:                          0
  类型:                              DYN (共享目标文件)
  系统架构:                          Advanced Micro Devices X86-64
  版本:                              0x1
  入口点地址：              0x56d0
  程序头起点：              64 (bytes into file)
  Start of section headers:          132936 (bytes into file)
  标志：             0x0
  本头的大小：       64 (字节)
  程序头大小：       56 (字节)
  Number of program headers:         9
  节头大小：         64 (字节)
  节头数量：         29
  字符串表索引节头： 28 
```

### strace

作用: 跟踪系统调用和信号.

`lstrace` 和 `strace` 唯一的区别是, `strace` 工具不是追踪调用的库, 而是 `追踪系统调用`.

举个例子, 如果想要把一些东西打印到屏幕上, 会使用标准库 `libc` 中的 `printf` 或 `puts` 函数; 但是, 在底层, 最终会有一个
名为 `write` 的系统调用来实际把东西打印到屏幕上.
 
一个 nginx 的 worker 进程:

```
> sudo strace -p 6022
strace: Process 6022 attached
epoll_wait(8, [{EPOLLIN, {u32=3055601136, u64=94883178137072}}], 512, -1) = 1
accept4(6, {sa_family=AF_INET, sin_port=htons(45104), sin_addr=inet_addr("127.0.0.1")}, [112->16], SOCK_NONBLOCK) = 3
epoll_ctl(8, EPOLL_CTL_ADD, 3, {EPOLLIN|EPOLLRDHUP|EPOLLET, {u32=3055601617, u64=94883178137553}}) = 0
epoll_wait(8, [{EPOLLIN, {u32=3055601136, u64=94883178137072}}], 512, 60000) = 1
accept4(6, {sa_family=AF_INET, sin_port=htons(45106), sin_addr=inet_addr("127.0.0.1")}, [112->16], SOCK_NONBLOCK) = 11
epoll_ctl(8, EPOLL_CTL_ADD, 11, {EPOLLIN|EPOLLRDHUP|EPOLLET, {u32=3055601857, u64=94883178137793}}) = 0
epoll_wait(8, [{EPOLLIN, {u32=3055601617, u64=94883178137553}}], 512, 60000) = 1
recvfrom(3, "GET / HTTP/1.1\r\nHost: 127.0.0.1\r"..., 1024, 0, NULL, NULL) = 622
stat("/opt/local/nginx/html/index.html", {st_mode=S_IFREG|0644, st_size=417, ...}) = 0
openat(AT_FDCWD, "/opt/local/nginx/html/index.html", O_RDONLY|O_NONBLOCK) = 12
fstat(12, {st_mode=S_IFREG|0644, st_size=417, ...}) = 0
writev(3, [{iov_base="HTTP/1.1 304 Not Modified\r\nServe"..., iov_len=180}], 1) = 180
write(5, "127.0.0.1 - - [11/May/2020:20:53"..., 182) = 182
close(12)                               = 0
setsockopt(3, SOL_TCP, TCP_NODELAY, [1], 4) = 0
epoll_wait(8, 
```

## strace 用法

```
strace [-CdffhiqrtttTvVwxxy] [-I n] [-e expr]...
       [-a column] [-o file] [-s strsize] [-P path]...
       -p pid... / [-D] [-E var=val]... [-u username] PROG [ARGS]

or
    
strace -c[dfw] [-I n] [-e expr]... [-O overhead] [-S sortby]
       -p pid... / [-D] [-E var=val]... [-u username] PROG [ARGS]

```

Output format:
  -a column      在特定列 (默认列是40) 中对齐返回值.
  
  -k             在每个系统调用之后 (实验的) 打印被跟踪进程的执行堆栈跟踪. 仅当使用 `libunwind` 构建strace时, 
                 此选项才可用.
                 
  -o file        将跟踪输出到 FILE 而不是stderr
  -s strsize     指定要打印的最大字符串大小(默认为32). 请注意, 文件名不视为字符串, 并且始终完整打印.
  
  -r             打印相对时间戳
  -t             打印绝对时间戳
  -tt            打印带有纳秒的绝对时间戳
  -T             打印每个syscall的调用时间
  
  -x             以十六进制打印非ASCII字符串
  -xx            以十六紧张打印所有的字符串
  
  -y             与 `文件描述符` 关联的打印 `路径`
  -yy            与 `套接字文件描述符` 关联的打印 `协议特定信息`

Statistics:
  -c             计算每个系统调用的时间, 调用和错误, 并报告摘要(常规输出被禁止)
  -C             像 `-c` 一样, 也可以打印常规输出
  -S sortby      对系统调用统计信息排序: `time`, `calls`, `name`, `nothing` (default time)

Filtering:
  -e expr        表达式: `option=[!]all or option=[!][?]val1[,[?]val2]...`, 其中 option 是 
  `trace`, `abbrev`, `verbose`, `raw`, `signal`, `read`, `write`, `fault`, `inject` 之一. 
  而 val 是 `限定的符号` 或 `数字`. 默认的 `option` 是 `trace`. 使用 `!` 表示区反. 例如, `-e open` 
  等效于 `-e trace=open`, 表示跟踪 `open` 系统调用. 相反的, `-e trace=!open`, 表示跟踪除了 `open` 
  之外的系统调用. 如果没有系统调用与提供的条件匹配, 则系统调用条件之前的 `?` 允许运行抑制错误. 除此之外, 
  特殊值 `all` 和 `none` 没有明显的含义.
  
  
  -e trace=set 仅追踪指定的系统调用集合. 例如, trace=open,close,read,write 表只追踪这四个系统调用. 
  如果仅监视一部分系统调用, 则在推断 user/kenel 边界的时候要小心. 默认值是 trace=all
  
  -e trace=%file, 跟踪所有以文件名作为参数的系统调用. 可以将其视为 `-e trace=open,stat,chmod,unlink,...`
  的缩写, 这对于查看进程所引用的文件很有用. 此外, 使用缩写将确保不会意外忘记在列表中包括 `lstat` 之类的调
  用.
  
  -e trace=%process
  -e trace=%network
  -e trace=%signal
  -e trace=%ipc
  -e trace=%desc
  -e trace=%memory
  -e trace=%stat
  
  -P path        跟踪对路径的访问

Tracing:
  -b syscall     如果达到指定的系统调用, 请与跟踪的进程分离. 当前, 仅支持 `execve syscall`. 如果要跟踪
  多线程进程并因此需要 `-f`, 但又不想跟踪其(可能非常复杂的)子级, 则此选项很有用.
  
  -D             作为独立的 grandchild 而不是作为示踪 parent 运行跟踪程序进程. 
  
  -f             跟踪子进程, 这些子进程是由 `fork, vfork, 和 clone` 系统调用导致当前跟踪的进程创建的. 
  注意, 如果 `-p PID -f` 是多线程的, 则它将附加进程PID的所有线程, 而不仅限于 `thread_id=PID` 的线程.
  
  -ff            如果 `-o filename` 选项有效, 则将每个进程跟踪写入 `filename.pid`, 其中pid是每个进程
  的数字进程ID. 这与 -c 不兼容, 因为不保留每个进程的计数.
  

Startup:
  -E var         针对执行的命令, 环境变量var移除
  -E var=val     针对执行的命令, 设置环境变量 var 的值为 val 
  -p pid         追踪 pid 是 PID 的进程
  -u username    以 username 用户身份运行命令

Miscellaneous:
  -d             允许 debug 信息输出到 stderr
  -v             详细模式: 打印未缩写的 `argv`, `stat`, `termios`等. args