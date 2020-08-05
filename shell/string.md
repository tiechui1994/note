## shell 下字符串处理

#### 1.判断读取字符串值

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


> example

```bash
echo "声明:"
var=100
echo "声明性替换: ${var:+www.google.com}"
echo "未声明性替换: ${uvar:='www.unwar.com'}"

echo "======================================================="
echo "变量错误消息"
echo "未声明错误消息: ${var:?'hello,world'}"

echo "======================================================="
echo "变量匹配"
w="wq"
wq="wq"
echo "存在的变量1: ${!w*}"
echo "存在的变量2: ${!w@}"
```

---

#### 2. 字符串操作(长度, 读取, 替换)

| 表达式                 | 含义                                                         |
| --------------------- | ----------------------------------------------------------- |
| `${string}`           | `$string`的长度 |
|                       |                                                             |
| `${string:pos}`       | 在`$string`中,从`$pos`开始提取子串 |
| `${string:pos:len}`   | 在`$string`中,从`$pos`开始提取长度为`$len`的子串 |
|                       |                                                             |
| `${var#*string}`      | 从左到右截取 `第一个string后的字符串` |
| `${var##*string}`     | 从左到右截取 `最后一个string后的字符串` |
| `${var%string}`       | 从右到左截取 `第一个string后的字符串` |
| `${var%%string}`      | 从右到左截取 `最后一个string后的字符串` |
|                       |                                                             |
| `${string/sub/repl}`  | 使用`$repl`来替换第一个匹配`$sub`的子串(非正则) |
| `${string//sub/repl}` | 使用`$repl`来替换所有匹配`$sub`的子串(非正则) |
| `${string/#sub/repl}` | 如果`$string`的前缀匹配`$sub`,那么使用`$repl`替换匹配`$sub`的子串(1个) |
| `${string/%sub/repl}` | 如果`$string`的后缀匹配`$sub`,那么使用`$repl`替换匹配`$sub`的子串(1个) |

---

> example

```bash
echo "======================================================="
echo "长度"
len="0123456789"
echo "原始字符串: $len"
echo "字符串长度: ${#len}"

echo "======================================================="
echo "截取"
red="0123456789"
echo "原始字符串: $len"
echo "字符串截取1: ${len:3}"
echo "字符串截取2: ${len:3:4}"

echo "======================================================="
echo "删除操作"
del="/a/b/c/d.java"
echo "原始字符串: $del"
echo "前缀最短删除 #: ${del#*/}"
echo "前缀最长删除 ##: ${del##*/}"
echo "后缀最短删除 %: ${del%/*}"
echo "后缀最长删除 %%: ${del%%/*}"

echo "======================================================="
echo "替换操作"
repl="www.qq.www.vv.www"
echo "原始字符串: ${repl}"
echo "替换: ${repl/www/rst}"
echo "全部替换 /: ${repl//www/rst}"
echo "条件前缀替换 #: ${repl/#www/xyz}"
echo "条件后缀替换 %: ${repl/%www/xyz}"
```