# nginx 模块化体系结构

nginx 提供了web服务器的基础功能, 同时还提供了web服务反向代理, email服务反向代理功能. nginx core实现了底层
的通信协议, 为其他模块和nginx进程构建了基本的运行时环境, 并且构建了其他各模块的协作基础. 除此之外, 或者说大部分
与协议相关的, 或者与应用相关的功能都是在这些模块中所实现的.


## 模块概述 

nginx将各功能模块组织成一条链, 当有请求到达的时候, 请求依次经过这条链上的部分或者全部模块, 进行处理. 每个模块实
现特定的功能. 例如, 实现对请求解压缩的模块, 实现SSL的模块, 实现与上游服务器进行通讯的模块, 实现与FastCGI服务
进行通讯的模块等.


>有两个模块比较特殊, 它们居于nginx core和各种功能模块的中间. 这两个模块就是http模块和mail模块. 这两个模块在nginx
core之上实现了另外一层抽象, 处理与HTTP协议和email相关协议(SMTP/POP3/IMAP)有关的*事件*, 并且确保这些事件能
被以正确的顺序调用其他的一下功能模块.


*目前HTTP协议是被实现在http模块中的, 但是有可能将来被剥离到一个单独的模块中, 以扩展nginx支持SPDY协议.*


## 模块分类

event module: 搭建了独立于操作系统的事件出口机制的框架, 及提供了各具体事件的处理. ngx_event_module, ngx_epoll_module等.
nginx具体使用何种事件处理模块, 这依赖于具体的操作系统和编译选项.

phase handler: 此类型的模块也被直接称为handler模块. 主要负责处理客户端请求并产生待响应内容, 比如ngx_http_static_module
模块, 负责客户端的静态页面请求处理并将对应的磁盘文件准备为响应内容输出.

output filter: filter模块,注意是负责对输出的内容进行处理, 可以对输出进行修改. 例如,可以实现对输出的所有html页面
增加预定义的footbar一类的工作, 或者对输出的图片的URL进行替换之类的工作.

upstream: 实现反向代理的功能, 将真正的请求转发到后端服务器上, 并从后端服务器上读取响应, 发回客户端. upstream模块
是一种特殊的handler, 只不过响应内容不是真正由自己产生的, 而是从后端服务器上读取的.

loadbalancer: 负载均衡模块, 实现特定的算法, 在众多的后端服务器中, 选择一个服务器出来作为某个请求的转发服务器.


## nginx的请求处理

nginx采用多进程方式对外提供服务, 其中一个master进程, 多个worker进程. master进程负责管理nginx本身和其他worker
进程.

所有实际上的业务处理逻辑都在worker进程. worker进程中有一个函数, 执行无限循环, 不断处理收到的来自客户端的请求,并进
行处理, 直到整个nginx服务被停止.

worker进程中, ngx_worker_process_cycle() 函数就是这个无限循环的处理函数. 在这个函数中, 一个请求的简单处理流
程如下:

- 操作系统提供的机制(例如epoll,kqueue等)产生相关的事件
- 接收和处理这些事件, 如果是接收到数据, 则产生更高层的request对象.
- 处理request的header和body.
- 产生响应, 并发送回客户端.
- 完成request的处理.
- 重新初始化定时器及其他事件.

### 请求处理流程

从nginx内部来看, 一个HTTP Request的处理过程涉及到以下几个阶段.

- 初始化HTTP Request(读取来自客户端数据, 生成HTTP Request对象, 该对象含有请求所有的信息)
- 处理请求头
- 处理请求体
- 如果有的话, 调用与此请求(URL或者Location)关联的handler
- 依次调用phase handler进行处理.

一个phase handler通常执行以下几项任务:
```
1. 获取location配置
2. 产生适当的响应
3. 发送response header
4. 发送response body
```

当nginx读取到一个HTTP Request的header的时候, nginx首先查找与这个请求关联的虚拟主机的配置. 如果找到了这个虚拟
主机的配置, 那么通常情况下, 这个HTTP Request将会经过以下几个阶段的处理(phase handlers):

**NGX_HTTP_POST_READ_PHASE**: 读取请求内容

**NGX_HTTP_SERVER_REWRITTE_PHASE**: Server请求地址重写

**NGX_HTTP_FIND_CONFIG_PHASE**: 查找配置

**NGX_HTTP_REWRITE_PHASE**: Location请求地址重写

**NGX_HTTP_POST_REWRITE_PHASE**: 请求地址重写提交

**NGX_HTTP_PREACCESS_PHASE**: 访问权限检查准备

**NGX_HTTP_ACCESS_PHASE**: 访问权限检查

**NGX_HTTP_POST_ACCESS_PHASE**: 访问权限检查提交

**NGX_HTTP_TRY_FILES_PAHSE**: 配置项try_files处理

**NGX_HTTP_CONTENT_PHASE**: 内容产生

**NGX_HTTP_LOG_PHASE**: 日志模块处理


在*NGX_HTTP_CONTENT_PHASE*阶段, 为了给一个request产生正确的响应, nginx必须把这个request交给一个合适的
Content Handler去处理. 如果这个request对应的location在配置文件中被明确指定了一个Content Handler, 那么
nginx就可以通过对location的匹配, 直接找到这个对应的Handler, 并把这个request交给这个Content Handler去处
理. 这样的配置指令包含像perl, fllv, proxy_pass, mp4等.


如果一个request对应的location并没有直接配置的Content Handler, 那么nginx依次尝试:
```
1. 如果一个location里面有配置random_index on, 那么随机选择一个文件, 发送给客户端.
2. 如果一个location里面有配置index指令, 那么发送index指令指明的文件给客户端.
3. 如果一个location里面有配置autoindex on, 那么发送请求地址对应的服务端路径下的文件列表给客户端.
4. 如果这个request对应的location上设置gzip_static on, 那么就查找是否有对应的.gz文件存在, 有的话, 就发送这个
gz文件给客户端(客户端支持gzip的情况下)
5. 请求的URI如果对应一个静态文件, static module就法搜静态文件的内容到客户端.
```


*NGX_HTTP_CONTENT_PHASE*阶段完成之后, 生成的输出被传递到filter模块去进行处理. filter模块也是与location相关的.
所有的filter模块都被组织成一条链. 输出会依次穿越所有的filter, 直到有一个filter模块的返回值表明已经处理完成.

常见的filter模块:
```
server-side includes
XSLT filtering
图像压缩之类的
gzip 压缩
```
