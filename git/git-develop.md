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


## 修改 GitHub 的历史敏感提交

假设当前分之提交(提交 I 是当前 master 的HEAD): 
```
D---E---F---G---H---I
```

其中提交 E 和 H 里是包含敏感信息的, 那该如何修改可以消除 E, H 当中的敏感提交呢? 使用变基修改历史提交. 详细操作:

```
# 交互模式下, 使用 edit 命令修改需要修改的提交(E, H)
git rebase -i D [I|HEAD|master]

# 重置 E 的提交内容(注: 这里不是hard模式)
git reset HEAD^

# 编辑 E 提交的内容(去除敏感信息)
git add -A && git commit -m "E fix"

# 继续变基.
git rebase --contine

# 重置 F 的提交内容(注: 这里不是hard模式)
git reset HEAD^

# 编辑 F 提交的内容(去除敏感信息)
git add -A && git commit -m "F fix"

# 继续变基. 直到所有变基操作完成. (完成变基操作后, 会应用到当前分支)
git rebase --continue

# 将当前的分支强制推送到远程分支
git push origin master -f
```

经过上述操作之后, 可以将历史的敏感信息消除. 同时新的提交历程如下:

```
D---E'---F---G'---H---I
```

> 注: 在 GitHub 上 D 提交之后的所有提交的 CommitID 都会发生修改. E', G' 的所有提交信息都会修改.

