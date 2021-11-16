# sed 

sed 介绍:

sed意为流编辑器(Stream Editor), 在Shell脚本和Makefile中作为过滤器使用非常普遍,也就是把前一个程序的输出引入sed的
输入, 经过一系列编辑命令转换为另一种格式输出. sed和vi都源于早期UNIX的ed工具, 所以很多sed命令和vi的末行命令是相同的.


## sed 使用

格式:

```
sed option 'script' file ...
sed option -f scriptfile file ...
```

sed处理的文件既可以由标准输入重定向得到, 也可以当命令行参数传入, 命令行参数可以一次传入多个文件, sed会依次处理.

sed的编辑命令可以直接当命令行参数传入, 也可以写成一个脚本文件然后用-f参数指定.


### option 参数:

- `-n, --quiet, --silent` 只打印模式匹配的行
- `-e express` 添加 "脚本" 到程序的运行列表, 此为默认选项
- `-f script` 或 `--file=script` 添加 "脚本文件" 到程序的运行列表
- `-i` 直接修改文件内容
- `-r, --regexp-extended` 使用正则匹配表达式
- `-s, --seprate` 将输入文件视为各个独立的文件而不是一个长的连续输入.


行寻址方式:

默认情况下, 在sed中使用的命令会作用于文本数据的所有行, 如果只想将命令作用于特定的行或者某些行, 则需要使用"行寻址"功能.

sed 中包含两种形式的行寻址: `数字形式表示的行区间` 和 `文本模式匹配行`

命令语法: `[address] command`

### 数字形式的行寻址(以打印`p`命令为例):

1. `sed -n '3 p' file`      address形式: N       N表示一个数字
2. `sed -n '$ p' file`      address形式: $       $代表最后一行
3. `sed -n '3,6 p' file`    address形式: N, M    N, M表示一个数字, 表示 N ~ M 行
4. `sed -n '3,+4 p' file`   address形式: N,+M    N, M表示一个数字, 表示 N ~ N+M 行
5. `sed -n '10~3 p' file`   address形式: N~M     N, M表示一个数字, 表示从N行开始, 每第M行(循环)

### 文本模式的行寻址(以打印`p`命令为例):

1. `/pattern/ command` 单个模式匹配(所有匹配pattern的行).

```bash
sed -n '/^root/ p' file
```

2. `/pattern/, /pattern/ command` 两个模式匹配(首次匹配第一个 pattern 到 首次匹配第二个pattern之间的行).

```bash
sed -n '/^root/, /www/ p' file
```

3. `/pattern/, N command` 首次匹配第一个 pattern 直到第N行为止. 所有匹配pattern的行.

```bash
sed -n '/^root/, 10 p' file
```

4. `/pattern/, +N command` 匹配第一个 pattern 往后N行.

```bash
sed -n '/^root/, +5 p' file
```

5. `command` 匹配全文所有的行(经常使用)

```bash
sed -n 'p' file
```

### 命令(command):

```
a\text   在当前行 "后面" 添加text
i\text   在当前行 "前面" 添加text
c\text   使用 text "替换" 当前行

d  删除, 删除选择的行
D  删除, 删除模板块的第一行

p  打印模板块
P  打印模板块的第一行

# 注: 替换前后的 / 是必须的, 不能缺少
s/pattern1/pattern2/   将当前匹配行 "第一个" 匹配pattern1的字符串替换为pattern2
s/pattern1/pattern2/g  将当前匹配行 "所有" 匹配pattern1的字符串替换为pattern2
s/pattern1/pattern2/p  将当前匹配行 "第一个" 匹配pattern1的字符串替换为pattern2, 并打印输出

w file 文件写入命令. 将模式空间中的内容写入到文件. file是文件名称. 当文件不存在时, 会自动创建, 如果文件已经存在,
则会覆盖原文件的内容
r file 文件读取命令. 从外部文件中读取内容并且在满足条件的时候显示出来. 注意: r命令和文件名之间必须只有一个空格

e [command] sed当中执行外部命令command. 在没有提供外部命令的时候,sed 会将模式空间中的内容作为要执行的命令.

! 排除命令, 让原本会起作用的命令不起作用

q [value] 退出命令, 退出当前的执行流. 只支持单个地址匹配. value是可选的退出返回值

h  拷贝模板块的内容到内存的缓冲区
H  追加模板块的内容到内存的缓冲区

g  获得内存的缓冲区的内容, 并替换到当前模板块的文本
G  获得内存的缓冲区的内容, 并追加到当前模板块文本的后面
```

