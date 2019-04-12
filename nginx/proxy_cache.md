## Proxy Cache

**Buffer vs Cache**

Buffer和Cache都是用于提供IO吞吐效率的. 但是概念不同.

Buffer, "缓冲", 主要用于传输效率不同步或者优先级别不相同的设备之间传递数据. 一般通过对一方数据进行临时
存放, 再统一发送的方法传递给另一方, 以降低进程之间的等待时间, 保证速度较快的进程不发生间断, 临时存放的数
据一旦传递给另一方, 这些数据本身也没有用处了.

Cache, "缓存", 主要用于将硬盘上已有的数据在内存中建立缓存数据, 提高数据的访问效率, 对于过期不使用的缓存
可以随时销毁, 但不会销毁硬盘上的数据.


---

Proxy Buffer 与 Proxy Cache都与代理服务相关. 主要用来提供客户端和被代理服务器之间的交换效率.

Proxy Buffer实现了被代理服务器响应数据的异步传输;

Proxy Cache实现nginx服务器对客户端数据请求的快速响应;

>nginx服务器在接收到被代理服务器的响应数据之后, 一方面通过Proxy Buffer机制将数据传递给客户端, 另一方面
根据Proxy Cache的配置将这些数据缓存到本地硬盘上. 当客户端下次访问相同的数据时, nginx服务器直接从硬盘检
索到相应的数据返回给用户, 从而减少与被代理服务器交互的时间.

>注意: Proxy Cache机制依赖于Proxy Buffer机制, 只有在Proxy Buffer机制开启的状况下Proxy Cache的配
置才能发挥作用.
 

nginx还提供了另外一种将被代理服务器数据缓存到本地的方法Proxy Store, 与Proxy Cache的区别是, 它对来自被
代理服务器的响应数据, 尤其是**静态数据**只进行简单的缓存, 不支持缓存过期更新, 内存索引建立等功能, 但支持设
置用户或者用户组对缓存数据的访问权限.


### proxy_cache

**proxy_cache指令**配置一块公用的内存管理区域的名称, *在该区域可以存放缓存的索引数据*. 这些数据在nginx
服务器启动时由 **缓存索引重建进程** 负责建立, 在nginx服务器的整个运行过程中由 **缓存管理进程** 负责定时
检查过期数据, 检索等管理工作.

```
proxy_cache ZONE|off;
```
*ZONE*, 设置用于存放缓存索引的内存区域名称
*off*, 关闭Proxy Cache功能, 是默认的设置.

>从nginx 0.7 开始,Proxy Cache开启后会检查被代理服务器响应数据HTTP头中的"Cache-Control","Expires"
头域. 当"Cache-Control"头域的值是"no-cache", "no-store", "private" 或者 "max-age"赋值为0或
无意义时, 当"Expires"头域包含一个过期的时间时,该响应数据不被nginx服务器缓存. 目的是为了避免私有的数据被其
他客户端得到.


### proxy_cache_bypass

**proxy_cache_bypass指令** 配置 *nginx服务器向客户端发生响应数据时, 不从缓存中获取的条件*. 这些条件支持
nginx配置的常用变量.

```
proxy_cache_bypass STRING ...;
```
*STRING*, 条件变量, 支持配置多个, 当至少有一个字符串指令不为空或者不等于0时, 响应数据不从缓存中获取.

案例:
```
proxy_cache_bypass $cookie_nocache $arg_nocache $arg_comment $http_pargma $http_authorization
```
其中 `$cookie_nocache $arg_nocache $arg_comment $http_pargma $http_authorization` 都
是nginx配置文件的变量.


### proxy_cache_key

**proxy_cache_key指令** 设置nginx服务器在内存中为缓存数据建立索引使用的关键字

常用的配置:
```
proxy_cache_key $schema$proxy_host$uri$is_args$args
```


### proxy_cache_lock

**proxy_cache_lock指令**设置是否开启缓存的锁功能. 在缓存中, 某些数据项可以同时被多个请求返回的响应
数据填充. 开启该功能之后, nginx服务器同时只能有一个请求填充缓存中的某一个数据项. 

```
proxy_cache_lock on|off;
```
nginx 1.1.2之后才可以使用. 默认的关闭状态.


### proxy_cache_lock_timeout

**proxy_cache_lock_timeout指令**设置缓存的锁功能开启以后锁的超时时间. 

```
proxy_cache_lock_timeout TIME;
```
默认是5s.


### proxy_cache_min_uses

**proxy_cache_min_uses指令**设置客户端请求发送的次数, 当客户端向被代理服务器发送相同请求达到该指令
设置的次数后, nginx服务器才对该请求的响应数据做缓存. 合理设置该值可以有效地降低硬盘生缓存数据的数量,并
提高缓存的命中率.

