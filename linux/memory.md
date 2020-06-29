# Linux 下的内存管理

[参考文档](https://github.com/Durant35/durant35.github.io/issues/24)

程序内存地址 => 虚拟内存 => 物理内存


## Linux 虚拟内存和物理内存的理解

1.每个进程的4G内存空间是虚拟内存空间, 每次访问内存空间的某个地址, 都需要把地址翻译为实际物理内存地址.

2.所有进程共享同一物理内存, 每个进场只把自己目前需要的虚拟内存空间映射并存储到物理内存上.

3.进场要知道哪些内地址上的数据在物理内存上, 哪些不在, 还有在物理内存上的那些, 需要用 `页表` 来记录.

> 页表的每一个表项分两部分: 第一部分记录此页是否在物理内存上, 第二部分记录物理内存页的地址(如果存在)

4.当进程访问某个虚拟地址时, 去查询页表, 如果发现对应的数据不在物理内存中, 则产生 `缺页中断`.

> 缺页中断的处理过程, 就是把进程需要的数据从磁盘上拷贝到物理内存中, 如果内存已经满了, 没有空地方联动, 那就找一个页进行
> 覆盖, 当然如果被覆盖的页曾经被修改过, 需要讲此页写回磁盘.

![image](resource/mem_overwrite.png)


> **优点:**
> 
> - 既然每个进程的内存空间都是一致且固定的, 所以 *链接器在链接可执行文件时, 可以设定内存地址*, 而不用去管这些数据最终
> 实际的内存地址, 这是有独立内存空间的好处.
> - 当不同的进程使用同样的代码时, 比如库文件的代码, *物理内存中可以只存储一份*这样的代码, 不同的进场只需要把自己的虚拟
> 内存映射过去就可以了, 节省内存.
> - 当程序*需要分配连续的内存空间*的时候, 只需要在虚拟内存空间分配连续空间, 而不需要实际物理内存的连续空间, 可以利用碎
> 片.


## 处理器内核(软核)是否带有 MMU 单元

> MMU (内存映射单元), 通常是CPU的一部分, **本身有少量的存储空间**来存放从虚拟地址到物理地址的查找表; 所有数据请求都
> 送往MMU, 由MMU决定数据是在RAM内还是在大容量存储设备内; 也能将用用程序的执行对应到不同虚拟内存的空间中, 让操作系统提
> 供内存保护.

### MMU 功能

- 在 Linux 的运行环境中, MMU是必不可少的重要单元. 如果没有MMU对 memory 进行管理, 那么操作吸引面对的是单一的物理地址,
如果地址线是32位, 那么操作系统能够管理的只有 4 GB 空间, 正是引入 MMU:

> - 操作系统可使用虚拟地址来进行映射
> - MMU 的地址翻译和地址保护

- Linux 操作系统在运行过程中, 会涉及虚拟地址到物理地址的转换, 这就是 MMU 功能模块完成的任务.

### MMU 工作原理

- 如果软件需要控制 MMU, 需要通过系统内部的协处理器对某些寄存器进行读操作, 来获取MMU的状态; 通过向某些寄存器发起写操作
来控制 MMU 的操作

- MMU 单元可以提供全面的内存管理(`执行多任务程序需要的地址装换和权限检查`), 因此多用户应用程序可以在这个 CPU 内核的支
持下运行.

- 在打开 MMU 功能模块后, 它对数据池和指令池发出的地址称为虚拟地址:

> - 在内存中找到该地址域对应的转换页, 把虚拟地址的高位部分替换, 形成可以访问内存, 寄存器的物理地址.
> - 在这些`转换页`中, 有对该部分地址域限定的权限信息. 结合处理器的当前状态, 这些转换页提供的权限信息即可让处理器判断此
> 次的读写访问是否合法:
> 1.如果合法, 处理器会在存储空间中按照物理地址进行读写操作
> 2.如果非法, 处理器会发出数据访问或指令读取异常标志, 这些标志信号将引导处理器进入异常中断向量中.

- 现代操作系统普遍采用虚拟内存管理机制, 这需要MMU的支持. MMU 通常是CPU的一部分, 如果处理器没有MMU, 或者`有MMU但没有
启用`, **CPU执行单元发出的内存地址将直接传到芯片引脚上**, 被`内存芯片(物理内存)`接收, 这里的地址称为物理地址. 如果
处理器启用了 MMU, **CPU执行单元发出的内存地址将被MMU截获**, 从 CPU 到 MMU 的地址称为虚拟地址. 而MMU将这个地址翻
译成另一个地址发送到CPU芯片的外部地址引脚上, 也就是将虚拟地址转换为物理地址.

![image](resource/mmu.png)


## 硬件页表 vs 软件页表

- `现在Linux内核是 4 级页表结构, 3级页表结构的时代是10年前了`.

- X86_64 架构下, 无论是 Intel 还是 AMD 的 CPU, 都是4级的硬件页表, 所以软件层面的页表至少要 4 级(否则, 进程访问的
空间将受限, 因为有一级虚拟页表被固定住了, 3级页表, X86_64只能访问 512 GB 空间, 4级页表, X86_64的可访问空间达到了
31072(2^47)GB)

- i386 只有三级硬件页表: PUD -> PMD -> PTE. `怎么嵌入四级页表结构? 答案是虚设一级`

> - 用户空间虚拟地址, 按照上述的四级进行翻译
> - 内核空间虚拟地址是所有进场共享的, 重要的是, 从效率角度看, 如果同样走四级页表翻译的流程, 速度太慢. 于是, 内核初始化
> 时, 就创建内核空间的映射(因为所有进程共享, 有一份就足够了), 并且, `采用线性映射`, 而不是走页表翻译这种类似哈希表的方
> 式.
> - `为什么用户空间不能也像内核空间这么做`? 用户地址空间是随进场创建才产生的, 它的页面可能散步在不同的物理内存中, 无法
> 这么做. 另外, 走页表的过程, 不止是翻译的过程, 还是一个权限检查的过程, 对于不可控的用户态地址, 这样的安全性检查必不可
> 少. 而内核空间, 只有一份, 所有可以提前固定下来一片连续的物理地址空间, 按线性方法映射 (按前面的线性方法, 1G内核空间,
> 只能映射1G物理地址空间, 这对内核来说, 太掣肘了; Linux内核只对1G内核空间的前 896 M 按前面所说的方法线性映射, 剩下的
> 128M 的内核空间 `[高端内存]`, 采用动态映射的方式, 即按需映射的方式, 这样内核态的访问空间更多了).

## 几级页表 + MMU

### Linux 内存管理

- 以32位的系统来说, 对于 4GB 的虚拟内存, 系统要怎样来管理该内存呢? 一般就是采用所谓的 `分页机制`, 就是把这么大的内存
按照每一页的大小分成很多页, 内存的管理也就是以页作为单位, 而不是以字节作为单位.

> 4GB 的地址, 如噶按照每一页 4K 大小计算的话, 那么总共需要的页数为 2^20, 这时就需要一个页目录来存储这些页的信息, 以
> 便查找. `每一个页项存储的就是对应页的内存起始地址`, 每一项的大小为 32bit (4B), 页目录所需要的内存大小为 2^20*4B
> 也就是4MB的大小

- 对于进程来说 一般不会使用这么大的内存空间, 加上程序对内存的访问具有局部性, 这样的话, 就会出现很多的页表项不会被用到,
也就是程序所需要的页数很少. 如果一直将所有的页目录存储在内存的话(4MB), 或造成很大的内存浪费, 此时就出现了多级页表了.

> - 以二级页表来说, 将总的页目录按照页的大小(4KB) 划分, 总共需要的二级页数为 4MB/4KB=1K, 此时引入一级页表, 用来存
> 储二级页表的信息, 那么每一个一级页表项的大小为4B, 所需要的一级页表大小为 4KB.
>
> - 进程在运行的时间, 只需要先读取一级页表,接着再根据对二级页表以及内存页进行配置, 可以大大减少页的索引信息了.


- 对于一个线性地址(虚拟地址), 内存怎样把它映射为对应的物理地址呢?

> - 在二级页表下, 一级页的大小为 4KB, 也就是对应 1K 的二级页表, 索引要索引二级页表, 需要将虚拟地址的高10位用来作作为
> 一级页表的表内偏移索引
>
> - 通过一级页表的表内偏移索引找到二级页表后, 二级页表也有1K的页数, 所以需要虚拟地址中的低10位作为二级索引页表的表内偏
> 移索引
>
> - 在得到对应的物理地址页地址的时候,由于每一页有4K大小, 想要找到具体的字节地址, 那么需要12位的索引, 也就是32位地址剩
> 下的低12位. 这样就完成了一个虚拟地址到实际物理地址的映射
>
> - 对于一级页表, 其起始地址要怎样存储?
>
> 1) 一般的话, 由于起始地址是一个4B的指针, 可以存储在寄存器上
> 2) 每次进程运行的时候, 每一个进程都有字节的一级页表起始地址, 当进程被加载运行的时候, 操作系统为其分配的一级页表地址就
> 直接存在CR3寄存器中, 这样开始了进程的虚拟地址访问.

