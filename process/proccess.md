# Linux 进程优化

## 工具介绍

- 分析工具

![image](resource/analysis_tools.png)


- 基准测试工具
 
![image](resource/bechmark_tools.png)


- 观测工具

![image](resource/observation_tools.png)


- 观测工具 - sar

![image](resource/observation_sar.png)


---


## CPU

- top 显示系统总体的 CPU 和内存使用情况, 以及各个进程的资源使用情况.
- ps 显示每个进程的资源使用情况, 常用命令如 ps aux 、ps -ef 等.

### top

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


### pidstat

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

---


## 分析工具

### lsof

lsof(list open files)是一个列出当前系统打开文件的工具. 通过lsof工具能够查看这个列表对系统检测及排错,

常见的用法:

- 查看文件系统阻塞: lsof /boot
- 查看端口号被进程占用: lsof -i :3306
- 查看用户打开的文件: lsof -u <username>
- 查看进程打开的文件: lsof -p <pid>
- 查看远程已打开的网络链接: lsof -i @192.168.34.128
