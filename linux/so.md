### 动态库

- Ubuntu 下查询动态库("软件包") 的方法

```
# 过滤安装包, 这种方式能查看到相关的版本, 架构, 包描述信息
dpkg -l | grep xxx

# 搜索安装包, 这种方式可以查看到安装的相关信息
dpkg -S xxx
dpkg --search=xxx
```

- Ubuntu 下查看头文件的路径

```
/usr/include
/usr/local/include
```

`/usr/include` 一般是使用系统安装方式的lib的头文件位置(比如 `apt-get iinstall`, `dpkg -i`)

`/usr/local/include` 一般是用户手动编译lib时默认的头文件位置


- Ubuntu 下查看和配置动态库的路径

配置文件 `/etc/ld.so.conf`