- 完成虚拟地址到物理地址的转换一般是 MMU (Memory Management Unit)硬件来实现的.  为了实现更快的转换, 就有了 TLB (
Transaction Lock-aside Buffer),  用来根据程序访问内存的局部性机制来缓存已经转换过的虚拟页与实际页的对应关系!

> - TLB中包含了最近使用过的页面的内存映射信息, 处理器提供了专门的电路来并发地读取并比较TLB的页面映射项.
>
> - 对于频繁使用的虚拟地址, 它们很可能在 TLB 中对应有对应的映射项, 因而处理器可以绝对快速地将虚拟地址转译成物理地址; 
> 反之, 如果一个虚拟地址没有出现在 TLB 中, 那么处理器必须采取以上介绍的两次查表过程(两次访问内存)才能完成地址转译. 在
> 这种情况下, 这一次内存访问会慢一些, 但是, 经过两次访问以后, 此虚拟页面与对应物理页面之间的映射关系将被记录到TLB中,
> 所以, 下次再访问此虚拟页面时, 处理器可以从 TLB 中实现快速转译, 除非此映射项已经被移除了.
>

### Linux 4级页表的演进

内核用户空间

![image](resource/user-kernel.png)


## 虚拟内存地址空间

> Linux 虚拟地址空间布局以及进程栈和线程栈总结

