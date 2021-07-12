## git remote

管理追踪其分支的存储库集("remotes")

```
git remote [-v | --verbose]
git remote add [-t <branch>] [-m <master>] [-f] [--[no-]tags] [--mirror=<fetch|push>] <name> <url>
git remote rename <old> <new>
git remote remove <name>
git remote set-head <name> (-a | --auto | -d | --delete | <branch>)
git remote set-branches [--add] <name> <branch>...
git remote get-url [--push] [--all] <name>
git remote set-url [--push] <name> <newurl> [<oldurl>]
git remote set-url --add [--push] <name> <newurl>
git remote set-url --delete [--push] <name> <url>
git remote [-v | --verbose] show [-n] <name>...
```

- `add`, 在 <url> 添加一个名为 <name> 的远程仓库. 然后可以使用命令 `git fetch <name>` 创建和更新远程跟踪分支
`<name>/<branch>`.

1) `-f` 参数, 在设置 "remote" 信息后立即执行 `get fetch <name>` 命令.

2) `--tags` 参数, `get fetch <name>` 将从远程仓库导入每个 tag.

> 默认情况下, 仅导入获取的分支上的tag

3) `-t <branch>` 参数, 代替用于追踪 `refs/remotes/<name>/` 命名空间下所有分支的refspec(默认选项), 将创建仅追踪
<branch>的 refspec. 可以使用多个 `-t <branch>` 来追踪多个分支.

4) `-m <master>` 参数, 设置符号引用 `refs/remotes/<name>/HEAD` 指向远程的 `<master>` 分支.

- `rename`: 远程仓库重命名

- `remove`: 远程仓库删除

- `set-head`: 设置或者删除远程仓库默认的branch. 对于远程仓库而言, 一个默认的branch并不是必须的, 但是允许指定远程的
名称来代替特定的分支. 例如, 如果远程仓库 origin 的默认分支设置为 master, 那么在指定 origin/master 的任何地方指定 
origin

1) `-d`, `--delete`, 将删除符号引用 `refs/remotes/<name>/HEAD` 

2) `-a`, `--auto`, 将查询远程以确定其 HEAD, 然后将符号引用 `refs/remotes/<name>/HEAD` 设置到同一分支. 例如, 
如果远程 HEAD 指向 next, 则 "git remote set-head origin -a" 会将符号引用 `refs/remotes/origin/HEAD` 设置为
`refs/remotes/origin/next`. 仅在 `refs/remotes/origin/next` 已经存在的情况下才有效; 如果不是, 则必须先获取它.

3) 使用<branch>显式设置符号引用 `refs/remotes/<name>/HEAD`. 例如, "git remote set-head origin master" 会
将符号引用 `refs/remotes/<name>/HEAD` 设置为 `refs/remotes/<name>/master`. 仅当 `refs/remotes/<name>/HEAD`
已经存在时, 这才起作用; 如果不是, 则必须先获取它.


- `set-branches`: 设置追踪的分支

- `get-url`: 获取url

- `set-url`: 设置新的 url

- `show`: 查看 remote 信息.