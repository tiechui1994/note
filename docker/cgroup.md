## cgroup

文档: https://access.redhat.com/documentation/zh-cn/red_hat_enterprise_linux/7/html-single/resource_management_guide/index


Linux CGroup 是 Linux 内核的一个功能, 用来限制, 控制与分离一个进程组群的资源(
CPU,内存,磁盘输入输出等).

功能如下:

- Resource limitation: 限制资源使用, 比如内存使用上限以及文件系统的缓存限制.
 
- Prioritization: 优先级控制, 比如: CPU利用和磁盘IO吞吐.

- Accounting: 一些审计或一些统计, 主要目的是为了计费.

- Control: 挂起进程, 回复执行进程.

使用CGroup, 系统管理员可以更具体地对系统资源的分配, 优先顺序, 拒绝, 管理和监控.

CGroup 内容:

```
quinn@master:~$ lssubsys -m
cpuset /sys/fs/cgroup/cpuset
cpu,cpuacct /sys/fs/cgroup/cpu,cpuacct
blkio /sys/fs/cgroup/blkio
memory /sys/fs/cgroup/memory
devices /sys/fs/cgroup/devices
freezer /sys/fs/cgroup/freezer
net_cls,net_prio /sys/fs/cgroup/net_cls,net_prio
perf_event /sys/fs/cgroup/perf_event
hugetlb /sys/fs/cgroup/hugetlb
pids /sys/fs/cgroup/pids
rdma /sys/fs/cgroup/rdma
```

### 案例

1.CPU限制

- CPU使用率限制: 
cpu.cfs_quota_us (-1表示无限制, 20000表示20%的CPU利用率)