```
# 是否使用经典进程内存布局
# 新的进程内存布局(默认进程内存布局)导致了栈空间的固定. 而堆区域和 MMAP 区域共用一个空间, 这在很大程度上增长了堆区域
# 的大小
$ cat /proc/sys/vm/legacy_va_layout
0

$ sysctl -w vm.lagacy_va_layout=1

# 是否开启 ASLR 地址空间布局随机化
# 当设置值是 1, 地址空间是随机的. 栈空间位置和虚拟动态共享对象(VDSO)页共享同一个区域
# 当设置值是 2, 和值是 1 类似, 栈空间位置和虚拟动态共享对象(VDSO)页, 数据段, 三者共享同一个区域 
$ cat /proc/sys/kernel/randomize_va_space
2

$ sysctl -w kernel.randomize_va_space=0
```

### 32 位模式下 4GB 的内存地址块

> 32位内核地址空间划分, 64位内核地址空间划分是不同的

![image](resource/32_virtual_mem.png)

- 每个进程看到的 **地址空间** 都是一样的, 比如, **.text** 都是从 `0x80048000` 开始, 然后 **用户栈** 都是从
`0xBFFFFFFF` 向低地址增长, 内核地址空间都是 `0xC0000000` ~ `0xFFFFFFFF`
 
![image](resource/32_virtual_layout.png)

1. `0x00000000` ~ `0x08048000` 是不能给用户访问的, 这里是一些 C 运行库的内容. 访问会报 **segment fault**错误

2. `0xC0000000` ~ `0xFFFFFFFF` 这段是内核的逻辑地址, 在用户态访问会出错, 权限不足, 如果想访问, 需要切换到内核态,
可以通过**系统调用**等. 系统调用代表某个进程运行于内核, 此时, 相当于该进程可以访问 `0xC0000000` ~ `0xFFFFFFFF`这
一段地址了(实际上只能访问该进程的某个8kB的内核栈, 这里不是确定, 因为每个进程都有自己独立的8kB的内核栈, 应该是不能访问
别的进程的内核栈), 此时可以把用户空间逻辑地址在内核逻辑地址之间进行内存拷贝.

