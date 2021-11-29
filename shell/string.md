## shell 字符串

使用字符串的过程中, 既可以使用双引号, 也可以使用单引号, 也可以什么也不用.

- 单引号

单引号内容是原样输出, **不能包含变量(若包含, 则依旧原样输出)**, 且不能出现单独单引号.

例如:

```bash
a='hello'
echo ${a} # 输出是 hello

b='$a world'
echo ${b} # 输出是 $a world
```


- 双引号

可以出现转义字符(如果使用 `echo` 需要使用 `-e` 参数, 进行转义输出.). 可以包含变量(变量会被转换为其值)

例子:

```bash
a="hello"
echo ${a} # 输出是 hello

b="$a world"
echo ${b} # 输出是 hello world

c="'$a' world"
echo ${c} # 输出是 'hello' world
```

### 长文本字符串的使用

- 使用 `cat` 直接输出到文件

```bash
var=100
cat > /path/to/file <<- 'EOF'
hello world, ${var}
EOF


cat > /path/to/file <<- EOF
hello world, ${var}
EOF
```

> cat 的方式可以将一个长文本字符串直接重定向到文件当中. 使用 `'EOF'`, 是原样输出. 而使用 `EOF` 会将文本当中的变量进行
转义, 然后重定向到文件. 这个很类似于单引号和双引号的区别. 


- 使用 `read` 定义一个文本字符串

```bash
var=100
read -r -d '' var <<- 'EOF'
hello world, ${var}
EOF


read -r -d '' var <<- EOF
hello world, ${var}
EOF
```

> read 可以读取一个长文本字符串到某个变量当中. 后续可以使用该变量进行一系列的操作. `EOF` 和 `'EOF'` 的区别和上面的 
`cat` 当中的类似.
> 这种方式最常见的场景是定义一个模板, 然后使用字符串匹配替换的方式替换一些其中的变量, 最后再将这个文本内容重定向到某个文件.


### 判断读取字符串值

|  表达式            | 含义                                          |
| ----------------- | ---------------------------------------------|
| `${var}`          | 变量var的值, 与`$var`相同 |
| `${var-DEFAULT}`  | 如果var没有被声明, 使用`$DEFAULT`作为其值 |
| `${var:-DEFAULT}` | 如果var没有被声明或者值为空, 使用`$DEFAULT`作为其值 |
| `${var=DEFAULT}`  | 如果var没有被声明, 使用`$DEFAULT`作为其值 |
| `${var:=DEFAULT}` | 如果var没有被声明或者值为空, 使用`$DEFAULT`作为其值 |
|                   |                                    |
| `${var+OTHER}`    | 如果var声明了,那么其值就是`$OTHER`, 否则就是空字符串 |
| `${var:+OTHER}`   | 如果var声明了,那么其值就是`$OTHER`, 否则就是空字符串 |
|                   |                                 |
| `${var?ERR_MSG}`  | 如果var没有被声明, 那么打印`$ERR_MSG` |
| `${var:?ERR_MSG}` | 如果var没有被声明, 那么打印`$ERR_MSG` |
|                   |                                 |
| `${!prefix*}`     | 匹配之前`所有以prefix开头`的为变量名称的变量 |
| `${!prefix@}`     | 匹配之前`所有以prefix开头`的为变量名称的变量 |


> 详细案例:

```bash
echo "声明:"
var=100
echo "声明性替换: ${var:+www.google.com}"
echo "未声明性替换: ${uvar:='www.unwar.com'}"

echo "========================================="
echo "变量错误消息"
echo "未声明错误消息: ${var:?'hello,world'}"

echo "========================================="
echo "变量匹配"
w="wq"
wq="wq"
echo "存在的变量1: ${!w*}"
echo "存在的变量2: ${!w@}"
```


### 字符串操作(长度, 读取, 替换)

| 表达式                 | 含义            |
| --------------------- | -------------- |
| `${#string}`           | `$string`的长度 |
|                       |                                                             |
| `${string:pos}`       | 在`$string`中,从`$pos`开始提取子串 |
| `${string:pos:len}`   | 在`$string`中,从`$pos`开始提取长度为`$len`的子串 |
|                       |                                                             |
| `${var#*string}`      | 从左到右截取 `第一个string后的字符串`, `*`代表任意多个字符串 |
| `${var##*string}`     | 从左到右截取 `最后一个string后的字符串`, `*`代表任意多个字符串 |
| `${var%string}`       | 从右到左截取 `第一个string后的字符串`, `*`代表任意多个字符串 |
| `${var%%string}`      | 从右到左截取 `最后一个string后的字符串`, `*`代表任意多个字符串 |
|                       |                                                             |
| `${string/sub/repl}`  | 使用`$repl`来替换第一个匹配`$sub`的子串(非正则) |
| `${string//sub/repl}` | 使用`$repl`来替换所有匹配`$sub`的子串(非正则) |
| `${string/#sub/repl}` | 如果`$string`的前缀匹配`$sub`,那么使用`$repl`替换匹配`$sub`的子串(1个) |
| `${string/%sub/repl}` | 如果`$string`的后缀匹配`$sub`,那么使用`$repl`替换匹配`$sub`的子串(1个) |


> 详细案例:

```bash
echo "================ 长度 ================"
len="0123456789"
echo "原始字符串: $len"
echo "字符串长度: ${#len}"

echo "================ 截取 ================"
red="0123456789"
echo "原始字符串: $len"
echo "字符串截取1: ${len:3}"
echo "字符串截取2: ${len:3:4}"

echo "================ 删除 ================"
del="/a/b/c/d.java"
echo "原始字符串: $del"
echo "前缀最短删除 #: ${del#*/}"
echo "前缀最长删除 ##: ${del##*/}"
echo "后缀最短删除 %: ${del%/*}"
echo "后缀最长删除 %%: ${del%%/*}"

echo "================ 替换 ================"
repl="www.qq.www.vv.www"
echo "原始字符串: ${repl}"
echo "替换: ${repl/www/rst}"
echo "全部替换 /: ${repl//www/rst}"
echo "条件前缀替换 #: ${repl/#www/xyz}"
echo "条件后缀替换 %: ${repl/%www/xyz}"
```