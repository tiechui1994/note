## sed 

sed 介绍:

sed意为流编辑器(Stream Editor), 在Shell脚本和Makefile中作为过滤器使用非常普遍,也就是把前一个程序的输出引入sed的
输入, 经过一系列编辑命令转换为另一种格式输出. sed和vi都源于早期UNIX的ed工具, 所以很多sed命令和vi的末行命令是相同的.


### sed 使用

格式:

```
sed option 'script' file ...
sed option -f scriptfile file ...
```

sed处理的文件既可以由标准输入重定向得到, 也可以当命令行参数传入, 命令行参数可以一次传入多个文件, sed会依次处理.

sed的编辑命令可以直接当命令行参数传入, 也可以写成一个脚本文件然后用-f参数指定.


- option 参数:

- `-n, --quiet` 只打印模式匹配的行
- `-e express` 直接在命令行模式上进行sed动作编辑,此为默认选项
- `-i` 直接修改文件内容
- `-r, --regexp-extended` 使用正则匹配表达式



行寻址方式:

默认情况下, 在sed中使用的命令会作用于文本数据的所有行, 如果只想将命令作用于特定的行或者某些行, 则需要使用"行寻址"功能.

sed 中包含两种形式的行寻址: `数字形式表示的行区间` 和 `文本模式匹配行`

命令语法: `[address]command`

- 数字形式的行寻址:

1. `sed -n '3 p' file`      address形式: N       N表示一个数字
2. `sed -n '$ p' file`      address形式: $       $代表最后一行
3. `sed -n '3,6 p' file`    address形式: N, M    N, M表示一个数字, 表示 N ~ M 行
4. `sed -n '3,+4 p' file`   address形式: N,+M    N, M表示一个数字, 表示 N ~ N+M 行
5. `sed -n '10~3 p' file`   address形式: N~M     N, M表示一个数字, 表示从N行开始, 每第M行(循环)

- 文本模式的行寻址:

1. `/pattern/ command` 单个模式匹配(所有匹配pattern的行).

```bash
sed -n '/^root/ p' file
```

2. `/pattern/, /pattern/ command` 两个模式匹配(首次匹配第一个pattern 到 首次匹配第二个pattern之间的行).

```bash
sed -n '/^root/, /www/ p' file
```

3. `/pattern/, N command` 首次匹配第一个pattern 直到 第N行为止. 所有匹配pattern的行.

```bash
sed -n '/^root/, 10 p' file
```

4. `/pattern/, +N command` 匹配第一个pattern 往后N行.

```bash
sed -n '/^root/, +5 p' file
```
   

- 执行命令(command):

```
p  打印
d  删除

a\text   行 "后面" 添加text
i\text   行 "前面" 添加text
c\text   使用 text "替代" 当前行

s/pattern1/pattern2/   将该行 "第一个" 匹配pattern1的字符串替换为pattern2
s/pattern1/pattern2/g  将该行 "所有" 匹配pattern1的字符串替换为pattern2

w file 文件写入命令. 将模式空间中的内容写入到文件. file是文件名称. 当文件不存在时, 会自动创建, 如果文件已经存在,
则会覆盖原文件的内容
r file 文件读取命令. 从外部文件中读取内容并且在满足条件的时候显示出来. 注意: r命令和文件名之间必须只有一个空格

e [command] sed当中执行外部命令command. 在没有提供外部命令的时候,sed 会将模式空间中的内容作为要执行的命令.

! 排除命令, 让原本会起作用的命令不起作用

q [value] 退出命令, 退出当前的执行流. 只支持单个地址匹配. value是可选的退出返回值
```

- 常用的技能:

1. 在 "匹配的行" 的前一行或后一行添加内容

```bash
#匹配行前前
sed -i '/allow 361way.com/i\allow www.361way.com' the.conf.file

#匹配行前后
sed -i '/allow 361way.com/a\allow www.361way.com' the.conf.file
```

2. 在 "具体行号" 的前一行或后一行添加内容

```bash
#匹配行前前
sed -i '2i\allow www.361way.com' the.conf.file

#匹配行前后
sed -i '2a\allow www.361way.com' the.conf.file
```

3. 删除 "匹配的行"

```bash
#删除匹配行
sed -i '/allow 361way.com/d' the.conf.file

#删除匹配行的后一行
sed -i '/allow 361way.com/{n;d}' the.conf.file
```


### sed空间:

- 模式空间:

对任何文件的来说,最基本的操作就是输出它的内容,为了实现该目的,在sed中可以使用print命令打印出模式空间中的内容. 
上述的行寻址属于模式空间.

- 保持空间:

在处理模式空间中的某些行时,可以用保持空间来临时保存一些行. 有5条命令可用来操作保持空间.

```
h 将模式空间复制到保持空间
H 将模式空间附加到保持空间
g 将保持空间复制到模式空间
G 将保持空间附加到模式空间
x 交换模式空间和保持空间的内容
```

