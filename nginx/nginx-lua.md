# nginx lua 脚本

nginx lua 脚本可使用的指令: 

```
init_by_lua_block
init_worker_by_lua_block
set_by_lua_block
rewrite_by_lua_block
access_by_lua_block
header_filter_by_lua_block
body_filter_by_lua_block
log_by_lua_block
```

> 这些指令是在 nginx 处理请求的各个阶段被调用执行. 使用的时候要根据实际的状况选择合适的指令.


nginx lua 获取 http 变量:

```
// uri 变量
ngx.var.arg_xxx, xxx 是 uri 当中的变量名. 例如: /a?abc=123, ngx.var.arg_abc 等价于 $arg_abc, 获取 abc 值

// nginx 内置变量
ngx.var.xxx, xxx 是内置变量名. 例如: ngx.var.remote_addr 等价于 $remote_addr, 获取请求远程地址.
```