3. `start_brk` 和 `brk` 这两个值分别标识了堆的起始地址和结束地址. 其中 `brk` 又叫 program break. 在linux中可以
通过 brk() 和 sbrk() 这两个函数来改变 program break的位置.

3.1) 当程序调用 malloc() 时, 一般就是在内部调用 sbrk() 来调整 brk 标识的位置向上移动.

3.2) 当程序调用 free() 释放空间的时候, 传递给 sbrk() 一个负值来使堆的 brk 标识向下移动. 当然, brk() 和 sbrk() 
所做的工作不是简单地移动 brk 标识, 还要处理将虚拟内存映射到物理内存地址等工作.

3.3) glibc 中当申请的内存空间不大于 MMP_THRESHOLD 的时候, malloc() 使用brk/sbrk来调整 brk 标识的位置, 这个时
候所申请的空间确实位于图中 start_brk 和 brk 之间. 当所 `申请的空间大于这个阈值的时候, malloc() 改用 mmap() 来分
配空间`. 这个时候所申请到的空间就位于图中的 Memory Mapping Segment 这一段当中.

3.4) `习惯上将整个 Heap Segment 和 Memory Mapping Segment 称为 "堆"`

4. `Memory Mapping Segment`段是 `所有调用 mmap() 映射的数据的存储地`, 除了 malloc() 之外, 再就是动态链接库的
加载. linux 中程序开始运行的一个重要步骤是 `loader 会去查找该程序所依赖的链接库, 然后使用 mmap将链接库映射到进程的
地址空间中, 即映射到此处`

- Linux 对只读的内容可以共享, 在物理内存中只有一份拷贝. 这样, 即使在逻辑地址上看起来有很多 C 库等运行库在里面, 但整
个内存只有一份拷贝.
 
- 对于可写的数据段(data segment), 每个进程都应该有独立一份.

- **每个进程都有一个字节的页表**, 使得某逻辑地址对应于某个物理内存. 正因为每个进程都有一个自己的页表, 使得相同的逻辑
地址映射到不同的物理内存. 对于线程, 它有自己的页表, 只是页表的逻辑地址映射到非物理内存相同.

> - linux 内核把所谓的线程当做进程来实现, 线程仅仅被视为一个与其他进程共享某些资源的进程.
>
> - 是否共享地址空间(一个进程的地址空间与另一个进程的地址空间使用相同的内存地址 (虚拟内存的地址空间)) 几乎是进程和线
> 程间本质上的唯一区别, 线程对内存来说仅仅是一个共享特定资源的进程而已.
>
> - 进程的页表是怎样的呢?
>
> 1)首先, 内核本身就有一个页表了 (对于 normal_area都是一一映射到物理内存的), 能把内核逻辑地址映射到内核物理地址, 这
> 个内核逻辑地址对于每一个进程来说都是一样的, 所以, 在创建进程页表的时候,就直接拷贝该内核的页表, 作为进程页表的一部分;
> 
> 2)另外, 对于该进程的用户部分的页表, 可以简单地理解为**把逻辑地址映射到一个空闲的物理内存区域**
>
> - 每当切换到另一个进程时候, 就要设置这个进程的页表. 通过**设置 MMU 的某些寄存器, 然后 MMU 就可以把 cpu 发出的逻辑
> 地址转换为物理地址了**.


### 64 位模式

> Linux 内存管理

![image](resource/64_virtual_mem.png)

> Linux x86_64 位虚拟地址空间布局

- 虚拟地址只使用了 48 位, 因此打印的地址只有 12 位 16 进制.

- 在 x86_64 Linux 下有效的地址区间是从 `0x000000 00000000` ~ `0x00007FFF FFFFFFFF` 还有 `0xFFFF8000 0000
0000` ~ `0xFFFFFFFF FFFFFFFF` 两个地址区间. 而每个地址区间都有 128TB 的地址空间可以使用, 所以总共是 256TB 的可
用空间.

---

> amd64 下的 Linux 内存空间布局

[image](resource/amd64_virtual_mem.png)