```
proxy_cache_min_uses N;
```
默认设置是1.


### proxy_cache_path

**proxy_cache_path指令**设置nginx服务器存储缓存数据的路径以及和缓存索引相关的内容.

```
proxy_cache_path PATH [levels=LEVEL] key_zone=NAME:SIZE [inactive=TIME]
[max_size=SIZE] [loader_files=N] [loader_sleep=TIME] [loader_threshold=TIME]
```

*PATH*, 设置缓存数据存放的根路径, 该路径应该是预先存在于磁盘上的.

*levels*, 设置相对于PATH指定目录的第几级hash目录中缓存数据. levels=1, 表示一级hash目录
levels=1:2 表示两级.

*key_zone*, nginx服务器的缓存索引重建进程在内存中为缓存数据建立索引, 这一对变量用来设置存
放缓存索引的内存区域名称和大小.

*inactive*, 设置强制更新缓存数据的是,当硬盘上的缓存数据在设定是时间内没有被访问时,nginx服
务器强制从硬盘上将其删除, 下次客户端访问数据时重新缓存. 默认是10s.

*max_size*, 设置硬盘中缓存数据的大小限制. 硬盘中的缓存数据由nginx服务器的缓存管理进程进行
管理, 当缓存的大小超过该变量的设置时, 缓存管理进程将根据最近最少被访问的策略删除缓存.

*loader_files*, 设置缓存索引重建进程每次加载的数据元素的数量上限. 在重建缓存索引的过程中,
进程通过一系列的递归遍历读取硬盘上的缓存数据目录及缓存数据文件, 对每个数据文件中的缓存数据在
内存中建立对应的索引, 我们称每建立一个索引为加载一个数据元素. 进程在每次遍历的过程中可以同时
加载多个数据元素, **该值限制了每次遍历中同时加载的数据元素的数量**. 默认是100

*loader_sleep*, 设置缓存索引重建进程在一次遍历结束, 下次遍历开启之间的暂停时长. 默认是50ms

*loader_threshold*, 设置遍历一次硬盘缓存数据的时间的上限. 默认是200ms

> 注: 该指令只能放在http块中

### proxy_cache_revalidate

**proxy_cache_revalidate指令**: 使用带有"If-Modified-Since"和"If-None-Match"头域
来刷新缓存.

>注: 1.5.7之后版本使用

### proxy_cache_use_stale

如果nginx在访问被代理服务器过程中出现被代理服务器无法方法访问或者访问出错等现象时. nginx服务
器使用历史缓存响应客户端的请求.

```
proxy_cache_use_stale error|timeout|invalid_header|updating|http_500|http_502|
http_503|http_504|http_404|off ...;
```
该指令和proxy_next_upstream指令类似. 默认设置是off


### proxy_cache_valid

**proxy_cache_valid指令**针对不同的HTTP响应状态设置不同的缓存时间.

```
proxy_cache_valid [ CODE ... ] TIME; 
```
*CODE*设置HTTP响应的状态码. 可选, 默认是200,301,302
*TIME*, 设置缓存时间.

案例:
```
proxy_cache_valid 200 302 10m;
proxy_cache_valid 301 1h;
proxy_cache_valid any 1m;
```


### proxy_no_cache

**proxy_no_cache指令**配置 *在什么状况下不使用缓存*.

```
proxy_no_cache STRING ...;
```
*STRING*, 可以是一个或者多个变量. **当STRING的值不为空或者不为"0"时, 不启用缓存**.


### proxy_store

**proxy_store指令**配置是否在本地磁盘缓存来自被代理服务器的响应数据. 这个nginx提供了另
一种缓存数据的方法, 但是该功能相对Proxy Cache简单, 不提供缓存过期更新, 内存索引建立等功
能, 不占用内存空间, 对静态数据的效果比较好.

```
proxy_store on | off | PATH ;
```
*on|off*, 设置是否开启Proxy Store功能. 如果开启, 缓存文件会存放到alias指令或者root指
令设置的本地路径下. 默认是off

*PATH*, 自定义缓存文件的存放路径.


### proxy_store_access

*proxy_store_access指令**设置用户或用户组对Proxy Store缓存的数据的访问权限.

```
proxy_store_access USER:PERM ... ;
```
*USER*, 可以设置为user, group或者all
*PERM*, 设置权限.

案例:
```
location /images/ {
    root /data/www;
    error_page 404 = /fetch$uri;
}

location /fetch/ {
    proxy_pass http://backend;
    proxy_store on;
    proxy_store_access user:rw group:rw all:r;
    root /data/www;  # 缓存数据路径
}
```
