## linux 系统常见问题

### 常用的 ip 设置禁用

[Postman下载页面](https://www.fosshub.com/Postman-old.html)

> 禁止自动更新设置, 在 /etc/hosts 文件当中添加如下配置 

```
0.0.0.0        dl.pstmn.io
0.0.0.0        account.jetbrains.com
0.0.0.0        www.jetbrains.com
```

### 系统动态库查询

- Ubuntu 下查询包查询("软件包") 的方法

```
# 过滤安装包, 这种方式能查看到相关的版本, 架构, 包描述信息
dpkg -l | grep xxx

# 搜索安装包, 这种方式可以查看到安装的相关信息
dpkg -S xxx
dpkg --search=xxx
```

- Ubuntu 下查看"头文件"的路径

```
/usr/include
/usr/local/include
```

`/usr/include` 一般是使用系统安装方式的lib的头文件位置(比如 `apt-get iinstall`, `dpkg -i`)

`/usr/local/include` 一般是用户手动编译lib时默认的头文件位置


- Ubuntu 下动态库

动态库路径配置文件: `/etc/ld.so.conf`, `/etc/ld.so.conf.d/*.conf`.

动态库路径缓存文件: `/etc/ld.so.cache`

使用 ldconfig 命令可以进行动态库更新和查看:

```
# 更新动态库缓存
sudo ldconfig 

# 查看动态库缓存当中的动态库路径
ldconfig -p
```

使用 ldd 命令可以查看 `可执行程序(动态编译)`, `动态库` 依赖的动态库

```
ldd FILE
```

### apt-get 介绍

apt-get 是 APT 包处理应用程序的命令行界面. 下面是有用的选项.

- `--no-install-recommends`, 不将推荐(recommend)的软件包视为安装的依赖项. 配置项: APT::Install-Recommends.

- `--install-suggests`, 将建议(suggest)的软件包视为安装的依赖项. 配置项: APT::Install-Suggests.

- `--no-upgrade`, 不升级软件包, 当与 install 一起使用时, no-upgrade 将阻止对已安装软件包的升级. 配置项: APT::Get::Upgrade

- `--only-upgrade`, 不安装新的软件包; 当与 install 一起使用时, only-upgrade 将只为已经安装的包进行升级, 并忽略安
装新的软件包的请求. 配置项: APT::Get::Only-Upgrade

- `--purge`, 对于要删除的任何内容, 请使用 remove 而不是 purge. `remove --purge` 等同于 `purge` 命令.

- `--reinstall` 重新安装已经安装的最新版本的软件包. 配置项: APT::Get::ReInstall

- `-t, --target-release, --default-release`, 此选项控制策略引擎的默认输入. 它使用指定的release string创建优先
级为 990 的默认脚本. 这会覆盖 `/etc/apt/preferences` 中的常规设置. 简而言之, 此选项可以控制将从哪些distribution
packages 中检索. 一些常见的示例: `-t '2.1*'`, `-t unstable`, `-t sid`. 配置项: APT::Default-Release.

- `--auto-remove, --autoremove`, 如果命令是 install 或 remove, 则此选项的作用类似运行 autoremove 命令, 删除
未使用的依赖包. 配置项: APT::Get::AutomaticRemove

- `-b, --compile, --build`, 下载源码包后编译. 配置项: APT::Get::Compile

- `-a, --host-architecture`, 此选项控制由 `apt-get source --compile` 构建的arch包以及如何满足跨构建关系. 默认
情况下未设置, 这意味着host arch与build arch(APT::Architecture)相同. 配置项: APT::Get::Host-Architecture.

- `-d, --download-only`, 仅下载, 仅检索包文件, 而不是解包或安装. 配置项: APT::Get::Download-Only.

- `-f, --fix-broken`, 修复. 尝试修正具有破坏关系的系统. 此选项与 install/remove 一起使用时, 可以省略任何包以允许
APT推断出可能的解决方案. 如果指定了包, 则这些包必须完全纠正的问题.

