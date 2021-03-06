# rsync

rsync (Remote Sync), 是 Unix 系统下的数据镜像备份工作. 可以实现本地, 远程备份. 

特性:

- 可以保持文件原来的权限, 时间, 所有者, 组信息, 软硬链接等
- 可以从远程或者本地镜像保存整个目录树和文件系统
- 快速: 要比 scp (Secure Copy) 要快; 第一次同步时 rsync 会复制全部内容, 但在下一次只会传输修改过的文件. rsync 在
传输数据过程中可以实时压缩及解压操作.
- 安全: 可以使用 scp, ssh 等方式传输文件, 当然也可以通过直接的socket连接.
- 支持匿名传输


rsync 常用的 3 种格式:

```
# 本地模式
rsync [OPTION] SRC DEST

# 远程 push
rsync [OPTION] SRC [USER@]HOST:DEST

# 远程 pull
rsync [OPTION] [USER@]HOST:SRC DEST
```

常用的参数:

- `-v, --verbose`, verbose 详细输出
- `-a, --archive`, **归档模式, 表示以递归方式传输文件, 并保持文件的属性**
- `-r, --recursive`, **对子目录以递归处理**

- `-b, --backup`, **将在传输或删除每个文件时重命名先前存在的目标文件. 可以使用--suffix 和 --backup-dir 选项
控制备份文件的目录和备份文件后缀.**
- `--backup-dir=DIR`, 将备份文件(如filename~)存放在目录下.
- `--suffix=SUFFIX`, 备份文件的后缀. 默认是 `~`

- `-z --compress`, 压缩文件传输
- `--compress-level=NUM`, 压缩级别

- `-h`, 输出友好

- `-u, --update`, **跳过已经存在的文件, 备份更新**
- `--inplace`, 更改 rsync 在需要更新其数据时传输文件的方式: rsync直接直接将更新的数据写入到目标文件中. ( 默认方式:
先文件新副本, 然后将文件副本重命名). 

存在的影响:

```
1. 使用中的二进制文件无法更新(操作系统阻止此种情况的发生)
2. 传输过程中文件的数据将处于不一致状态.
3. rsync 无法写入的文件将无法更新. root可以更新任何文件, 但需要授予普通用户打开文件的写权限才能成功进行写操作.
```

- `--append`, rsync 通过数据追加到文件末尾来更新文件. 这假定接收方已经存在的数据和发送方的文件开头相同. 如果文件需要
传输并且接收方的大小等于或大于发送方的大小, 则跳过该文件. 

- `--append-verify`, 与 `--append` 选项一样, 但完整文件校验和验证步骤中包括接收方的现有数据, 如果最终验证步骤失败,
则会导致文件被重新传输.


- `--filter=PATTERN`, filter 规则允许灵活选择要传输(include)的文件和要跳过(exclude)的文件.

rsync 的 filter 规则语法:

```
RULE [PATTERN_OR_FILENAME]

RULE, MODIFIERS [PATTERN_OR_FILENAME]
```

> 可以选择使用短或长规则名称, 如下所述. 如果使用短命名规则, 则将 RULE 与 MODIFIERS 分开的 `,` 是可选的. 后面的 
PATTERN 或 FILENAME (如果存在) 必须在单个空格或下划线 `_` 之后. 

下面是可以的规则前缀:

```
exclude, - 指定排除模式
include, + 指定包含模式
merge, . 指定一个合并文件以读取更多规则
dir-merge, : 指定每个目录的合并文件
hide, H 指定用于从传输中隐藏文件的模式
show, S 非隐藏文件模式
protect, P 指定一种保护文件不被删除的模式
risk, R 与模式匹配的文件不受保护
clear, ! 清除当前的include/exclude 列表(不带参数)
```

> 从文件中读取规则时, 空行和以"#"开头的注释行将被忽略.

> `--filter`, `--include`, `--exclude` 选项各采用一个规则/模式. 要添加多个选项, 可以在命令行上多次使用这些选项.

合并文件有两种方式: 单个文件 `merge` ('.'), 和 目录 `dir-merge` (':').

example:

```
merge /ect/rsync/default.rules
. /ect/rsync/default.rules

dir-merge .per-dir-filter
dir-merge,n- .non-inherited-per-dir-excludes
:n- .non-inherited-per-dir-excludes
```

- `C 是一种指定应以CVS兼容方式读取文件的方式. 这会启用 "n", "w" 和 "-", 但也允许指定清除列表的标记(!). 如果未提供文
件名, 则假定为 ".cvsignore"`.

> - `n` 表示规则不被子目录继承.
> - `w` 表示规则使用空格进行分割, 而不是常规的行分割. 注: 此时 `- foo + bar` 会被解析成两个规则.

- `e 将从传输中排除合并文件名.` 例如 "dir-merge,e .rules" => "dir-merge .rules" 且 "- .rules".


```bash
cat <<EOF | rsync -avC --filter='. -' src/ dst
+ foo.o
:C
- *.old
EOF

rsync -avC --include='foo.c' --filter=':C' --exclude='*.old' src/ dst
```



```bash
# 只同步 .git 目录下的文件
rsync --filter ': .git' /src/path /dst/path
```

- `--exclude=PATTERN`
- `--include=PATTERN`

- `--exclude-from=FILE`
- `--include-from=FILE`



