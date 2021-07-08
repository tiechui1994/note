## git show

`git show` 显示各种类型的对象.

显示一个或多个对象(二进制大型对象, 树, 标签和提交).

对于提交, 它显示日志消息和文本差异. 它还以特殊格式显示合并提交 `git diff-tree -cc`.

对于标签, 它显示标签信息和引用的对象.

对于树, 它显示名称(相当于`git ls-tree`)

对于二进制大型对象, 它显示简单的内容.


### 命令使用

```
git show [options] <object> ...
```

格式化选项:

- `--pretty=<format>, --format=<format>` 给定格式打印提交日志的内容. format 可以是 `oneline`, `short`, `medium`,
`full`, `fuller`, `email`, `raw`, `format:<string>`. 

1) `oneline`
```
<sha1> <title>
```

2) `short`
```
commit <sha1>
Author: <author>
<title>
```

3) `medium`
```
commit <sha1>
Author: <author>
Date: <date>
<title>
```

4) `full`
```
commit <sha1>
Author: <author>
Commit: <commit>
<title>
```

5) `fuller`
```
commit <sha1>
Author: <author>
AuthorDate: <date>
Commit: <commit>
CommitDate: <date>
<title>
```

6) `email`
```
From <sha1> <date>
From: <from>
AuthorDate: <date>
Date: <date>
Subject: <title>
```

7) `raw`
```
commit <sha1>
tree <sha1>
parent <sha1>
author <author>
committer <author>
<title>
```

8) `format:<string>`

差异选项:

- `-p -u --patch`, 生成补丁. 生成的内容可以通过 `patch` 命令进行差异化更新.

- `-s --no-patch`, 抑制差异输出. `git show` 默认显示补丁.

- `--name-only`, 仅仅显示更改文件的名称.

- `--name-status`,  仅仅显示更改文件的状态和名称.

- `--diff-filter=[(A|C|D|M|R|T|U|X|B)]`, 只选择已添加(A), 已复制(C), 已删除(D), 已修改(M), 以重命名(M), 已更改(T),
以取消合并(U), 未知(X), 已破坏(B)的文件.

- `--numstat`, 显示十进制表示法中添加和删除的行数, 以及不带缩写的路径名称. 例如 `git show --format=format: --numstat`

- `--shortstat`, 单行显示文件总的添加和删除的行数. `git show --format=format: --shortstat`.
