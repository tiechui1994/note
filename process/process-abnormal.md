# 进程异常的处理思路(CPU使用率过高)

## CPU使用率查看

- top 显示系统总体的 CPU 和内存使用情况, 以及各个进程的资源使用情况.
- ps 显示每个进程的资源使用情况, 常用命令如 ps aux 、ps -ef 等.

**top:**

```
top - 21:05:55 up  4:47,  1 user,  load average: 0.00, 0.00, 0.00
Tasks: 255 total,   1 running, 254 sleeping,   0 stopped,   0 zombie
%Cpu(s):  0.1 us,  0.1 sy,  0.0 ni, 99.7 id,  0.1 wa,  0.0 hi,  0.0 si,  0.0 st
KiB Mem :   985888 total,    71740 free,   606652 used,   307496 buff/cache
KiB Swap:  1046524 total,   709116 free,   337408 used.   169712 avail Mem 

   PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND                                                                                                                                 
  1039 root      20   0  527548  87584  18984 S   2.0  8.9   0:50.74 Xorg    
```

参数说明:
Tasks: 运行的运行任务统计信息

%Cpu(s): 系统CPU使用情况
```
us, user: 运行非niced用户进程的时间
sy, system: 运行内核进程的时间
ni, nice: 运行niced用户进程的时间
id, idle: 内核处于空闲的时间
wa, IO-wait: 等待IO完成的时间
hi: 硬中断的时间
si: 软终端的时间
st: 从虚拟内存加载到内存花费的时间
```

KiB Mem: 系统内存使用情况(总量, 未使用, 已使用, 缓存)
```
total: 总安装内存(从操作系统来看, OS的物理内存)
free: 可用量(从操作系统来看, OS还有可用的物理内存)
used: 使用量(从操作系统来看, OS使用了的物理内存)

buff/cached: 被OS cached的内存
avail Mem: 可用内存(从用户角度来看, 系统可用使用的内存)
```

其中可用内存计算公式: **can use = free + buff/cached + avail Mem**

KiB Swap: 系统交换空间使用情况


**pidstat:**

主要是查看CPU使用率.

```
# 每隔1秒输出一组数据, 共输出5组
$ pidstat 1 5
15:56:02      UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
15:56:03        0     15006    0.00    0.99    0.00    0.00    0.99     1  dockerd
```

参数:

%usr: 用户态CPU使用率
 
%system: 内核态CPU使用率

%guest: 运行虚拟机CPU使用率

%wait: 等待CPU使用率

%CPU: 总CPU使用率

```
安装: sudo apt install sysstat
```

## 解决方案

perf 是更好的选择, 它内置于Linux 2.6.31之后的版本,主要通过性能事件采样, 分析系统的各种事件和内核性能,
且可以用来分析指定程序的性能问题.

关于 perf, 就不做过多介绍了, 详细内容可参考man手册, 在此只提供一种使用perf分析CPU性能问题的用法 -- 
perf top, 它的表现形式类似于top, 不同的是, perf top能够实时显示占用 CPU 时钟最多的函数或指令, 因
此可以用来定位高频函数, 形式如下图所示:

注: perf安装方法, sudo apt install linux-tools-common

```
$ perf top
Samples: 729  of event 'cpu-clock', Event count (approx.): 72684182
Overhead  Shared Object       Symbol
   8.04%  perf                [.] 0x00000000003b6210
   5.13%  [kernel]            [k] vsnprintf
   4.67%  [kernel]            [k] module_get_kallsym
   4.01%  [kernel]            [k] _raw_spin_unlock_irqrestore
   ...
```

参数: 

Samples: 采样数

Event: 事件类型

Event count: 事件总数

指标:

Overhead: 该符号的性能事件在所采样中所占比例;

Shared: 该函数或指令所属对象, 如内核(kernel), 进程, 动态库, 模块等;

Object: 表示对象的类型, 如`[.]`表示用户空间的可执行程序或动态库, `[k]`表示内核空间;

Symbol: 符号名, 即函数名, 当函数名未知时, 用十六进制的地址表示


## 总结

- 用户 CPU 使用率高, 说明用户态进程占用 CPU 较多, 所以应该重点排查进程性能问题;
- 系统 CPU 使用率高, 说明内核态占用较多 CPU, 所以应该重点排查内核线程或系统调用的性能问题;
- 中断 CPU 使用率高, 说明中断处理程序占用较多 CPU, 所以应该重点排查内核中的中断服务函数;



