# git submodule

## 子模块产生的背景

面对比较复杂的项目, 我们有可能会将代码根据功能拆解成不同的子模块. 主项目对子模块有依赖关系, 却又并不关心子模块的内部
开发流程细节.

这种情况下, 通常不会把所有源码都放在同一个 Git 仓库中.

一种简单的方式, 在当前工作目录下, 将子模块文件夹加入到 `.gitignore` 文件当中, 这样主项目就可以无视子模块的存在. 这
么做的问题在于, 使用主项目的人需要知道子模块的版本.

另一种方式, 就是使用 Git 的 `submodule` 功能. `submodule` 的功能就是建立当前项目与子模块之间的依赖关系(`子模块路
径`, `子模块的远程仓库`, `子模块的版本号`)


## 子模块操作

### 创建 submodule

使用 `git submodule add <remote_url>` 命令可以在项目中创建一个子模块.

```
$ git submodule add git@github.com:tiechui1994/tool.git tool
正克隆到 '/tmp/www/project/tool'...
remote: Enumerating objects: 791, done.
remote: Counting objects: 100% (188/188), done.
remote: Compressing objects: 100% (126/126), done.
remote: Total 791 (delta 113), reused 112 (delta 60), pack-reused 603
接收对象中: 100% (791/791), 791.70 KiB | 434.00 KiB/s, 完成.
处理 delta 中: 100% (437/437), 完成.
```

此时, 在项目目录仓库当中会多出两个文件: `.gitmodules` 和 `tool`. 

`.gitmodules` 当中记录了子模块的相关信息. `tool`, 实际上保持的是子模块当前版本的版本号信息.

```
[submodule "tool"]
    path = tool
    url = git@github.com:tiechui1994/tool.git
```

此时在 `.git/config` 当中会增加一条子模块信息 `[submodule "tool"]`, 在 `.git/modules` 文件夹下记录子模块 `tool`
的 `.git` 信息. 在 `tool` 目录当中的 `.git` 目录会指向主项目的 `.git/modules` 下的 `tool` 文件夹.


### 获取 submodule

方式一:

使用 `git clone <remote_url>` 获取仓库, 但是此时子模块只是一个空文件夹. 下面是在主项目下更新子模块操作:

```
# before clone project, submodule status
$ git submodule status 
-edcc3323fc44ed33b8ae89a18c5dc38a0efd4885 tool

# 初始化子模块
$ git submodule update --init tool

# after init, submodule status
$ git submodule status
 edcc3323fc44ed33b8ae89a18c5dc38a0efd4885 tool (remotes/origin/develop)
```

方式二:

使用 `git clone --recurse-submodules <remote_url>` 获取仓库, 并初始化子模块.


### 更新 submodule

```
# first commit submodule and push, check HEAD version
$ git commit -m "submodule update"
$ git rev-parse HEAD 

# check to parent, check submodule version, check equals. 
$ git submodule

# update main project commit and push
$ git add -A
$ git commit -m "update submodule version"
```

子模块内容的更新

对于子模块而言, 不需要知道引用自己的主项目的存在. 对于子模块自身, 其就是一个完整的 Git 仓库, 按照正常的 Git 代码管
理规范操作即可.

对主项目而言, 子模块的内容发生变动时, 通常有三种情况:

1) 当前项目子模块文件夹内容发生了未追踪(未添加到本地暂存区)的内容变动;

2) 当前项目子模块文件夹的内容发生了版本变化(本地已提交);

3) 当前项目子模块文件夹内的内容未变, 其远程仓库有变更;

> 情况1: 子模块有未追踪的内容变动

这种情况通常发生在开发环境, 直接修改子模块文件夹中的代码导致的. 此时在主项目中使用 `git status` 能够看到关于子模块
尚未暂存以备提交的变更, 但是对于主项目是无能为力, 使用 `git add/commit` 对其不会产生影响.

```
$ git status 
位于分支 main
您的分支与上游分支 'origin/main' 一致。

尚未暂存以备提交的变更：
  （使用 "git add <文件>..." 更新要提交的内容）
  （使用 "git checkout -- <文件>..." 丢弃工作区的改动）
  （提交或丢弃子模组中未跟踪或修改的内容）

        修改：     tool (未跟踪的内容)

修改尚未加入提交（使用 "git add" 和/或 "git commit -a"

$ git diff
diff --git a/tool b/tool
--- a/tool
+++ b/tool
@@ -1 +1 @@
-Subproject commit d8fbfde3d0b328f4fe3a91854c0cbdda71d6e63f
+Subproject commit d8fbfde3d0b328f4fe3a91854c0cbdda71d6e63f-dirty
```

