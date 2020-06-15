# Linux 输出格式解析

## ps

```
> ps -aux|head -5
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.1 225240  9140 ?        Ss   19:02   0:04 /sbin/init splash
```

- USER, 用户
- PID, 线程pid
- %CPU, 进程使用的CPU
- %MEM, 进程使用的内存

- VSZ(Virtual Memory Size), 虚拟内存大小, 表示进程的虚拟内存. VSZ 包含了进程所能访问的所有内存, 包含了进入交换分区
的内存, 被分配但是还没有被使用的内存(堆内存和栈内存), 以及动态库中的内存.

- RSS(Resident Set Size), 常驻内存集, 表示该进程的内存大小(RAW中的物理内存). RSS 不包含进入交换分区的内存. RSS 
包含了它所链接的动态库并且被加载到物理内存中的内存, RSS 还包含栈内存和堆内存.

- TTY, terminal

- STAT, 表示当前进程的状态. 

> 进程状态:
> 
> - `D`, 不可中断的休眠(通常是IO)
> - `S`, 中断休眠(等待event的完成)
> - `I`, 空闲的内核线程
> - `R`, running 或 runnable (或在运行队列当中)
> - `T`, stopped by job control signal
> - `t`, stopped by debugger during the tracing
> - `X`, dead(永远也看不到)
> - `Z`, 僵尸进程, 进程已终止但未被其父级回收
>
> 对于 BSD 格式, 其他值:
> 
> - `<`, 高优先级
> - `N`, 低优先级
> - `L`, pages locked into memory(用于实时和自定义IO)
> - `s`, session leader
> - `l`, 多线程
> - `+`, 前台进程

- START, 命令启动的时间.
- TIME, 累计CPU时间
- COMMAND, 执行的命令

> 内存说明:

```
假设进程A的二进制文件是 500K, 并且链接了一个 2500K 动态库, 堆和栈共使用了 200K, 其中 100K 在内存中(剩下的被换出或
者不再被使用),  一共加载了动态库中 1000K 内容以及二进制文件中的 400K 内容至内存中, 那么:

RSS: 400K + 1000K + 100K = 1500K
VSZ: 500K + 2500K + 200K = 3200K

由于部分内存是共享的, 被多个进程使用, 所以如果将所有的 RSS 值加起来可能会大于系统的内存总量.

申请过的内存如果程序没有实际使用, 则可能不显示在 RSS 里.

```

## top

```
> top

1:Def - 22:33:27 up 11 min,  1 user,  load average: 0.99, 1.17, 0.87
Tasks: 211 total,   3 running, 208 sleeping,   0 stopped,   0 zombie
%Cpu(s): 57.4 us,  2.9 sy,  0.0 ni, 32.4 id,  7.4 wa,  0.0 hi,  0.0 si,  0.0 st
MiB Mem :   7857.5 total,   3617.7 free,   1861.3 used,   2378.5 buff/cache
MiB Swap:      0.0 total,      0.0 free,      0.0 used.   5431.9 avail Mem 

1  PID USER      PR  NI    VIRT    RES    SHR S  %CPU  %MEM     TIME+ COMMAND                                                           
 15223 root      20   0  117328  81260  60424 R 100.0   1.0   0:01.02 apt                                                               
 15250 root      20   0  117768  81352  60688 R 100.0   1.0   0:00.78 apt-get 
                                                           
2  PID  PPID     TIME+  %CPU  %MEM  PR  NI S    VIRT    RES   UID COMMAND                                                               
 15258 15042   0:00.01   6.2   0.2  20   0 S  660580  13884     0 lastore-tools                                                         
 15256  8903   0:00.01   6.2   0.0  20   0 R   44444   3768  1000 top         
                                                           
3  PID  %MEM    VIRT    RES   CODE    DATA    SHR nMaj nDRT  %CPU COMMAND                                                               
  8533  10.6 4855212 855084      4 1035480  83180  384    0   0.0 java                                                                  
  8004   2.4  833892 194180 151916  289584 138240    7    0   0.0 chrome  
                                                                
4  PID  PPID   UID USER     RUSER    TTY          TIME+  %CPU  %MEM S COMMAND                                                           
  6165  6150   998 www      www      ?          0:00.00   0.0   0.1 S nginx                                                             
     1     0     0 root     root     ?          0:03.05   0.0   0.1 S systemd                                                           
```

- PID, 进程pid
- USER, 进程执行的用户
- PR, 
- NI, 
- VIRT, 

- RES, 常驻内存大小(KB), 虚拟地址空间(VIRT) 的子集. 表示当前进程正在使用的未交换的物理内存.

- SHR, 共享内存大小(KB), 常驻内存(RES)的子集可能由其他进程使用. 它将包括"shared anonymous pages" 和 "shared 
file-backed pages". 它还包括映射到 "private pages" (包括程序镜像和共享库)
            
- S, 
- %CPU, 进程使用的CPU
- %MEM, 进程使用的内存
- TIME+/TIME, CPU时间, 任务自启动以来已使用的总CPU时间. 当"Cumulative mode(累积模式)"为"On"时, 将列出每个进程
及其子进程(dead)所使用的CPU时间. 可以使用 "S" 来切换累积模式, "S" 既是命令行选项又是交互式命令.

- COMMAND, 命令
- PPID, 进程的父进程
- CODE, 
- DATA, 