### 案例:

1. 在 "匹配的行" 的前一行或后一行添加内容

```bash
# 匹配行之前
sed -i '/^allow/ i\allow www.361way.com' the.conf.file

# 匹配行之后
sed -i '/^allow/ a\allow www.361way.com' the.conf.file
```

使用模式匹配寻址 `/^allow/`, 命令是 `i\xxx` 或 `a\xxx`

2. 在 "具体行号" 的前一行或后一行添加内容

```bash
# 匹配行之前
sed -i '2 i\allow www.361way.com' the.conf.file

# 匹配行之后
sed -i '2 a\allow www.361way.com' the.conf.file
```

使用行号寻址 `2`, 命令是 `i\xxx` 或 `a\xxx`


3. 删除 "匹配的行"

```bash
#删除匹配行
sed -i '/allow/ d' the.conf.file

#删除匹配行的后一行
sed -i '/allow/ {n;d}' the.conf.file
```

使用模式匹配寻址 `/^allow/`, 命令是 `d` 或 `{n;d}`(比较特殊)

4. 替换

```bash
# 匹配的行只替换一次
sed -i '/allow/ s/^aa/xyz/' the.conf.file

# 匹配的行只替换所有
sed -i '/allow/ s/^aa/xyz/g' the.conf.file

# source源替换
sed -n '/^[^#]/ s|http://us.archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|p' source.list
```

使用模式匹配寻址 `/allow/`, 命令是 `s/^aa/xyz/` 或 `s/^aa/xyz/g`

使用模式匹配寻址 `/^[^#]/`, 命令是 `s|http://us.archive.ubuntu.com|https://mirrors.tuna.tsinghua.edu.cn|p`,
这里使用 `|` 作为分隔符, 默认是 `/`

5. 复制修改

```bash
sed -n '/^[^#]/ s|http://us.archive.ubuntu.com|&.cn|p' source.list
```

使用模式匹配寻址 `/^[^#]/`,  命令是 `s|http://us.archive.ubuntu.com|&.cn|p`.

> `&` 用来保存搜索字符以其替换其他字符, 如 `s/love/**&**/`, love这成 `**love**`.

6. 正则匹配(分组匹配)

```bash
sed -n -r '/^s/ s|([a-z\-]+):x:([0-9]+)|\1-link-\2|p' /etc/passwd
```

详情:

```
# before
sys:x:3:3:sys:/dev:/usr/sbin/nologin
sync:x:4:65534:sync:/bin:/bin/sync
systemd-network:x:100:102:systemd Network Management,,,:/run/systemd/netif:/usr/sbin/nologin
systemd-resolve:x:101:103:systemd Resolver,,,:/run/systemd/resolve:/usr/sbin/nologin
syslog:x:102:106::/home/syslog:/usr/sbin/nologin
sshd:x:109:65534::/run/sshd:/usr/sbin/nologin

# after
sys-link-3:3:sys:/dev:/usr/sbin/nologin
sync-link-4:65534:sync:/bin:/bin/sync
systemd-network-link-100:102:systemd Network Management,,,:/run/systemd/netif:/usr/sbin/nologin
systemd-resolve-link-101:103:systemd Resolver,,,:/run/systemd/resolve:/usr/sbin/nologin
syslog-link-102:106::/home/syslog:/usr/sbin/nologin
sshd-link-109:65534::/run/sshd:/usr/sbin/nologin
```

使用模式匹配寻址 `/^s/`, 命令是 `s|([a-z\-]+):x:([0-9]+)|\1-link-\2|p`

> `\1`, `\2` 用来代表分组匹配的结果, 与 `&` 类似.


7. 内存拷贝替换

```bash
sed  '/root/ h; /mysql/ g' passwd
```

使用模式匹配寻址 `/root/`,  命令是 `h`(将当匹配行拷贝到内存的缓冲区).

使用模式匹配寻址 `/mysql/`, 命令是 `g`(从内存的缓冲区当中获取内容, 并替换当前模板块的文本).

```
# before
root:x:0:0:root:/root:/bin/bash
mysql:x:999:999::/home/mysql:/bin/sh

# after
root:x:0:0:root:/root:/bin/bash
root:x:0:0:root:/root:/bin/bash
```
