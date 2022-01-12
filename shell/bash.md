# bash

## 参数扩展

'$' 字符引入了参数扩展, 命令替换或算数扩展. 要扩展的参数名称或符号使用大括号括起来.

- `${param:-word}`, 使用默认值. 如果 param "为空" 或 "未设置", 则替换 word 的扩展.

- `${param:+word}`, 使用替代值. 如果 param "为空" 或 "未设置", 则不替换任何内容, 否则替换 word 的扩展.

- `${param:=word}`, 分配默认值. 如果 param "为空" 或 "未设置", 则将 word 的扩展分配给参数. 然后替换参数的值. 不
能以这种方式分配 `位置参数` 和 `特殊参数`.

- `${param:?word}`, 显示错误. 如果参数 "为空" 或 "未设置", 则 word 的扩展 (或者如果 word 不存在, 则将产生一条消息)
写入标准错误, 并且 shell 如果它不是交互式的, 则退出. 否则, 参数的值被替换.


- `${param:offset}`, `${param:offset:length}`


- `${!prefix@}`, `${!prefix*}`, 变量名前缀匹配

搜索以 prefix 开头的变量名, 由 IFS 特殊变量的第一个字符分隔. 当使用 `@` 并且扩展出现在双引号内时, 每个变量名都会扩展
为一个单独的单词.


- `${!name[@]}`, `${!name[*]}`, 数组键列表.

如果 name 是一个数组变量, 则扩展为 name 中分配的数组索引(键)列表. 如果 name 不是一个数组, 则扩展为 0. 当使用 `@` 并
且扩展出现在双引号内时, 每个键都扩展为一个单独的单词.

- `${#param}`, 参数长度. 

如果 param 是 `*` 或 `@`, 则替换的值是 "位置参数的个数". 如果 param 是一个以 `*` 或 `@` 为下标的数组名, 则替换的值
是数组中的元素个数. 其他情况, 则替换的值是 param 变量的长度.


- `${param#word}`, `${param##word}`, 删除前缀匹配模式.

word 被扩展一个模式. 如果模式匹配 param 变量的前缀, 则扩展的结果是具有最短匹配模式('#') 或 最长匹配模式('##') 被删除.

如果 param 是 `@` 或 `*`, 模式移除操作将依次应用于每个位置参数, 扩展是结果列表. 如果 param 是下标为 `@` 或 `*` 的
数组变量, 模式移除操作将依次应用于数组的每个成员, 扩展的结果列表.

> 注: 这里的 word 是一个字面量字符串. 

```bash
word='*a'

param1='aaaxyz'

# word 使用变量作为字面量字符串
echo "${param1#$word}"  # aaxyz
echo "${param1##$word}" # xyz

# word 直接使用字面量字符串
echo "${param1#*a}"  # aaxyz
echo "${param1##*a}" # xyz 


param2=('aaaxyz' 'aabc' 'abc')
echo "${param2[@]#$word}"  # aaxyz abc bc
echo "${param2[*]##$word}" # xyz bc bc


echo "${@#$word}" # 位置参数最短匹配
echo "${@##$word}" # 位置参数最长匹配
```

- `${param%word}`, `${param%%word}`, 删除后缀匹配模式.

与 `删除前缀匹配模式` 类似.

> 这里的 word 是一个字面量字符串. 


- `${param/pattern/string}`, `${param//pattern/string}`, 模式替换. 

pattern 被扩展以产生一个模式. 将模式的 "最长匹配" 替换为string. 

如果 pattern 以 `/` 开头, 则 pattern 的所有匹配都被替换为字符串. 通常只替换第一个匹配的字符串. 

如果 pattern 以 `#` 开头, 则必须匹配参数扩展值的开头. 最长匹配模式.
如果 pattern 以 `%` 开头, 它必须匹配参数扩展值的末尾. 最长匹配模式.

如果 string 为空, 则删除 pattern 的匹配项, 并且可以省略 `/` 后面的 pattern. 

