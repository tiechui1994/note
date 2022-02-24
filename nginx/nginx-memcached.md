## 基于memcached的缓存机制

memcached 是一套高性能的基于分布式的缓存系统, 用于动态web应用以减轻后台数据服务器的负载. 它可以独立于任何应用程序作为后
台程序运行, 通过在内存中的缓存数据来减少对后台数据服务器的请求, 从而提高对客户端的响应.

memcached可以处理并发的网络连接. 它在内存中开辟一块空间, 然后建立一个Hash表, 将缓存数据通过键/值存储在Hash表中进行管理. 
memcached由服务端和客户端两个核心组件组成,**服务端先通过计算 "键" 的Hash值来确定键/值对在服务端所处的位置. 当确定键/值
对的位置后, 客户端就会发送一个查询请求给对应的服务端, 让它来查找并返回确切的数据**


### memcached_pass

**memcached_pass指令**配置memcached服务器的地址.

```
memcached_pass ADDRESS;
```

- ADDRESS, 支持IP+端口的地址 或者 域名地址. 也可以使用upstream指令配置的一个memcached服务器组


### memcached_connect_timeout

配置连接memcached服务器的超时时间. 默认是60s, 建议该时间不要超过75s.

### memcached_read_timeout

配置nginx服务器向memcached服务器发出两次read请求之间的等待超时时间, 如果在该时间内没有进行数据传输,
连接将会关闭, 默认是60s

### memcached_send_timeout

配置nginx服务器向memcached服务器发出两次write请求之间的等待超时时间, 如果在该时间内没有进行数据传输,
连接将会关闭, 默认是60s

### memcached_bufer_size

**memcached_buffer_size指令**配置nginx服务器用于接收memcached服务器响应数据的缓存区大小.

```
memcached_buffer_size SIZE;
```

- SIZE, 设置的缓存区大小, 一般是内存页大小的倍数, 默认是4KB|8KB

### memcached_next_upstream

**memcached_next_upstream指令**: 在配置了一组memcached服务器的情况下使用. 服务器组中各个 memcached 服务器的访问
规则遵循upstream指令配置的轮训规则, 同时使用该指令配置在发生哪些一次状况时, 将请求顺次交由下一个组内服务器处理.
 
```
memcached_next_upstream STATUS ...;
```

- STATUS, 设置当memcached服务器返回的状态, 可以是一个或者多个. 状态包括:

```
1. error, 建立连接, 向memcached服务器发送请求或者读取响应头时服务器发生连接错误.
2. timeout, 建立连接, 向memcached服务器发送请求或者读取响应头时服务器发生连接超时.
3. invalid_header: memcached服务器返回响应头为空或者无效.
4. not_found: memcached服务器未找到对应的键/值对
5. off: 无法将请求发生给memcached服务器.
```

>以上是使用memcached缓存经常使用的指令. 在实际配置nginx服务器使用memcached时, 需要配置nginx全局的 $memcached_key.

案例:
```
server {
    location / {
        set $memcached_key "$uri?$args"; # 配置全局的$memcached_key变量
        memcached_pass 192.168.1.4:8080;
        error_page 404 502 504 = @fallback;
    }
    
    location @fallback {
        proxy_pass http://192.168.1.3:2000;
    }
}
```
