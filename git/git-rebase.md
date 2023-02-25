## git rebase 

```
git rebase [-i | --interactive] [options]  [--onto <newbase>]
               [<upstream> [<branch>]]

git rebase --continue | --skip | --abort | --quit 
```


- 关于 `-i` 选项的交互命令.

1. pick, 就是使用当前 commit, 不做任何修改

2. reword, 在 pick 的同时可以编辑 commit 消息.

3. edit, 在 pick 的同时, 会在当前记录停止, 后续可以编辑信息(git操作). 最后需要使用 `git rebase --continue` 进行提交, 或者 `git rebase --abort`
撤销此次 rebase

4. squash, 合并当前记录到前一个记录中, 并把当前 commit 消息也合并进去(需要进行编辑).

5. fixup, 合并此条记录到前一个记录中, 但是忽略当前 commit 消息.

6. drop, 删除当前提交.

> 注: 如果不指定 `-i` 选项, 则所有的 rebase 的默认操作的 `pick`.

- `--onto <newbase>`, 需要 rebase 之后进行回放操作的基础分支. 如果未指定该选项, 则该值是 `<upstream>`

- `<upstream> <branch>`, 进行 rebase 的 commit 范围.


### 案例

1. 拆分历史某个提交

当前分之提交:
```
D---E---F---G master
```

拆分后的效果:
```
D---E---F1---F2---G' master
```

操作:

```
# 交互模式下, 使用 edit 命令修改需要拆分的提交
git rebase -i E [master|HEAD]

# 重置当前提交(注: 这里不是hard模式)
git reset HEAD^

# after do change 1
git add -A && git commit -m "F1"

# after do change 2
git add -A && git commit -m "F2"

# 继续变基. 直到所有变基操作完成. (完成变基操作后, 会应用到当前分支)
git rebase --continue
```


2. 合并历史某几个连续的提交为1个. 

当前分之提交:
```
D---E---F---G master
```

合并后的效果:
```
D---EF---G master
```

操作:
```
# 交互模式下, 使用 squash 合并提交, 注意 commit 提交的顺序
git rebase -i D [master|HEAD]

# 给变基重新命名分支
git checkout -b new
```

3. 将某几个提交应用到某个分支上

当前分之提交:
```
      A---B---C--X topic
     /
D---E---F---G master
```

合并后的效果:
```
      A---B---C--X topic
     /
D---E---F---G---B'---C' master
```


操作:
```
# 交互模式下, 使用 pick 命令修改需要拆分的提交
git rebase -i --onto master A C

# 切换, 重置
git rebase HEAD master 
```

