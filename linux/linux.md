### 常用的应用软件

- 音乐/视频播放 (SMPlayer, mpv)

```
sudo apt-get install smplayer
sudo apt-get install mpv
```

> 最新版本的 SMPlayer 是基于 mpv 开发的

- 禁用的IP地址列表

[下载页面](https://www.fosshub.com/Postman-old.html)

> 禁止自动更新设置, 在 /etc/hosts 文件当中添加如下配置 

```
0.0.0.0	    dl.pstmn.io
0.0.0.0		account.jetbrains.com
0.0.0.0		www.jetbrains.com
```

### 系统动态库查询

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

### apt-get 非常实用的选项