这种情况下, 通常需要进入子模块内部的版本控制提交代码到远程仓库. 完成之后, 进入情况2.

> 情况2: 子模块有版本变化

```
$ git status 
位于分支 main
您的分支落后 'origin/main' 共 1 个提交，并且可以快进。
  （使用 "git pull" 来更新您的本地分支）

尚未暂存以备提交的变更：
  （使用 "git add <文件>..." 更新要提交的内容）
  （使用 "git checkout -- <文件>..." 丢弃工作区的改动）

        修改：     tool (新提交)

修改尚未加入提交（使用 "git add" 和/或 "git commit -a"）
```

这种情况下, 在主项目当中将使用 `git add/commit` 将变更提交. 其实本质上就是修改子模块 `文件`.

```
$ diff --git a/tool b/tool
index d8fbfde..933a178 160000
--- a/tool
+++ b/tool
@@ -1 +1 @@
-Subproject commit d8fbfde3d0b328f4fe3a91854c0cbdda71d6e63f
+Subproject commit 933a1784fe0c27cfb534bdd71b1b065422ee42ff
```

> 情况3: 子模块远程有更新

一般情况下, 主项目与子模块是同时进行开发的. 通常是子模块负责维护自己的版本升级后, 推送到远程仓库, 并告知主项目可以更
新对子模块的版本依赖.

之前提到过 `子模块获取` 时, 可以使用 `git submodule update` 更新子模块的代码, 但是那是特指 `当前主项目文件夹下的
子模块目录内容` 与 `当前主项目记录的子模块版本` 不一致时, 会参考后者去更新前者.

但是, 如今的情况是 `当前主项目记录的子模块版本` 还没有变化, 在主项目看来当前情况一切正常.

此时, 需要进入主项目的子模块, 拉取子模块的代码, 进行升级操作. 当子模块目录下代码版本发生变化, 转到情况2的流程进行主
项目的提交.

不同场景下子模块更新方式如下:

对于子模块, 只需要管理好自己的版本, 并推送到远程分支即可;

对于父模块, 若子模块版本信息未提交, 需要更新子模块目录下的代码, 并执行 commit 操作提交子模块版本信息;

对于父模块, 若子模块版本信息已提交, 需要使用 `git submodule update`, Git 会自动根据子模块版本信息更新所有子模块
目录的相关代码.

### 删除 submodule

子模块相关的内容: `子模块文件夹`, `.gitmodules`, `.git/config`, `.git/modules`

卸载子模块: `git submodule deinit <path>`, 该命令会移除 `.git/config` 当中子模块的信息.

删除子模块: `git rm <path>`, 该命令会删除 `子模块文件夹`, 自动删除 `.gitmodules` 当中子模块配置信息.

此时, 主项目当中关于子模块的信息基本上被删除(还剩下 `.git/modules` 目录下的残余), 此时可以使用命令 `gs` 清除掉残
留的文件. 之后进行提交, 推送到远程, 完成对子模块的删除.


## 子模块 submodule 时遇到的问题

1) 问题 `fatal: Needed a single revision, Unable to find current revision in submodule path 'xxx'` 或
`Fetched in submodule path 'xxx', ... Direct fetching of that commit failed`

解决方案之一: (手动 clone submodule)

```
# 删除老的目录
rm -rf xxx

# clone 到指定 commit 的提交
git clone git@github.com:example/xxx.git --branch=develop xxx

# 检查 submodule 的版本
$ git submodule 
-94babad95c5832f747b14e16fbc664258c5a3919 alarm
 ed32cdbf5e778e213f78d7126159147417e3c45d xxx (v1.0.0-9-ged32cdb)
-8c8272f678bf2ab50d0e8229dc37dbc479ef7d68 testtool

`+`, ` `, `-` 的含义如下 
带有 `+` 表示 submodule 版本未提交
带有 ` ` 表示 submodule 已经提交/初始化
带有 `-` 表示 submodule 未被初始化, 需要进行初始化
```

解决方案之二: (如果只是配置了 ssh 秘钥, 没有 http 拉取子模块的权限, 则可以更新 pull 代码方式)

```
[url "ssh://git@github.com"]
	insteadof = https://github.com
```

> 这种场景就是 .gitmodules 当中配置的 submodule 的 url 是 https 方式的私有仓库, 则需要转换成 git 方式去拉去代码.


注: 方式一与方式二的不同之处在于子模块下的 .git 文件, 对于方式一, .git 是一个目录, 里面单独记录子模块的信息. 对于方
式二, .git 是一个文件, 其指向更上一层级的 .git 目录.
