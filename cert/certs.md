## Linux 系统导入根证书

> 注意: 本文的 Linux 系统是 Ubuntu 16.04, 其他的 Linux 发行版本需要谨慎.

在进行系统证书导入之前, 先要弄清楚 Linux 系统与系统证书相关的几个文件/目录. 

`/usr/share/ca-certificates`, 这个目录存放了系统内置的证书. 一般在 `mozilla` 目录下, 保存为 `crt`文件.

`/usr/local/share/ca-certificates`, 这个目录是本地的证书.(似乎没用到过)

`/etc/ca-certificates/update.d`, 这个目录主要存放 hooks 脚本. 在执行 `update-ca-certificates` 命令的使用进行
执行.

`/etc/ca-certificates.conf`, 这个文件是配置系统内置的证书文件名称列表. 所有的文件都是相对于 `/usr/share/ca-certificates`
目录的. 如果以 `!` 开始的行, 表示要取消选择这个证书文件名. 根据这个配置文件最终, 生成 `/etc/ssl/certs/ca-certificates.crt`
文件内容. 使用命令 `dpkg-reconfigure ca-certificates` 可以自动生成此文件, 使用命令 `update-ca-certificates` 
可以根据此文件内容更新 `/etc/ssl/certs/ca-certificates.crt` 文件.

`/etc/ssl/certs`, 这个目录存储的证书(包括系统内置的证书和用户的生成的证书)

`/etc/ssl/certs/ca-certificates.crt`, 系统内置的证书文件内容的集合 (就是将所有系统内置的证书的文件内容放到一个文件
当中), 在 Go 当中, 就是使用此目录作为系统内置的证书加载文件. 使用 `update-ca-certificates` 可以更新此文件.

`/etc/ssl/private`, 这个目录存储的用户的私钥.

下面讲解导入系统证书的一般过程:

- 生成一个证书. 可以 Google `如果使用openssl生成证书`.

- 将生成的证书放到 `/usr/share/ca-certificates/mozilla` 目录下, 文件后缀 `.crt`, 文件内容是 `pem` 格式.

- 更新系统证书的配置, 执行 `dpkg-reconfigure ca-certificates` 命令(注意: 要使用 root 权限执行). 这个时候会跳出
来一个弹出框, 第一步选择 `yes`, 第二步将新添加的证书打上星号(新添加的证书是一个空白).

- 更新系统证书文件, 执行 `update-ca-certificates` 命令(注意: 要使用 root 权限执行). 到这里, 就内置了一个自己的系
统证书.

需要注意: 目前 Chrome 浏览器对于自己生成的系统证书, 在进行 ssl 连接的时候还是会发出告警的信息的, 这个需要将自己的系统
证书添加到 Chrome 浏览器的 `chrome://settings/certificates` 当中导入自己生成证书, 以消除告警.

