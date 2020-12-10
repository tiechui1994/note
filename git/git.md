## .git 常用的配置文件

一般初始化一个 git 项目之后, 在项目的根目录下会出现一个 .git 目录, 目录下的内容如下: 

```
branches/
COMMIT_EDITMSG
config         
description
FETCH_HEAD     
HEAD      
hooks/
index
info/
logs/
objects/
ORIG_HEAD
packed-refs
refs/
```

config, 这个文件是 git 的本地配置信息. 一般包括 `[core]` 核心配置, `[user]` 用户信息配置, `[remote "xxx"]` 远
程仓库配置, `[branch "xxx"]` 分支配置, 等等.

HEAD, 指向当前分支的最近一次提交. 例如 `ref: refs/heads/sync`, 可以在 `.git/refs/heads/sync` 当中可以查看当前
分支 `sync` 的最新一次提交的 commit

COMMIT_EDITMSG, 最近一次提交的消息内容.

FETCH_HEAD, 最近一次调用 `git fetch` 命令分支的 commit 和 相关消息.

refs, 这是一个目录, 记录的是对提交的commit的引用. 里面包含有目录, 最常见的有 heads, remotes, tags. heads记录本地
的各个分支最近一次提交的commit; remotes远程的各个分支最近一次push的commit; tags记录本地打标签时各个标签对应的commit.

hooks, 这是一个目录, 里面包含了的是一些脚本文件, 可以在 `commit`, `push`, `rebase`, `apply` 等操作的前后加一些脚
本, 以完成一些自动化的工作. 功能非常强大, 但是目前我没咋使用到.

logs, 这是一个目录, 记录的是各个分支的提交记录的日志. logs/HEAD 记录的当前分支的commit日志. logs/refs/heads 记录
的是本地各个分支的commit记录日志. logs/refs/remotes 记录各个远程仓库的远程推送的 commit 日志.

objects, 这是一个目录, 里面记录的是序列化之后的内容. 对于任意一个commit, commit的前两位选择文件, 后面的内容是文件名称.
可以通过 `git cat-file` 命令查看相关文件的的内容, 这个里面的内容非常的丰富.


### config 内容

config 是一个 git 的一个本地配置文件. 在刚初始化一个git项目时(`git init`), 里面只包含一个 `[core]` 配置.
 
`[core]` 配置:

```toml
[core]
	repositoryformatversion = 0
	filemode = true         # 文件模式, 在跨文件系统的时候, 需要设置为false
	bare = false            # 是否是裸露的项目, 添加 --bare 参数时, 此值是 true
	logallrefupdates = true
```

`[core]` 还可以设置的内容, `editor` 可以设置为 `vim`, 这样每次 append commit 的时候, 弹出 vim 编辑器, 而不是默
认的编辑器(很难用). 

`[user]` 配置:

```
[user]
	email = xxx@github.com.cn
	name  = xxx
```

这个是配置提交用户名称和邮箱信息. 一般情况下, 邮箱是你的注册 github/gitlab 等的邮箱, 用户名称是你注册的名称. 当然啦,
你也可以用其他的名称或者邮箱(不建议啦).

`[remote "xxx"]` 配置:

```
[remote "origin"]
	url = git@gitlab.example.com.cn:test.git
	fetch = +refs/heads/*:refs/remotes/origin/*
```

使用命令 `git remote add xxx git@gitlab.cn:test.git`, 会在 config 当中添加一个配置 `[remote "xxx"]`
使用命令 `git remote remove xxx`, 会从 config 当中移除配置 `[remote "xxx"]`.
使用命令 `git remote rename xxx yyy`, 会将 config 当中的配置 `[remote "xxx"]` 改为  `[remote "yyy"]`.

它的含义是添加远程仓库 `git@gitlab.example.com.cn:test.git`, 在本地的别名是 `origin`. 当然了, 也是可以添加多个
远程仓库,这样一份代码可以同时同步到多个仓库当中. 这个配置也是可以手动修改的, 比如上述的 url 这里使用的是 git 协议, 你可
以更改为 http 协议的.

`[branch "xxx"]` 配置:

```
[branch "master"]
	remote = origin
	merge = refs/heads/master
```

使用命令 `git checkout -b xxx origin/xxx`, 就可以在 config 当中创建一个 `[branch "xxx"]` 配置. 
使用命令 `git branch -D xxx`, 会将 config 当中的 `[branch "xxx"]` 移除.

remote, 在 `master` 分支进行 `git fetch` 和 `git push` 时, remote 指定了往哪个远程仓库进行 fetch/push.
merge 和 branch 一起定义了分支的上游分支. 它告诉 `git fetch` 和 `git pull`, `git rebase` 合并哪个分支, 并且还
可能影响 `git push`. 在分支 "xxx" 中时, 它告诉 `git fetch` 将标记为要合并到 `FETCH_HEAD` 中的默认refspec. 