如果 param 是 `@` 或 `*`, 则依次对每个位置参数应用替换操作. 
如果 param 是下标为 `@` 或 `*` 的数组变量, 则对数组的每个成员依次进行替换操作.

> 这里的 pattern 是字面量字符串.

```bash
param1='bacadaxayaz'

# 一个匹配替换, 所有匹配替换
echo "${param1/a/'-'}"  # b-cadaxayaz
echo "${param1//a/'-'}" # b-c-d-x-y-z

# 前缀最长匹配
echo "${param1/#b/'-'}"  # -acadaxayaz
echo "${param1/#b*/'-'}" # -

# 后缀最长匹配
echo "${param1/%z/'-'}"  # bacadaxaya-
echo "${param1/%*z/'-'}" # -
```

- `${param^pattern}`, `${param^^pattern}`, `${param,pattern}`, `${param,,pattern}`, 大小写修改.

此扩展修改参数中字母字符的大小写. pattern 被扩展以产生一个模式, 与"pathname expansion"中一样.
 
`^` 运算符将匹配模式的小写字母转换为大写;
`,` 运算符将匹配模式的大写字母转换为小写.

`^^` 和 `,,` 扩展转换扩展值中的每个匹配字符; 

`^` 和 `,` 扩展仅匹配并转换扩展值中的第一个字符. 如果省略了 pattern , 则将其视为 `?` (匹配任意多个字符串). 

如果 param 是 `@` 或`*`, 则对每个位置参数依次应用大小写修改操作.

如果 param 是一个以 `@` 或 `*` 为下标的数组变量, 则对数组的每个成员依次应用大小写修改操作.

> 这里的 pattern 是字面量字符串.

```bash
param1='bacadaxayaz'

# 小写转大写
echo "${param1^a}"  # bAcadaxayaz
echo "${param1^^A}" # bAcAdAxAyAz

# 小写转大写, 省略 pattern, 等价于 pattern 是 ?
echo "${param1^}"   # Bacadaxayaz
echo "${param1^^}"  # BACADAXAYAZ
```

## 常见的内置命令

- exec

### 输出

- echo, printf

### 表达式相关

- eval
```
eval [args ...]

将参数作为 shell 命令执行. 将 args 组合成一个字符串, 将结果用作 shell 的输入, 然后执行结果命令.
```

- test

用法: `test [expr]`

计算表达式的值. 根据 expr 的计算结果, 退出状态为 0(真), 1(假).  表达式可以是一元或二元的. 一元表达式通常用于检查文件
的状态. 

文件状态操作:
```
-a FILE 文件存在
-e FILE 文件存在
-s FILE 文件非空

-b FILE 块文件
-c FILE 字符文件
-p FILE 管道文件

-f FILE 普通文件
-L FILE 符号链接文件
-d FILE 目录

-r FILE 文件可读
-w FILE 文件可写
-x FILE 文件可执行

-O FILE 文件owner属于you
-G FILE 文件group属于you
```

字符串操作: (字符串可以使用 `=, !=, >, <, =~` 进行比较. `=~` 是正则匹配)
```
-z STRING 字符串为空
-n STRING 字符串非空
```

数字操作:
```
-eq 等于
-ne 不等于

-gt 大于
-lt 小于
```

- caller

用法: `caller [expr]`

返回当前子协程调用的上下文. 如果未指定 expr, 则返回 "$line $filename". 指定 expr 返回 "$line $subroutine $filename"; 
此额外信息可用于提供堆栈跟踪.

> expr 的值表示在当前调用帧之前要返回多少个调用帧; 顶部帧是第 0 帧.


### 命令行参数解析

- getopts
- shift


### 信号

- kill
- trap


### read 相关

- read

用法: `read [-rs] [-a ARRAY] [-d DELIM] [-n NCHARS] [-p PROMPT] [-t timeout] [-u FD] [NAME ...]`

从标准输入中读取一行并将其拆分为"fields". 