- CPU核限制
cpuset.cpus (2,3 限制CPU只能使用#2核和#3核)


2.内存使用限制

- 内存大小限制
memory.limit_in_bytes (内存大小限制)

3.磁盘IO限制

- 磁盘IO限制读限制
blkio.throttle.read_bps_device (8:0 1048576 第一个字段表示设备号, 第二个字段表示读取的速度,单位是bps)

> 设备号可以通过 ls -l /dev/sda 查询

### CGroup 子系统

- blkio 块设备设定输入/输出限制. 比如物理设备(磁盘, 固态硬盘, USB等)

- cpu 使用调度程序提供对CPU的cgroup任务访问.

- cpuacct 自动生成cgroup中任务所使用的CPU报告

- cpuset 为cgroup中的任务分配独立CPU(多核系统)和内存节点

- devices 允许或者拒绝cgroup中的任务访问设备

- freezer 挂起或者恢复cgroup中的任务

- memory 设定cgroup中任务使用的内存限制, 并自动生成内存资源使用报告

- net_cls 使用等级识别符号(classid) 标记网络数据包, 可允许Linux流量控制程序(tc)识别从具体cgroup
中生成的数据包.

- net_prio 用来设计网络流量的优先级

- hugetlb 主要针对HugeTLB系统进行限制, 这是一个大页文件系统.


术语

- 任务(Tasks): 就是系统的一个进程

- 控制组(Control Group): 一组按照某种标准划分的进程, 其表示了某个进程组. Cgroups中的资源
控制都是以控制组为单位实现. 一个进程可以加入到某个控制组. 而资源的限制是定义在这个组上. 简单来
说, cgroup的呈现就是一个目录带一系列的可配置文件.

- 层级(Hierarchy): 控制组可以组织成hierarchical的形式, 即一棵控制组的树(目录结构). 控制
组树上的子节点继承父节点的属性. 简单说, Hierarchy就是在一个或多个子系统上的cgroup目录树.

- 子系统(Subsystem): 一个子系统就是一个资源控制器, 比如CPU子系统就是控制CPU时间分配的一个控
制器. 子系统必须附加到一个层级上才能起作用, 一个子系统附加到某个层级以后, 这个层级上所有控制族
群都受到这个子系统的控制.


### cgroup 层级

cgroup 的默认层级

默认情况下, systemd会自动创建slice, scope和service单位的层级, 来为cgroup提供统一结构. 使用systemctl
指令, 通过创建自定义slice进一步修改此结构.

systemd自动为/sys/fs/cgroup目录中重要的kernel资源管理器挂载层级.


systemd的单位类型:

系统中运行的所有进程, 都是systemd init 进程的子进程. 在资源管理方面, systemd提供了三种单位类型.

- service 一个或一组进程, 由systemd依据单位配置文件启动. service对指定进程进行封装, 这样进程可以作为
一个整体被启动或终止.

- scope 一组外部创建的进程. 由强制进程通过 `fork()` 函数启动和终止, 之后被systemd在运行时注册的进程. 
scope会将其封装. 例如: 用户会话, 容器和虚拟机被认为是scope.

- slice 一组按层级排列的单位. slice并不包含进程, 但会组建一个层级, 并将scope和service都放置其中. 真
正的进程包含在scope或service中. 在这一被划分层级的树中, 每一个slice单位的名字对应通向层级中一个位置的路
径. 横线("-")起分离路径组件的作用.

例如: 如果一个slice的名字是:
```
parent-name.slice
```
这说明parent-name.slcie是parent.slice的一个子slice. 这一子slice可以再拥有自己的slice, 被命名为:
parent-name-name2.slice, 以此类推.

根slice的表示方式:
```
-.slice
```

service, scope和slice单位直接映射到cgroup树中的对象. 当这些单位被激活, 它们会直接一一映射到由单位名创建
的cgroup路径中.

service, scope和slice是由系统管理员手动创建或者由程序动态创建的. 默认情况下, 操作系统会定义一些运行系统必
要的内置service. 另外, 默认情况下, 系统会创建四种slice:

- -.slice 根slice
- system.slice 所有系统service的默认位置
- user.slice 所有用户会话的默认位置
- machine.slice 所有虚拟机和Linux容器的默认位置


service 和 slice 单位可通过中的永久单位文件来配置; 或者对 PID 1 进行 API 调用, 在运行时动态创建. 

scope 单位只能以API调用的方式来创建. 

API 调用动态创建的单位是临时的, 并且仅在运行时存在. 一旦结束, 被关闭或者系统重启, 临时单位会被自动释放.


### 使用控制群组

通过将 cgroup 层级系统与 systemd 单位树捆绑, Red Hat Enterprise Linux 7 可以把资源管理设置从
进程级别移至应用程序级别. 因此, 可以使用 systemctl 指令, 或者通过修改 systemd 单位文件来管理系统资
源.

创建控制群组:

从systemd的角度来看, cgroup 会连接到一个系统单位, 此单位可用单位文件进行配置, 用systemd命令进行管
理. 根据应用的类型, 资源管理设定可用是transient(临时的) 或者 persistent(永久的)

要为服务创建 transient cgroup, 使用 **systemd-run** 指令启动此服务. 如此, 可用限制此服务在运行时
所用资源. 对systemd进行API调用, 应用程序可用动态创建临时cgroup.


要为服务创建 persistent cgroup, 需要编写配置文件. 系统重启之后, 此项配置会被保留, 所以它可用用于管理
自动启动的服务. 

> 注意: scope 单位不能以此方式创建

systemd-run: 

```
systemd-run --unit=NAME --scope --slice=SLICE command
```

- NAME 表示被识别的名称. 如果 --unit 没有被指定, 单位名称会自动生成. 建议选择一个描述性的名字.

- 使用可选的 --scope 参数创建临时单位来替代默认创建的service单位

- --slice选项, 让新创建的service或scope单位可以称为指定slice的一部分. 用现存slice(systemctl -t slice
输出所示)的名字替代SLICE, 或者通过一个独有的名字创建新slice

- command代表在service单位中运行的命令. 将此命令放置于systemd-run语句的最末端.

- 其他选项: --description可以创建单位的描述; service进程结束后, --remain-after-exit可以收集运行时信息;
--machine 选项可以在密闭容器中执行指令.

```
# systemd-run --unit=toptest --slice=test --description='top test' top -b
Running as unit: toptest.service
```


永久cgroup:

若要在系统启动时，配置一个自动启动的单位， systemctl enable 指令. 自动运行在/etc/systemd/system目录下创建
的单位文件. 


