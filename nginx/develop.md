# nginx 常见的问题和模块

## 常见的模块

- `nginx-rtmp-module`, 视频推流模块

git地址: github.com/arut/nginx-rtmp-module

- `ngx_http_proxy_connect_module`, HTTP代理的connect模块

git地址: github.com/chobits/ngx_http_proxy_connect_module

- `lua-nginx-module`, LUA模块

安装文档: https://github.com/openresty/lua-nginx-module#installation

- `nginx-http-flv-module`, HTTP方式访问 flv 视频模块

git 地址: github.com/winshining/nginx-http-flv-module

> `ngx_http_mp4_module` 是 HTTP方式访问 mp4 视频模块, 属于 nginx 内置模块, 只要在编译的时候启用即可, 启用的选项
是 `--with-http_mp4_module`


## 常见的问题

- `directory index of "xxx" is forbidden`, 访问出现 403

文件索引路径找不到, 注意不是文件不存在. 解决方案:

```
try_files $uri $uri/ index.html;
```

指定搜索索引路径.

- `open() "xxx" failed (13: Permission denied)`, 访问出现 403

文件路径没有权限访问, 设置好相关路径的读写权限即可.

- `open() "xxx" failed (2: No such file or directory)`, 访问出现 404

文件路径不存在, 这个要检查 nginx 路径配置.

