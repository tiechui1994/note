# git filter-branch

```
git filter-branch [--setup <command>]
                  [--env-filter <command>]
                  [--index-filter <command>]
                  [--tag-name-filter <command>]
                  [-f | --force]
                  [--prune-empty]
                  [--] [<rev-list options>...]
```

- `--prune-empty`, 某些 filter 会生成空提交, 使树保持不变. 此选项指示 git-filter-branch 删除此类提交(如果它们恰好有一个或零个未修剪的父提交); 
因此合并提交将保持完整.

- `--env-filter`, 使用此过滤器修改执行提交的环境. 具体来说, 修改提交的 author/committer name/email/time 变量

- `--index-filter`, 重写 tree 及其 content 过滤器. new tree(新文件会自动添加, 删除的文件会自动删除 - .gitignore 文件
或任何其他忽略规则都没有任何效果), 经常与 `git rm --cached --ignore-unmatch xxx` 一起使用

- `--tag-name-filter`, 重写 tag name 的过滤器. 将对指向重写对象(或指向重写对象的tag object) 的每个 tag ref 调用该过滤器.
origin tag name 通过标准输入传递, new tag name 应在标准输出中. origin tag 不会被删除, 但可以被覆盖; 使用 "--tag-name-filter cat" 来
简单地更新标签.

- `<rev-list options>`, limiting output: `--all`, `--branches` 等


### 应用案例

1. 删除某个文件的所有提交记录

```
git filter-branch --force --index-filter "git rm --cached --ignore-unmatch path/to/file" --prune-empty --tag-name-filter cat -- --all
```

2. 修改提交历史中的author信息

```
git filter-branch --env-filter 'export GIT_AUTHOR_NAME="author"; export GIT_AUTHOR_EMAIL="email";'
```
