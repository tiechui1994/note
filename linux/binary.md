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
/lib/x86_64-linux-gnu/libpam.so.0.83.1: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), 
dynamically linked, BuildID[sha1]=a2ae7b18e356a9433e3c9fae6b42d5c7a92d7140, stripped

> file /ect/passwd
/etc/passwd: ASCII text
```

### ldd

作用: 打印共享对象依赖关系

如果一个可执行文件上使用了上面的 `file` 命令, 肯定能够看到输出中的 `动态链接(dynamic linked)` 信息. 

在开发软件的时候, 尽量不要重复造轮子. 有一组常见的任务是大多数软件需要的, 比如打印输出或从标准输入/打开的文件中读取等.
这些常见的任务都被抽象成一组通用的函数, 然后每个人都可以使用, 而不是写出自己的变体. 这些常用的函数被放在一个叫 `libc`
或 `glibc` 的库中.

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

`ldd` 命令是找到可执行程序所依赖的库. 然而, 一个库可以包含数百个函数. 在这上百个函数中, 哪些是二进制程序正在使用的实际
函数?

`ltrace` 可以显示 `运行时` 从库中调用的所有函数. 下面的例子中, 可以看到被调用的函数名称, 以及传递给该函数的参数. 也可
以在输出的最右边看到函数的返回内容.

```
> ltrace pwd
__libc_start_main(0x401720, 1, 0x7ffe80d59d38, 0x404c60 <unfinished ...>
getenv("POSIXLY_CORRECT")                                                     = nil
strrchr("pwd", '/')                                                           = nil
setlocale(LC_ALL, "")                                                         = "en_US.UTF-8"
bindtextdomain("coreutils", "/usr/share/locale")                              = "/usr/share/locale"
textdomain("coreutils")                                                       = "coreutils"
__cxa_atexit(0x402440, 0, 0, 0x736c6974756572)                                = 0
getopt_long(1, 0x7ffe80d59d38, "LP", 0x405200, nil)                           = -1
getcwd(0, 0)                                                                  = ""
puts("/home/user"/home/user
)                                                                             = 11
free(0xdb8030)                                                                = <void>
__fpending(0x7efe30f30620, 0, 0x402440, 0x7efe30f30c70)                       = 0
fileno(0x7efe30f30620)                                                        = 1
__freading(0x7efe30f30620, 0, 0x402440, 0x7efe30f30c70)                       = 0
__freading(0x7efe30f30620, 0, 2052, 0x7efe30f30c70)                           = 0
fflush(0x7efe30f30620)                                                        = 0
fclose(0x7efe30f30620)                                                        = 0
__fpending(0x7efe30f30540, 0, 0x7efe30f31780, 0)                              = 0
fileno(0x7efe30f30540)                                                        = 2
__freading(0x7efe30f30540, 0, 0x7efe30f31780, 0)                              = 0
__freading(0x7efe30f30540, 0, 4, 0)                                           = 0
fflush(0x7efe30f30540)                                                        = 0
fclose(0x7efe30f30540)                                                        = 0
+++ exited (status 0) +++
```


### hexdump

作用: 以ASCII, 十进制, 十六进制 或 八进制显示文件内容.

通常情况下, 当使用应用程序打开一个文件, 而它不知道处理该文件时, 就会出现这种状况. 尝试使用 `vim` 打开一个可执行文件或者视频
文件, 会在屏幕上看到的只是抛出的乱码.

在 `hexdump` 中打开未知文件, 可以帮助你看到文件的具体内容. 


### strings

作用: 打印文件中的可打印字符的字符串.

如果只是在二进制中寻找可打印的字符, 那么 `hexdump` 就显得矫枉过正. 

在开发软件的时候, 各种文件/ASCII信息会被添加到其中, 比如打印的信息, 调试信息, 帮助信息, 错误信息等. 只要这些信息都存在于二进
制当中, 就可以使用 `strings` 命令将其转储到屏幕上.


### readelf

作用: 显示有关 ELF 文件的信息.

`ELF (Executable and Linked File Format)` 是可执行文件或二进制文件的主流格式, 不仅是 Linux 系统