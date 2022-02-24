## proxy buffer

**proxy buffer的配置是针对每一个请求起作用的, 而不是全局的概念**. 即每个请求都会按照这些指令的配置来配置各自的Buffer, 
*nginx服务器不会生成一个公共的proxy buffer供代理请求使用.*

---

**proxy buffer启用之后, nginx服务器会异步的将被代理服务器的响应数据传递给客户端.**

nginx服务器首先尽可能地从被代理服务器那里接收响应数据, 放置在proxy buffer中, Buffer的大小由prox_buffer_size指令和
proxy_buffers指令决定. 如果在接收过程中, 发现Buffer没有足够大小来接收一次响应数据, nginx服务器会将部分接收到的数据临
时存放在磁盘的临时文件中, 磁盘上的临时文件路径可以通过proxy_temp_path进行设置, 临时文件的大小由proxy_max_temp_file_size
和proxy_temp_file_write_size决定. 一次响应数据被接受完成或者Buffer已经装满后, nginx服务器开始向服务器传输数据.

每个proxy buffer装满数据后, 从 *开始向客户端发送* 一直到 *proxy buffer中的数据全部传输给客户端* 的整个过程中, 它都
处于BUSY状态, 期间对它进行的其他操作都会失败, 同时处于BUSY状态的proxy buffer总大小由 prox_busy_buffers_size 限制, 
不能超过该指令设置的大小.

---

当proxy buffer关闭时,nginx服务器只要接收到响应数据就会同步地传递给客户端, 它本身不会读取完整的响应数据.


### proxy_buffering

**proxy_buffering指令**配置是否启用或者关闭proxy buffer. 默认是开启状态.

```
proxy_buffering on|off;
```

开启或者关闭proxy buffer还可以通过在HTTP响应头的"X-Accel-Buffering"头域设置"yes"或者"no"来实现.


### proxy_buffers 

**proxy_buffers指令**配置 *接收一次被代理服务器响应数据* 的proxy buffer个数和每个Buffer的大小.

```
proxy_buffers NUMBER SIZE;
```
- NUMBER, proxy buffer的个数
- SIZE, 每个Buffer的大小, 一般设置为内存页的大小. 可能是4KB或者8KB


通过这个指令可以得到接收一次被代理服务器响应数据的proxy buffer总大小是NUMBER*SIZE. 默认配置:

```
proxy_buffers 8 4k|8k;
```


### proxy_buffer_size

**proxy_buffer_size指令** 配置 *从被代理服务器获取的第一部分响应数据的大小, 该数据一般只包含了HTTP响应头.*

```
proxy_buffer_size SIZE;
```
- SIZE, 缓存大小. 默认设置是4KB或者8KB, 保持于proxy_buffer指令中的SIZE变量相同, 当然也可以设置得更小.


### proxy_busy_buffers_size (难理解)

BUSY状态: 每个proxy buffer装满数据后, 从 *开始向客户端发送* 一直到 *proxy buffer中的数据全部传输给客户端* 的整个
过程中, 它都处于BUSY状态.

在BUSY状态, nginx一定会向客户端发送响应, 直到缓冲小于此值. **proxy_busy_buffers_size指令** 用来设置此值. **同时, 
剩余的缓冲区可以用于接收响应.**

**proxy_busy_buffers_size指令**限制处于BUSY状态的proxy buffer的总大小.

```
proxy_busy_buffers_size  SIZE;
```
- SIZE 为处于BUSY状态的缓存区总大小. 该大小默认是 proxy_buffer_size和proxy_buffers 指令设置单块缓冲大小的两倍. 
即默认设置为8KB或者16KB. 

### proxy_temp_path

**proxy_temp_path指令**设置临时存放代理服务器的大体积响应数据.

```
proxy_temp_path PATH [LEVEL, LEVEL];
```
- PATH, 磁盘上存放临时文件的路径
- LEVEL, 设置临时文件在PATH变量路径下的第几级hash目录中存.

案例:
```
proxy_temp_path /nginx/proxy/spool/temp 1 2;
```

配置临时文件存放在/nginx/proxy/spool/temp路径下的第二级目录中. 基于该配置的一个临时文件目录可以是:

```
/nginx/proxy/spool/temp/1/10/00000100101
```

### proxy_max_temp_file_size

**proxy_max_temp_file_size指令**配置 **临时文件的总体积大小**, 存放在磁盘上的临时文件不能超过该配置值.

```
proxy_max_temp_file_size SIZE;
```
*SIZE*设置临时文件的总体积上限值. 默认是1024MB


### proxy_temp_file_write_size

**proxy_temp_file_write_size指令**配置 **同时写入临时文件的数据量的总大小**, 合理的设置可以避免磁盘IO负载过重导致
系统性能下降的问题.

```
proxy_temp_file_write_size SIZE;
```

默认设置是8KB或者16KB, 一般与平台的内存页大小相同.