从标准读取单行, 如果提供了 `-u` 选项, 则从文件描述符FD当中读取. 读入的内容使用 `$IFS`(默认是空格) 分割成多个字段, 第一
个单词分配给NAME, 第二个单词分配给第二个NAME ...

如果没有提供 NAME, 则读取的行存储在 REPLY 变量中.

选项:

`-r`, 不允许反斜杠转义任何字符.

`-s`, 不回显来自终端的输入. 默认会回显输入的字符串, 一般用于密码输入.

`-d DELIM`, 直到读取 DELIM(默认是'\n') 的第一个字符才停止读取.

`-p PROMPT`, 在读取之前输出没有换行符的字符串 PROMPT.

`-a ARRAY`, 将读取的 word 插入到数组变量 ARRAY, 从索引0开始. 这时的 NAME 将被忽略.

`-n NCHARS`, 读取 NCHARS 个字符后返回, 而不是等待分隔符. 如果在分隔符之前读取的内容少于 NCHARS 个字符, 则使用分隔符

- readarray

用法: `readarray [-n COUNT] [-O ORIGIN] [-s COUNT] [-t] [-u FD] [-C CALLBACK] [-c quantum] [array]`

将文件中读入的行插入到数组变量. `mapfile` 的同义词.

- mapfile

用法: `mapfile [-d DELIM] [-O ORIGIN] [-s COUNT] [-t] [-u FD] [-C CALLBACK] [-c quantum] [ARRAY]`

将标准输入中的行读入插入到数组变量. 如果提供了 -u 选项, 则从文件描述符 FD 中读入. 默认的数组变量名是 MAPFILE.

选项:

`-t`, 从读取的每一行中删除尾随的DELIM(默认换行符)

`-d DELIM`, 使用 DELIM 分割文本(默认是换行符).

`-O ORIGIN`, 在索引 ORIGIN 处开始分配给 ARRAY. 默认索引为 0.

`-s COUNT`, 丢弃读取的前 COUNT 行.

`-C CALLBACK`, 执行调用回调函数, 参数是数组索引, 行内容.

`-c quantum`, 指定每次执行 CALLBACK 之间读取的行数. 也就是步长, 也就是说每读取 quantum 行后, 执行一次 CALLBACK. 
默认值是5000.

案例:
```bash
cat > file <<-EOF
1d3001df-6589-47d6-a059 05cb46b37c2a
16754ee2-65e6-449e-b6c8 f6cbb7c9fb8e
e844ce36-fa57-4d94-a20e b0582015fff4
614d6ba1-044f-482a-8cca 2eb57cbe729c
EOF

# 使用换行符作为分割符, 并且移除换行符
mapfile -t -C "echo args:" -c 1 arr <file

# 使用空格作为分割符, 并且移除空格
mapfile -t -d ' ' -C "echo args:" -c 1 arr <file

# 数组从索引2开始插入, 最多插入3行
mapfile -O 2 -n 3 arr <file
```

- readonly


### 目录栈

- cd
- pushd
- popd


### 设置

- export
- alias
- unalias
- set
- unset


### 声明与结构体

- declare

用法: `declare [-aAfFgilnrtux] [-p] [name[=value] ...]`

设置变量值和属性. 声明变量并赋予它们属性. 如果没有给出name, 则显示所有变量的属性和值.

选项:

`-f`, 将操作或显示限制为函数名称和定义.

`-F`, 只显示函数名(调试时加上行号和源文件).

`-g`, 在 shell 函数中使用时创建全局变量; 否则忽略.

属性:

`-r`, 只读变量

`-a`, 索引数组(array)

`-A`, 关联数组(map)

`-i`, 整数变量

`-l`, 在赋值时将变量的值转换为小写

`-u`, 在赋值时将变量的值转换为大写

`-x`, 可导出变量

- typeset

与 declare 用法相同.

- let
- local



### 工作进程

- jobs
- bg
- fg
- wait
- suspend
- ulimit


### 其他

- exit
- help
- source

