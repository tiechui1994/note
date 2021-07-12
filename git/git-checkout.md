## git checkout

`git-checkout` 的作用是 `切换分支 或 还原工作树的文件(撤销修改的文件)`

### 命令

```
git checkout [-q] [-f] [-m] [<branch>]
git checkout [-q] [-f] [-m] --detach [<branch>]
git checkout [-q] [-f] [-m] [--detach] <commit>
git checkout [-q] [-f] [-m] [[-b|-B|--orphan] <new_branch>] [<start_point>]
git checkout [-f|--ours|--theirs|-m|--conflict=<style>] [<tree-ish>] [--] <paths>...
git checkout [-p|--patch] [<tree-ish>] [--] [<paths>...]
```

- `git checkout <branch>`

切换分支. 要准备在 `<branch>` 上工作, 通过更新工作树中的index和files, 并将 `HEAD` 指向 `branch` 来切换到该分支.
保留对工作树中文件的本地修改, 以便可以将其提交给 `<branch>`.

如果未找到`<branch>`, 但确实在一个具有匹配名称的远程站点 (称为 `<remote>` ) 中存在跟踪分支, 则等价的命令是:

```
git checkout -b <branch> --track <remote>/<branch>
```

- `git checkout -b|-B <new_branch> [<start point>]`

指定 `-b` 将导致创建新分支, 就像是先调用git-branch, 然后将其检出一样. 在这种情况下, 可以使用 `--track` 或 `--no-track` 
选项, 这些选项将传递到git分支.

如果是 `-B` 选项, 当 `<new_branch>` 分支不存在的时, 将创建分支 `<new_branch>`. 如果 `<new_branch>` 已经存在, 
则它将被重置. 等价的命令如下:

```
git branche -f <branch> [<start point>]
git checout <branch>
```

- `git checkout --detach [<branch>], git checkout [--detach] <commit>`

准备在 `<commit>` 上工作, 方法是分离HEAD, 并更新工作树中的索引和文件. 保留了对工作树中文件的本地修改, 因此生成的工作
树将是提交中记录的状态加上本地修改.

当 `<commit>` 参数是分支名称时, `--detach` 选项可用于在分支的尖端分离HEAD (`git checkout <branch>` 将在不分离
HEAD的情况下检出该分支).

省略 `<branch>` 会在当前分支的尖端分离 HEAD.

- `git checkout [-p|--patch] [<tree-ish>] [--] <pathspec>...`

当给出 `<paths>` 或 `--patch` 时, `git checkout` 不会切换分支. 它从索引文件或命名的 `<tree-ish>` (通常是提交)
更新工作树中的命名路径.  在这种情况下, `-b` 和 `--track` 选项没有意义, 并且给它们中的任何一个都将导致错误. `<tree-ish>`
参数可用于指定特定的树状结构(即 commit, tag 或 tree), 以在更新工作树之前更新更新给定路径的索引.

带有 `<paths>` 或 `--patch` 的 git checkout 用于将已修改或已删除的路径从索引恢复到其原始内容, 或将路径替换为已命名
的 `<tree-ish>` (通常是的 commit-ish) 中的内容.

#### 选项参数

- `-f, --force`

切换分支时, 即使索引或工作树与HEAD不同, 也要继续进行. 这用于丢弃本地更改.

从索引中检出路径时, 不要在未合并的条目上失败; 相反, 未合并的条目将被忽略.
            
- `--ours, --theirs`


- `-b <new_branch>`

创建一个名为<new_branch>的新分支, 并在<start_point>处启动它.

- `-B <new_branch>`

创建分支 <new_branch> 并在 <start_point> 处启动它; 如果已经存在, 则将其重置为 <start_point>. 这等效于用 "-f" 运
行"git branch"

- `-t, --track`

创建新分支时, 设置 "upstream" 配置.

如果未给出 `-b` 选项, 则通过查看为相应的远程配置的refspec的本地部分, 然后将初始部分剥离为 "*", 将从远程跟踪分支派生新
分支的名称. 这将告诉我们在分支 "origin/hack"(或 "remotes/origin/hack", 甚至 "refs/remotes/origin/hack") 时
使用 "hack" 作为本地分支. 如果给定名称没有斜杠, 或者上述猜测结果为空名称, 则猜测被中止. 在这种情况下, 可以使用 `-b 显
式命名.

- `--no-track`

即使 `branch.autoSetupMerge` 配置变量为true, 也不要设置 "upstream" 配置.

- `-l`

- `--detach`

- `-m, --merge`

- `-p, --patch`
