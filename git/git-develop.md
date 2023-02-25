# git 日常使用问题

## github ssh 加速

github ssh 加速指的是在命令行当中加速 pull, push 远程代码. 对于浏览器当中加速访问 github, 则需要使用代理进行加速.

```
# 使用远程代理
Host github.com
     User git
     HostName git.zhlh6.cn
     Port 22
     IdentityFile ~/.ssh/id_rsa
     LogLevel ERROR
     Compression yes

# 使用本地代理
Host github.com
     User git
     HostName github.com
     Port 22
     IdentityFile ~/.ssh/id_rsa
     ProxyCommand nc -X connect -x 127.0.0.1:1080 %h %p
     LogLevel ERROR
     Compression yes

# 使用 SSH Connect over HTTPS
Host github.com
     User git
     HostName ssh.github.com
     Port 443
     IdentityFile ~/.ssh/id_rsa
     ProxyCommand nc -X connect -x 127.0.0.1:1080 %h %p
     LogLevel ERROR
     Compression yes
```

> IdentityFile 是 github 配置的私钥文件路径. HostName 配置的是远程 ssh 加速访问的代理服务器.

> nc 是使用代理, `-X connect` 是使用 http 代理. `-X 5` 是使用 socks5 代理.


## 'remote/xyz' is not a commit and a branch 'xyz' cannot be created from it ?

原因: git 无法解析您提供给特定提交的分支, 通常是因为它没有最新的远程分支列表.

解决方法一: 拉取所有的远程分支

```
git fetch --all
```

解决方法二: 只拉取特定的远程分支

```
# 拉取特定远程分支到 FETCH_HEAD, 然后切换到 FETCH_HEAD
git fetch origin remote/xyz
git checkout -b xyz FETCH_HEAD
```