- 对于 amd64 架构来说, 用户空间的 text 段的起始地址为 `0x00000000 00400000`, 和 x86 下的一样后面跟着 data 段
和 bss 段. heap 段和 bss 段之间也可以设置一个由 ASLR (ASLR, Address Space Layout Randomization, 是一种安全
机制, 主要防止缓存区溢出攻击) 导致的 `random brk offset`, heap 段向上增长.
 
- mmap 的起始地址通过页对齐之后从某一地址开始. 由于 amd64架构下 amd64 的页大小可以为 4K, 2M 或者 1G, 不像 x86 下
页大小统一为 4K, 所以 mmap 的起始范围根据系统的页大小也有不同; x86 下, mmap 段的起始地址固定为 `0x00002AAA AAAA
B000` (也可以设置 `random mmap offset`), 向上增长.

- stack 段和 `0x00007FFF FFFFF000` 之间可能有 `random stack offset`

---

> vm.legacy_va_layout=0
>
> kernel.randomize_va_space=2

![image](resource/cat_self_maps.png)

> - 前三行分别是 text segment, data segment 和 bss segment. **text segment**其实是存放二进制可执行代码的位
> 置, 所以它的权限是读与可执行. **data segment**存放的是静态常量, 所以该地址段权限是只读. **bss segment**存放未
> 初始化的静态变量, 所以它的权限是可读写.
> 
> - 接下来是 heap segment, heap地址是往高地址增长的, 是用来动态分配内存的区域. 它跟栈相反, 对应的内存申请系统调用
> 是 brk()
>
>> brk() 系统调用可以通过调整 heap 区域的 brk指针, 从而调整 heap 的虚拟内存空间大小.
> 
> - 接下来的区域是 memory mapping segment. 这块地址是用来分配内存区域的, 一般是用来把文件映射进内存用的, 但是也可
> 直接在这里申请内存空间使用, 对应的内存申请系统调用是 mmap()
>
>> mmap() 系统调用是把一个文件映射到一段内存地址空间; 也可以匿名直接申请一段内存空间使用
>> mmap() 不一定要在 memory mapping segment 进行内存申请, 可以指定任意的内存地址, 当然只要不跟已有的冲突就好, 这
>> 个地址也一定是 `000` 结尾, 才使得能页对齐.
> 
> - 再下面就是 stack segment, 栈的最大范围, 我们可以通过 prlimit 查看. 默认情况下的 8MB, 和 x86 一样.
>
> - 再下面就是 `vvar`, `vdso` 和 `vsyscall`. 这三个东西都是为了加速访问内核数据, 比如读取 `gettimeofday` 肯定
> 不能频繁地进行系统调用陷入内核, 所以就映射到用户空间了. 所有程序都有这个3个映射地址段.
>
>
>> 关于 vvar, vdso, vsyscall
>>
>> - 先说 vsyscall, 这东西出现最早, 比如读取时间 gettimeofday, 内核会把时间数据和 gettimeofday 的实现映射到这
>> 块区域, 用户空间可以直接调用(内核将一些本身应该是系统调用的直接映射到用户空间, 这样对于一些使用比较频繁的系统调用, 
>> 可以直接在用户空间调用以节省开销). 但是 vsyscall 区域太小了, 而且映射区域固定, 有安全问题.
>>
>> - 后来又造出了 vdso (virtual dynamic shared object), 之所以保留是为了兼容用户空间程序. vsdo 相当于加载一个
>> linux-vd.so库文件一样, 也就是把一些函数实现映射到这个区域.
>>
>> - vvar也就是存放数据的地方了, 那么用户可以通过调用 vsdo 里的函数, 使用 vvar 里的数据, 来获得自己想要的信息. 而
>> 且地址是随机的, 安全的.

---

> vm.legacy_va_layout=1
>
> kernel.randomize_va_space=0

![image](resource/cat_self_maps_1.png)


### 不同的 CPU 体系架构下虚拟内存地址空间大致类似

- `amd64` 架构下的进程地址空间布局总体上来说与 `x86` 下的相同, 只不过 amd64 的页大小可以为 4k, 2m, 或者 1g, 不像
x86 下大小统一为 4k



## 用户内存空间的各个段分布

