## git diff

### git diff 基础相关命令

```
git diff [--options] [--] [<path>...]
用于查看相对于索引(下一次提交的暂存区域)所做的更改. 换句话说, diff 就是告诉 git 进一步添加到索引中的内容, 但仍然没有提
交到本地仓库. 可以使用git-add进行这些更改.

git diff [--options] --cached [<commit>] [--] [<path>...]
用于查看相对于命名的<commit>(产生分支)为下一次提交(本地仓库)所做的更改. 通常, 与最新提交进行比较, 因此, 如果不提供
<commit>, 则默认为HEAD. 如果HEAD不存在(例如, unborn branch) 并且未给出<commit>, 它将显示所有已分阶段的更改. 
--staged 是 --cached 的同义词.


git diff [--options] <commit> [--] [<path>...]
用于查看相对于命名的<commit>(产生分支)在工作树中的更改. 可以使用 HEAD 将其与最新提交进行比较, 也可以使用分支名称与其他
分支的HEAD进行比较.

git diff [--options] <commit> <commit> [--] [<path>...]
用于查看任意两个提交之间的更改


git diff [--options] <commit>..<commit> [--] [<path>...]
用于查看任意两个提交之间的更改


git diff [--options] <commit>...<commit> [--] [<path>...]
用于查看 "第一个<commit>和第二个<commit>的共同祖先" 到 "第二个<commit>" 之间的更改, 该更改始于两个<commit>的共同
祖先. "git diff A...B" 等效于 "git diff $(git-merge-base A B) B". 可以省略 <commit> 中的任何一个, 其效果与
使用HEAD相同.
```