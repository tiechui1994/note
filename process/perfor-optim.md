# 性能优化(一般操作操作过程)

## 分析系统瓶颈

系统响应慢, 首先得定位大致的问题出现在哪里, 是IO瓶颈, CPU瓶颈, 内存瓶颈还是程序导致的系统问题.

使用top工具可以比较全面的查看关注点:

```
top - 16:42:37 up  7:55,  1 user,  load average: 0.87, 0.79, 0.65
Tasks: 273 total,   1 running, 204 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.8 us,  0.3 sy,  0.0 ni, 98.7 id,  0.3 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem : 16285648 total,  8051696 free,  4471440 used,  3762512 buff/cache
KiB Swap:  9765884 total,  9765884 free,        0 used. 10834200 avail Mem 

  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                                                      
  958 root      20   0  476272 140184  99636 S   2.6  0.9  21:12.29 Xorg                                                         
 2271 user      20   0 1586228 206880  68952 S   2.0  1.3  19:53.52 compiz 
```

在交互模式下:
- 输入M, 进程列表按照内存使用大小降序排序
- 输入P: 进程列表按照CPI使用大小降序排序

top的%Cpu(s)参数关注点:
- %id: 空闲CPU时间百分比, 如果这个值过低, 表明系统CPU存在瓶颈
- %wa: 等等IO的CPU时间百分比, 如果这个估值过高, 表明IO存在瓶颈

## 分析内存瓶颈

进一步的监视内存使用情况, 可使用vmstat工具, 实时动态监视操作系统的内存和虚拟内存的动态变化.

## 分析IO瓶颈

如果IO存在性能瓶颈, top工具中的%wa会偏高;

进一步分析使用iostat工具: 

```
/root$iostat -d -x -k 1 1
Linux 2.6.32-279.el6.x86_64 (colin)   07/16/2014      _x86_64_        (4 CPU)

Device:   rrqm/s   wrqm/s     r/s     w/s    rkB/s    wkB/s avgrq-sz avgqu-sz   await  svctm  %util
sda         0.02     7.25    0.04    1.90     0.74    35.47    37.15     0.04   19.13   5.58   1.09
dm-0        0.00     0.00    0.04    3.05     0.28    12.18     8.07     0.65  209.01   1.11   0.34
dm-1        0.00     0.00    0.02    5.82     0.46    23.26     8.13     0.43   74.33   1.30   0.76
dm-2        0.00     0.00    0.00    0.01     0.00     0.02     8.00     0.00    5.41   3.28   0.00
```

- 如果 %await 的值过高, 表示硬盘存在I/O瓶颈.
- 如果 %util 接近 100%, 说明产生的I/O请求太多, I/O系统已经满负荷, 该磁盘可能存在瓶颈.
- 如果 svctm 比较接近 await, 说明 I/O 几乎没有等待时间; 
- 如果 await 远大于 svctm, 说明I/O 队列太长, io响应太慢, 则需要进行必要优化.
- 如果 avgqu-sz 比较大, 也表示有大量io在等待.

## 分析进程调用(重点)

通过top等工具发现系统性能问题是由某个进程导致的之后, 接下来我们就需要分析这个进程; 继续查询问题在哪;

这里有两个好用的工具: pstack和strace

pstack用来跟踪进程栈, 这个命令在排查进程问题时非常有用, 比如我们发现一个服务一直处于work状态(如假死状态, 好似死循环),
使用这个命令就能轻松定位问题所在; 可以在一段时间内, 多执行几次pstack, 若发现代码栈总是停在同一个位置, 那个位置就需要重
点关注,很可能就是出问题的地方;

```
$ pstack 7013
5776: /etc/factory/factory
(No symbols found in )
(No symbols found in /lib/x86_64-linux-gnu/librt.so.1)
(No symbols found in /lib/x86_64-linux-gnu/libc.so.6)
(No symbols found in /lib64/ld-linux-x86-64.so.2)
0x0045baa3: runtime.futex + 0x23 (122fc70, 100000000, ffffffffffffffff, ffffffffffffffff, 122f420)
0x0041114b: runtime.notesleep + 0x9b (122fc70, c420022000, 122f420)
0x00431985: runtime.stopm + 0xe5 (c420022000, 1, c420001600, 1, 100000000429856, 0) + 58
0x00432b62: runtime.findrunnable + 0x4d2 (c420022000, 0, c4234a2100, 7ffe434c0c10, 43c205, 122f420) + 8
0x0043361c: runtime.schedule + 0x12c (c420001680, 0, c420041f01, 100000000000004, 122f420)
0x00433936: runtime.park_m + 0xb6 (c420001680, 122f400, 7ffe434c0ca0, 122f420, 7ffe434c0c90, 4308d4) + ffff80c5dcb80ea0
0x004579db: runtime.mcall + 0x5b (c14890, 0, beb26f, 6, 18, 1) + 238
0x0043d369: runtime.selectgo + 0x1149 (c420041eb8, c4234a20e0, 0, 0, 0, 0) + 1c0
0x006bdce5: bizaddr.(*Arbiter).do.func1 + 0x395 (c4234200c0, c42341e7c0, 3, 3c, c4234a20e0, c4234a2150) + ffffff3bdffbe020
```

而strace用来跟踪进程中的系统调用; 这个工具能够动态的跟踪进程执行时的系统调用和所接收的信号, 是一个非常有效的检测, 
指导和调试工具. 系统管理员可以通过该命令容易地解决程序问题.

