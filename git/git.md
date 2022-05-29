# git

## git 目录结构

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


### hooks 文件

hooks 在 git 执行 的某些点触发操作. 如果 hook 文件没有可执行权限, 则将被忽略. 

> **注: 如果要启用 hook 脚本, 将该文件放到配置的 hooks 目录当中, 该文件具有适当的名称(没有任何扩展名)并且是可执行的.**

默认情况下, hooks 目录是 `$GIT_DIR/hooks`, 可以通过 `core.hooksPath` 配置进行更改.

- `applypatch-msg`, 该 hook 由 git-am 调用. 它接收一个参数, 即保存建议的提交日志消息的文件名称.

- `pre-commit`, 该 hook 由 git-commit 调用, 可以使用 `-no-verfiy` 选项绕过. 它不带任何参数, 并且在获取提交日志
消息之前被调用. 如果此脚本以非0状态退出会导致 git commit 命令在创建提交之前终止.

默认的 pre-commit 启用时会捕获带有尾随空格的行的引入, 并在找到这样的行时终止提交.

- `post-commit`, 该 hook 由 git-commit 调用. 它不带任何参数, 并且在提交后被调用. 

这个 hook 主要用于通知, 不会影响 git commit 的结果.

- `prepare-commit-msg`, 该 hook 由 git-commit 调用. 在准备默认日志消息之后, 并且启动编辑器之前调用/

它需要一到三个参数. 第一个是包含提交日志消息的文件的名称. 第二个是提交消息的来源,可以是 message (如果指定了 `-m` 或 `-F`
选项); template (如果指定了 `-t` 选项或者设置了 `commit.template` 选项); merge (如果提交是一个合并或者存在
.git/MERGE_MSG文件); squash (如果存在 .git/SQUASH_MSG文件); commit; 然后提交 SHA-1 (如果指定了 `-c`, `-C`或
`--amend` 选项).

如果脚本的退出状态非0, 则 git commit 将终止.

- `pre-push`, 该 hook 由 git-push 调用, 可用于阻止推送. 使用两个参数调用 hook. 第一个参数远程仓库的名称, 第二个参数是远程仓库的URL.
hook 的标准输入中提供了有关要推送的内容信息, 格式如下:

```
<local ref> <local sha1> <remote ref> <remote sha1>
```

它们分别代表本地分支ref, sha1 和远程分支 ref, sha1. 如果远程 ref 尚不存在, 则 `<remote sha1>` 的值为 40 个 0.  如果要删除 ref, 则 
`<local ref>` 将作为 (delete) 提供, `<local sha1>` 的值为 40 个 0

> 详情参考 `man githooks` 文档.

## git 密钥

### git GPG 密钥对

- 生成 GPG 密钥对

`gpg --full-gen-key`, 可以选择`算法类型`, `有效期`, `名称`, `电子邮件`, `备注`.

> `电子邮件` 要与 github 当中的 `email` 一致, 否则 GPG 导出的公钥无法验证成功.

> 如果本地已经存在了一个 gpg 密钥对, 可以在原来的密钥对基础上添加新的用户标识(`邮箱`, `名称`, `备注`). 方法如下:
> 1) 首先使用命令 `gpg --edit-key UID`, 其中密钥UID的获取方法参考下面 '获取GPG密钥UID'. 进入交互式密钥编辑.
> 2) 输入命令 `adduid`, 添加一个新的用户标识. 然后依次输入 `名称`, `邮箱`, `备注`, 之后保存输入的内容.
> 3) 输入命令 `save`, 保存当前的修改, 就这样添加了新的用户标识.

- 获取 GPG 密钥的 UID.

`gpg --list-keys --keyid-format long`. 其中 `pub` 行的 `/` 后面的内容是密钥UID. 下例是 `17FA6CF726EC0733`

```
$ gpg --list-keys --keyid-format long
-----------------------------
pub   rsa3072/17FA6CF726EC0733 2022-01-01 [SC] [expires: 2023-01-01]
      1357901357901357901357901357901357901357
uid                 [ultimate] NAME (COMMENT) <EMAIL>
sub   rsa3072/17FA6CF726EC0733 2022-01-01 [E] [expires: 2023-01-01]
```

- 导出密钥UID的公钥

```
gpg -a --export UID
```

> 将导出的密钥ID的公钥复制到 github, gitlab, coding 等的 GPG 公钥处进行添加(类似SSH公钥).

- 配置使用 GPG 签名提交

```
# 配置密钥签名key, 也就是前面的 GPG 密钥UID
git config user.signingkey UID

# 配置自动 commit gpg 签名. 默认情况下, 在 'git commit' 时使用 '-S' 参数才会使用 GPG 签名.
git config commit.gpgsign true
```