> Linux 虚拟地址空间布局

![iamge](resource/user_segment.png)

- `random stack offset`, `random mmap offset` 和 `random brk offset` 随机值意在防止恶意程序. Linux 通过
对栈, 内存映射, 堆的起始地址加上随机偏移量来打乱布局, 以免恶意程序通过计算访问栈, 函数库等地址.

- 用户进程部分分段存储内容如下表(按地址递减顺序):

| 名称 | 存储内容 | 
| --- | --- |
| 栈 | 局部变量, 函数参数, 返回地址等 |
| 堆 | 动态分配的内存 |
| bss 段 | 未初始化或初值为0的全局变量和静态局部变量 |
| data 段 | 已经初始化且初值非0的全局变量和静态局部变量 |
| text 段 | 可执行代码, 字符串字面量, 只读变量 |

> - bss段, data段, text段, 是可执行程序编译时的分段, 运行时还需要堆和栈
>
> - 在将应用程序加载到内存空间执行时, 操作系统负责bss, data, text 段的加载, 并在内存中为这些段分配空间. 栈也是由操
> 作系统分配和管理; 堆由程序员自己管理, 即显示地申请和释放空间.
>
>> - execve(2) 负责为进程 text 和 data 建立映射, 真正将 text 和 data 的内容读入内存是由操作系统的缺页异常处理程
>> 序按需完成的.
>>
>> - 另外, execve(2) 还会将 bss 清零

- 栈 (stack)

- 内存映射段 (mmap)

mmap映射区向下扩展, 堆向上扩展, 两者相对扩展,直到耗尽虚拟地址空间的剩余区域.

- 堆(heap)

- bss 段

bss段用来存放程序未初始化的全局变量, 该段内容只记录数据所需空间大小, 并不分配真实空间.

- 数据段 (data)

data段用来存放程序已经初始化的全局变量, 为数据分配空间, 数据具体值保存在目标文件中.

- 代码段 (text)

text段用来存储程序中执行代码的内存区域, 通常为大小确定的只读段, 包括只读常量, 只读代码等

- 保留区


## 内核空间的虚拟地址 => 物理内存地址(高端地址)

```
$ cat /proc/buddyinfo 
Node 0, zone      DMA      2      1      3      2      1      2      0      0      1      1      3 
Node 0, zone    DMA32      7      5      5      6      5      6      6      5      7      7    586 
Node 0, zone   Normal    745    574    609    476     57     25     23     12      9      7    387
```

> Linux 虚拟内存和物理内存的理解

- IA32 架构中内核虚拟地址空间只有1GB大小(从3GB到4GB), 因此可以直接将这1GB大小的物理内存(即常规内存)映射到内核地址空
间, 但 **超出1GB大小的物理内存(即高端内存)** 就不能映射到内核空间. 为此, 内核采用了下面的方法使得内核可以使用所有的
物理内存.

> - 高端内存不能全部映射到内核空间, 也就是说这些物理内存没有对应的**线性地址**. 不过, 内核为每个物理页都分配了对应的
> 页描述符, 所有的页描述符都保存在 `mem_map` 数组中, 因此每个页描述符的线性地址都是固定存在的. 内核此时可以使用 
> `alloc_pages()` 和 `alloc_page()` 来分配高端内存, 因为这些函数返回页描述符的线性地址.
>
> - 内核地址空间的后 128MB 专门用于映射高端内存, 否则, 没有 `线性地址` 的高端内存不能被内核所访问, 这些高端内存的内
> 核映射显然是 `暂时映射的`, 否则也只能映射128MB的高端内存. 当内核需要访问高端内存时就临时在这个区域进行地址映射(使用
> 上面得到的*页描述符的线性地址*), 使用完毕之后再用来进行其他高端内存的映射.

![image](resource/kener_mem.png)

- 用户进程没有高端内存概念. 只有在内核空间才存在高端内存. 因为内核进程可以访问所有物理内存, 32位系统用户进程最大可以访
问3GB, 64位用户进程最大可以访问512GB

- 目前实现中, 64位Linux内核不存在高端内存, 因为64位内核可以支持超过512GB内存. **若机器安装的物理内存超过内核地址空
间范围, 就会存在高端内存**.




